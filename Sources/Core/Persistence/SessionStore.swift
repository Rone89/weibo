import Foundation

@MainActor
final class SessionStore: ObservableObject {
    private enum Keys {
        static let rawCookie = "session.rawCookie"
    }

    @Published private(set) var rawCookie: String
    @Published private(set) var hasCookie: Bool

    init() {
        let storedCookie = UserDefaults.standard.string(forKey: Keys.rawCookie) ?? ""
        self.rawCookie = storedCookie
        self.hasCookie = !storedCookie.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if hasCookie {
            BiliCookieParser.primeSharedStorage(with: storedCookie)
        }
    }

    var csrfToken: String? {
        cookieValue(for: "bili_jct")
    }

    var dedeUserID: String? {
        cookieValue(for: "DedeUserID")
    }

    func updateCookie(_ newValue: String) {
        let sanitized = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        rawCookie = sanitized
        hasCookie = !sanitized.isEmpty
        UserDefaults.standard.set(sanitized, forKey: Keys.rawCookie)
        BiliCookieParser.apply(sanitized)
    }

    func refreshFromStorage() {
        let exported = BiliCookieParser.exportCookieHeader()
        rawCookie = exported
        hasCookie = !exported.isEmpty
        UserDefaults.standard.set(exported, forKey: Keys.rawCookie)
    }

    func mergeCookieStateFromStores() async {
        let webKitCookie = await BiliCookieParser.exportCookieHeaderFromWebKit()
        let httpCookie = BiliCookieParser.exportCookieHeader()
        let merged = mergeCookieHeaders(webKitCookie, httpCookie)

        rawCookie = merged
        hasCookie = !merged.isEmpty
        UserDefaults.standard.set(merged, forKey: Keys.rawCookie)

        if !merged.isEmpty {
            BiliCookieParser.apply(merged)
        }
    }

    func restorePersistedCookieIfNeeded() {
        guard hasCookie else { return }
        BiliCookieParser.apply(rawCookie)
    }

    func clearSession() {
        rawCookie = ""
        hasCookie = false
        UserDefaults.standard.removeObject(forKey: Keys.rawCookie)
        BiliCookieParser.clearBilibiliCookies()
    }

    private func cookieValue(for name: String) -> String? {
        rawCookie
            .split(separator: ";")
            .compactMap { fragment -> (String, String)? in
                let pair = fragment.split(separator: "=", maxSplits: 1)
                guard pair.count == 2 else { return nil }
                return (
                    String(pair[0]).trimmingCharacters(in: .whitespacesAndNewlines),
                    String(pair[1]).trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            .first(where: { $0.0 == name })?
            .1
    }

    private func mergeCookieHeaders(_ primary: String, _ secondary: String) -> String {
        let merged = parse(primary).reduce(into: parse(secondary)) { partialResult, pair in
            partialResult[pair.key] = pair.value
        }

        return merged
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "; ")
    }

    private func parse(_ header: String) -> [String: String] {
        header
            .split(separator: ";")
            .reduce(into: [String: String]()) { partialResult, fragment in
                let pair = fragment.split(separator: "=", maxSplits: 1)
                guard pair.count == 2 else { return }
                let key = String(pair[0]).trimmingCharacters(in: .whitespacesAndNewlines)
                let value = String(pair[1]).trimmingCharacters(in: .whitespacesAndNewlines)
                guard !key.isEmpty, !value.isEmpty else { return }
                partialResult[key] = value
            }
    }
}
