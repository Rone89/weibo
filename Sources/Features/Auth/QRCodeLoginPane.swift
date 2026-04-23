import CoreImage
import CoreImage.CIFilterBuiltins
import CryptoKit
import SwiftUI
import UIKit

struct QRCodeLoginPane: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: QRCodeLoginViewModel

    init(apiClient: BiliAPIClient, onImportCookie: @escaping (String) -> Void) {
        _viewModel = StateObject(
            wrappedValue: QRCodeLoginViewModel(apiClient: apiClient, onImportCookie: onImportCookie)
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                qrCard

                if let errorMessage = viewModel.errorMessage {
                    messageCard(text: errorMessage, tint: .red)
                }

                if let backgroundMessage = viewModel.backgroundMessage {
                    messageCard(text: backgroundMessage, tint: Color("AccentColor"))
                }

                instructionsCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .task {
            await viewModel.loadIfNeeded()
        }
        .onDisappear {
            viewModel.stopPolling()
        }
        .onChange(of: scenePhase) { newValue in
            viewModel.handleScenePhaseChange(newValue)
        }
    }

    private var qrCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.qrLoginTabTitle)
                        .font(.title3.weight(.bold))
                    Text(viewModel.statusText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(L10n.qrLoginRefresh) {
                    Task { await viewModel.refreshQRCode() }
                }
                .buttonStyle(.plain)
                .biliPrimaryActionButton(fillWidth: false)
                .disabled(viewModel.isLoading)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 260, height: 260)
                    .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 10)

                if viewModel.isLoading && viewModel.qrCodeURL == nil {
                    ProgressView(L10n.qrLoginGenerating)
                } else if let qrCodeURL = viewModel.qrCodeURL {
                    QRCodeImageView(text: qrCodeURL)
                        .frame(width: 220, height: 220)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 44, weight: .regular))
                            .foregroundStyle(Color("AccentColor"))
                        Text(L10n.qrLoginHint)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                }
            }

            HStack(spacing: 10) {
                BiliMetricPill(
                    text: L10n.qrLoginCountdown(viewModel.remainingSeconds),
                    systemImage: "timer"
                )
                if viewModel.isPolling {
                    BiliMetricPill(text: L10n.qrLoginStatusWaiting, systemImage: "dot.radiowaves.left.and.right")
                }
            }
        }
        .padding(20)
        .biliCardStyle()
    }

    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            BiliSectionHeader(title: L10n.qrLoginHint, subtitle: L10n.qrLoginOpenInAppHint)

            Text(L10n.qrLoginBackgroundCapability)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .biliCardStyle()
    }

    private func messageCard(text: String, tint: Color) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(tint)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(tint.opacity(0.08))
            )
    }
}

@MainActor
final class QRCodeLoginViewModel: ObservableObject {
    @Published private(set) var qrCodeURL: String?
    @Published private(set) var statusText = L10n.qrLoginHint
    @Published private(set) var remainingSeconds = 180
    @Published private(set) var isLoading = false
    @Published private(set) var isPolling = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var backgroundMessage: String?

    private let apiClient: BiliAPIClient
    private let onImportCookie: (String) -> Void
    private var hasLoaded = false
    private var authCode: String?
    private var expiresAt: Date?
    private var pollTask: Task<Void, Never>?
    private var countdownTask: Task<Void, Never>?
    private let backgroundLease = BackgroundPollingLease()

    init(apiClient: BiliAPIClient, onImportCookie: @escaping (String) -> Void) {
        self.apiClient = apiClient
        self.onImportCookie = onImportCookie
        backgroundLease.onExpiration = { [weak self] in
            Task { [weak self] in
                await MainActor.run {
                    guard let self else { return }
                    self.backgroundMessage = L10n.qrLoginBackgroundExpired
                    self.pollTask?.cancel()
                    self.pollTask = nil
                    self.isPolling = false
                }
            }
        }
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await refreshQRCode()
    }

