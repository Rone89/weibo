import SwiftUI
import WebKit

struct WebLoginView: View {
    @Environment(\.dismiss) private var dismiss
    private enum LoginMode: String, CaseIterable, Identifiable {
        case qr
        case browser

        var id: String { rawValue }
    }

    let apiClient: BiliAPIClient
    let onImportCookie: (String) -> Void

    @State private var mode: LoginMode = .qr
    @State private var isImporting = false
    @State private var statusText = L10n.webLoginHint

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Login Mode", selection: $mode) {
                    Text(L10n.qrLoginTabTitle).tag(LoginMode.qr)
                    Text(L10n.browserLoginTabTitle).tag(LoginMode.browser)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 12)

                if mode == .qr {
                    QRCodeLoginPane(apiClient: apiClient) { rawCookie in
                        onImportCookie(rawCookie)
                        dismiss()
                    }
                } else {
                    VStack(spacing: 0) {
                        WebLoginBrowser()
                        Text(statusText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                    }
                }
            }
            .navigationTitle(L10n.webLoginTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.close) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if mode == .browser {
                        if isImporting {
                            ProgressView()
                        } else {
                            Button(L10n.import) {
                                Task {
                                    await importCookie()
                                }
                            }
                            .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
    }

    private func importCookie() async {
        isImporting = true
        let cookieHeader = await BiliCookieParser.exportCookieHeaderFromWebKit()
        isImporting = false

        if cookieHeader.isEmpty {
            statusText = L10n.webLoginMissingCookie
            return
        }

        onImportCookie(cookieHeader)
        dismiss()
    }
}

private struct WebLoginBrowser: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.customUserAgent = BiliAPIClient.userAgent
        webView.navigationDelegate = context.coordinator

        if let url = URL(string: "https://passport.bilibili.com/login") {
            var request = URLRequest(url: url)
            request.setValue(BiliAPIClient.userAgent, forHTTPHeaderField: "User-Agent")
            webView.load(request)
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, WKNavigationDelegate {}
}
