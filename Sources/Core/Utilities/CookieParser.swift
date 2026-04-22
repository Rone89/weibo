import Foundation
import WebKit

enum BiliCookieParser {
    private static let supportedDomains = [
        ".bilibili.com",
        "api.bilibili.com",
        "www.bilibili.com",
        "passport.bilibili.com",
        "app.bilibili.com",
        "search.bilibili.com",
        "s.search.bilibili.com"
    ]

    static func apply(_ rawCookie: String) {
        let cookies = makeCookies(from: rawCookie)
        replaceHTTPCookies(with: cookies)

        Task { @MainActor in
            replaceWebKitCookies(with: cookies)
        }
    }

    static func primeSharedStorage(with rawCookie: String) {
        replaceHTTPCookies(with: makeCookies(from: rawCookie))
    }

    static func clearBilibiliCookies() {
        clearBilibiliHTTPCookies()

        Task { @MainActor in
            clearBilibiliWebKitCookies()
        }
    }

    static func exportCookieHeader() -> String {
        let cookies = (HTTPCookieStorage.shared.cookies ?? [])
            .filter { isBilibiliDomain($0.domain) }

        let latestByName = Dictionary(grouping: cookies, by: \.name)
            .compactMapValues { $0.last }

        return latestByName
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value.value)" }
            .joined(separator: "; ")
    }

    static func exportCookieHeaderFromWebKit() async -> String {
        await withCheckedContinuation { continuation in
            WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
                let latestByName = Dictionary(grouping: cookies.filter { isBilibiliDomain($0.domain) }, by: \.name)
                    .compactMapValues { $0.last }

                let value = latestByName
                    .sorted { $0.key < $1.key }
                    .map { "\($0.key)=\($0.value.value)" }
                    .joined(separator: "; ")
                continuation.resume(returning: value)
            }
        }
    }

    private static func makeCookies(from rawCookie: String) -> [HTTPCookie] {
        let cookiePairs = parse(rawCookie)
        guard !cookiePairs.isEmpty else {
            return []
        }

        return supportedDomains.flatMap { domain in
            cookiePairs.compactMap { key, value in
                makeCookie(name: key, value: value, domain: domain)
            }
        }
    }

    private static func replaceHTTPCookies(with cookies: [HTTPCookie]) {
        clearBilibiliHTTPCookies()

        let storage = HTTPCookieStorage.shared
        cookies.forEach { storage.setCookie($0) }
    }

    private static func parse(_ rawCookie: String) -> [(String, String)] {
        rawCookie
            .split(separator: ";")
            .compactMap { fragment in
                let pair = fragment.split(separator: "=", maxSplits: 1)
                guard pair.count == 2 else {
                    return nil
                }
                let key = String(pair[0]).trimmingCharacters(in: .whitespacesAndNewlines)
                let value = String(pair[1]).trimmingCharacters(in: .whitespacesAndNewlines)
                guard !key.isEmpty, !value.isEmpty else {
                    return nil
                }
                return (key, value)
            }
    }

    private static func makeCookie(name: String, value: String, domain: String) -> HTTPCookie? {
        HTTPCookie(properties: [
            .domain: domain,
            .path: "/",
            .name: name,
            .value: value,
            .secure: true,
            .expires: Date().addingTimeInterval(60 * 60 * 24 * 365),
            .version: 0
        ])
    }

    private static func clearBilibiliHTTPCookies() {
        let storage = HTTPCookieStorage.shared
        let cookies = storage.cookies?.filter { isBilibiliDomain($0.domain) } ?? []
        for cookie in cookies {
            storage.deleteCookie(cookie)
        }
    }

    @MainActor
    private static func clearBilibiliWebKitCookies() {
        let webStore = WKWebsiteDataStore.default().httpCookieStore
        webStore.getAllCookies { cookies in
            cookies
                .filter { isBilibiliDomain($0.domain) }
                .forEach { webStore.delete($0) }
        }
    }

    @MainActor
    private static func replaceWebKitCookies(with cookies: [HTTPCookie]) {
        let webStore = WKWebsiteDataStore.default().httpCookieStore
        webStore.getAllCookies { existingCookies in
            existingCookies
                .filter { isBilibiliDomain($0.domain) }
                .forEach { webStore.delete($0) }

            cookies.forEach { webStore.setCookie($0) }
        }
    }

    private static func isBilibiliDomain(_ domain: String) -> Bool {
        domain.contains("bilibili.com")
    }
}