    func refreshQRCode() async {
        stopPolling()
        isLoading = true
        errorMessage = nil
        backgroundMessage = nil
        qrCodeURL = nil
        authCode = nil
        expiresAt = nil
        remainingSeconds = 180
        statusText = L10n.qrLoginGenerating

        do {
            let session = try await requestQRCodeSession()
            authCode = session.authCode
            qrCodeURL = session.url
            expiresAt = session.expiresAt
            remainingSeconds = max(0, Int(session.expiresAt.timeIntervalSinceNow.rounded(.down)))
            statusText = L10n.qrLoginStatusWaiting
            startCountdown()
            startPolling()
        } catch {
            errorMessage = error.localizedDescription
            statusText = L10n.qrLoginHint
        }

        isLoading = false
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
        countdownTask?.cancel()
        countdownTask = nil
        isPolling = false
        backgroundLease.end()
    }

    func handleScenePhaseChange(_ scenePhase: ScenePhase) {
        switch scenePhase {
        case .background:
            guard isPolling else { return }
            backgroundLease.begin(name: "QRCodeLoginPolling")
            backgroundMessage = L10n.qrLoginBackgroundActive
        case .active:
            backgroundLease.end()
            backgroundMessage = nil
            resumePollingIfPossible()
        default:
            break
        }
    }

    private func resumePollingIfPossible() {
        guard pollTask == nil else { return }
        guard let expiresAt, expiresAt > Date() else { return }
        guard authCode != nil else { return }
        startPolling()
    }

    private func startCountdown() {
        countdownTask?.cancel()
        countdownTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                guard let expiresAt = self.expiresAt else { return }
                let seconds = max(0, Int(expiresAt.timeIntervalSinceNow.rounded(.down)))
                self.remainingSeconds = seconds

                if seconds == 0 {
                    self.statusText = L10n.qrLoginExpired
                    self.pollTask?.cancel()
                    self.pollTask = nil
                    self.isPolling = false
                    return
                }

                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func startPolling() {
        guard pollTask == nil else { return }
        guard let authCode else { return }

        isPolling = true
        pollTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                guard let expiresAt = self.expiresAt, expiresAt > Date() else {
                    self.statusText = L10n.qrLoginExpired
                    self.isPolling = false
                    self.pollTask = nil
                    return
                }

                do {
                    let result = try await self.pollQRCodeStatus(authCode: authCode)
                    switch result {
                    case .pending(let message):
                        self.statusText = message
                    case .expired(let message):
                        self.statusText = message
                        self.isPolling = false
                        self.pollTask = nil
                        return
                    case .success(let cookieHeader):
                        self.statusText = L10n.qrLoginStatusSuccess
                        self.isPolling = false
                        self.pollTask = nil
                        self.backgroundLease.end()
                        self.onImportCookie(cookieHeader)
                        return
                    }
                } catch {
                    self.errorMessage = error.localizedDescription
                    self.isPolling = false
                    self.pollTask = nil
                    return
                }

                try? await Task.sleep(for: .seconds(1))
            }

            self.isPolling = false
            self.pollTask = nil
        }
    }

    private func requestQRCodeSession() async throws -> QRCodeLoginSession {
        let params = BiliAppSigner.sign([
            "local_id": "0",
            "mobi_app": "android_hd",
            "platform": "android"
        ])

        let object = try await apiClient.postJSON(
            baseURL: BiliBaseURL.passport,
            path: BiliEndpoint.qrCodeAuthCode,
            query: params,
            headers: BiliAppSigner.headers
        )

        guard let root = object as? [String: Any] else {
            throw APIError.invalidPayload
        }

        let code = JSONValue.int(root["code"]) ?? -1
        guard code == 0 else {
            throw APIError.server(JSONValue.string(root["message"]) ?? L10n.requestFailed(code: code))
        }

        guard let data = JSONValue.dictionary(root["data"]),
              let authCode = JSONValue.string(data["auth_code"]),
              let url = JSONValue.string(data["url"]) else {
            throw APIError.invalidPayload
        }

        return QRCodeLoginSession(
            authCode: authCode,
            url: url,
            expiresAt: Date().addingTimeInterval(180)
        )
    }

    private func pollQRCodeStatus(authCode: String) async throws -> QRCodePollResult {
        let params = BiliAppSigner.sign([
            "auth_code": authCode,
            "local_id": "0"
        ])

        let object = try await apiClient.postJSON(
            baseURL: BiliBaseURL.passport,
            path: BiliEndpoint.qrCodePoll,
            query: params,
            headers: BiliAppSigner.headers
        )

        guard let root = object as? [String: Any] else {
            throw APIError.invalidPayload
        }

        let code = JSONValue.int(root["code"]) ?? -1
        let message = JSONValue.string(root["message"]) ?? L10n.requestFailed(code: code)

        switch code {
        case 0:
            guard let data = JSONValue.dictionary(root["data"]),
                  let cookieInfo = JSONValue.dictionary(data["cookie_info"]) else {
                throw APIError.server(L10n.qrLoginCookieMissing)
            }
            let cookieHeader = makeCookieHeader(from: JSONValue.dictionaries(cookieInfo["cookies"]))
            guard !cookieHeader.isEmpty else {
                throw APIError.server(L10n.qrLoginCookieMissing)
            }
            return .success(cookieHeader)
        case 86038:
            return .expired(L10n.qrLoginExpired)
        case 86090:
            return .pending(L10n.qrLoginStatusWaiting)
        case 86101:
            return .pending(L10n.qrLoginStatusScanned)
        default:
            return .pending(message)
        }
    }

    private func makeCookieHeader(from cookies: [[String: Any]]) -> String {
        cookies
            .compactMap { item -> (String, String)? in
                guard let name = JSONValue.string(item["name"]),
                      let value = JSONValue.string(item["value"]),
                      !name.isEmpty,
                      !value.isEmpty else {
                    return nil
                }
                return (name, value)
            }
            .sorted { $0.0 < $1.0 }
            .map { "\($0.0)=\($0.1)" }
            .joined(separator: "; ")
    }
}

private struct QRCodeLoginSession {
    let authCode: String
    let url: String
    let expiresAt: Date
}

private enum QRCodePollResult {
    case pending(String)
    case expired(String)
    case success(String)
}

private enum BiliAppSigner {
    static let appKey = "dfca71928277209b"
    static let appSecret = "b5475a8825547a4fc26c7d518eaaa02e"

    static let headers = [
        "User-Agent": "Mozilla/5.0 BiliDroid/2.0.1 (bbcallen@gmail.com) os/android model/android_hd mobi_app/android_hd build/2001100 channel/master innerVer/2001100 osVer/15 network/2",
        "app-key": "android_hd",
        "env": "prod",
        "Content-Type": "application/x-www-form-urlencoded; charset=utf-8"
    ]

    static func sign(_ parameters: [String: String]) -> [String: String] {
        var signed = parameters
        signed["appkey"] = appKey
        signed["ts"] = "\(Int(Date().timeIntervalSince1970))"

        let canonical = signed
            .sorted { $0.key < $1.key }
            .map { "\(percentEncode($0.key))=\(percentEncode($0.value))" }
            .joined(separator: "&")

        let digest = Insecure.MD5.hash(data: Data((canonical + appSecret).utf8))
        let signature = digest.map { String(format: "%02x", $0) }.joined()
        signed["sign"] = signature
        return signed
    }

    private static func percentEncode(_ value: String) -> String {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.~")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }
}

private final class BackgroundPollingLease {
    var onExpiration: (() -> Void)?
    private var taskIdentifier: UIBackgroundTaskIdentifier = .invalid

    func begin(name: String) {
        guard taskIdentifier == .invalid else { return }
        taskIdentifier = UIApplication.shared.beginBackgroundTask(withName: name) { [weak self] in
            self?.onExpiration?()
            self?.end()
        }
    }

    func end() {
        guard taskIdentifier != .invalid else { return }
        UIApplication.shared.endBackgroundTask(taskIdentifier)
        taskIdentifier = .invalid
    }

    deinit {
        end()
    }
}

private struct QRCodeImageView: View {
    let text: String
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        if let image = makeImage() {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        }
    }

    private func makeImage() -> UIImage? {
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else {
            return nil
        }

        let transform = CGAffineTransform(scaleX: 12, y: 12)
        let scaledImage = outputImage.transformed(by: transform)
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
