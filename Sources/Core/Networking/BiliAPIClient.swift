import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidPayload
    case missingCSRF
    case server(String)
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return L10n.errorInvalidURL
        case .invalidResponse:
            return L10n.errorInvalidResponse
        case .invalidPayload:
            return L10n.errorInvalidPayload
        case .missingCSRF:
            return L10n.errorMissingCSRF
        case .server(let message):
            return message
        case .decoding(let message):
            return message
        }
    }
}

final class BiliAPIClient {
    static let userAgent =
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

    let session: URLSession
    let sessionStore: SessionStore
    let preferencesStore: AppPreferencesStore

    init(sessionStore: SessionStore, preferencesStore: AppPreferencesStore) {
        self.sessionStore = sessionStore
        self.preferencesStore = preferencesStore

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 30
        configuration.requestCachePolicy = .useProtocolCachePolicy
        configuration.waitsForConnectivity = false
        configuration.httpMaximumConnectionsPerHost = 8
        configuration.httpShouldSetCookies = true
        configuration.httpCookieStorage = HTTPCookieStorage.shared
        configuration.urlCache = URLCache(
            memoryCapacity: 64 * 1024 * 1024,
            diskCapacity: 256 * 1024 * 1024,
            diskPath: "bili-api-cache"
        )
        configuration.httpAdditionalHeaders = [
            "User-Agent": Self.userAgent,
            "Accept-Language": "zh-CN,zh-Hans;q=0.9",
            "Accept": "application/json, text/plain, */*"
        ]

        self.session = URLSession(configuration: configuration)
    }

    func requestJSON(
        baseURL: String = BiliBaseURL.api,
        path: String,
        query: [String: String] = [:],
        headers: [String: String] = [:],
        signedByWBI: Bool = false,
        includeCookies: Bool = true
    ) async throws -> Any {
        try await sendJSONRequest(
            baseURL: baseURL,
            path: path,
            method: "GET",
            query: query,
            headers: headers,
            body: nil,
            signedByWBI: signedByWBI,
            includeCookies: includeCookies
        )
    }

    func postJSON(
        baseURL: String = BiliBaseURL.api,
        path: String,
        form: [String: String] = [:],
        query: [String: String] = [:],
        headers: [String: String] = [:],
        signedByWBI: Bool = false,
        contentType: String = "application/x-www-form-urlencoded; charset=utf-8",
        includeCookies: Bool = true
    ) async throws -> Any {
        let body = formEncodedData(from: form)
        var mergedHeaders = headers
        mergedHeaders["Content-Type"] = contentType
        return try await sendJSONRequest(
            baseURL: baseURL,
            path: path,
            method: "POST",
            query: query,
            headers: mergedHeaders,
            body: body,
            signedByWBI: signedByWBI,
            includeCookies: includeCookies
        )
    }

    func requestEnvelopeValue(
        baseURL: String = BiliBaseURL.api,
        path: String,
        query: [String: String] = [:],
        headers: [String: String] = [:],
        signedByWBI: Bool = false,
        includeCookies: Bool = true
    ) async throws -> Any {
        try extractEnvelopeValue(
            from: await requestJSON(
                baseURL: baseURL,
                path: path,
                query: query,
                headers: headers,
                signedByWBI: signedByWBI,
                includeCookies: includeCookies
            )
        )
    }

    func postEnvelopeValue(
        baseURL: String = BiliBaseURL.api,
        path: String,
        form: [String: String] = [:],
        query: [String: String] = [:],
        headers: [String: String] = [:],
        signedByWBI: Bool = false,
        includeCookies: Bool = true
    ) async throws -> Any {
        try extractEnvelopeValue(
            from: await postJSON(
                baseURL: baseURL,
                path: path,
                form: form,
                query: query,
                headers: headers,
                signedByWBI: signedByWBI,
                includeCookies: includeCookies
            )
        )
    }

    func requestEnvelopeData(
        baseURL: String = BiliBaseURL.api,
        path: String,
        query: [String: String] = [:],
        headers: [String: String] = [:],
        signedByWBI: Bool = false,
        includeCookies: Bool = true
    ) async throws -> [String: Any] {
        guard let data = try await requestEnvelopeValue(
            baseURL: baseURL,
            path: path,
            query: query,
            headers: headers,
            signedByWBI: signedByWBI,
            includeCookies: includeCookies
        ) as? [String: Any] else {
            throw APIError.invalidPayload
        }
        return data
    }

    func postEnvelopeData(
        baseURL: String = BiliBaseURL.api,
        path: String,
        form: [String: String] = [:],
        query: [String: String] = [:],
        headers: [String: String] = [:],
        signedByWBI: Bool = false,
        includeCookies: Bool = true
    ) async throws -> [String: Any] {
        guard let data = try await postEnvelopeValue(
            baseURL: baseURL,
            path: path,
            form: form,
            query: query,
            headers: headers,
            signedByWBI: signedByWBI,
            includeCookies: includeCookies
        ) as? [String: Any] else {
            throw APIError.invalidPayload
        }
        return data
    }

    func requestEnvelopeArray(
        baseURL: String = BiliBaseURL.api,
        path: String,
        query: [String: String] = [:],
        headers: [String: String] = [:],
        signedByWBI: Bool = false,
        includeCookies: Bool = true
    ) async throws -> [[String: Any]] {
        JSONValue.dictionaries(
            try await requestEnvelopeValue(
                baseURL: baseURL,
                path: path,
                query: query,
                headers: headers,
                signedByWBI: signedByWBI,
                includeCookies: includeCookies
            )
        )
    }

    func requireCSRFToken() async throws -> String {
        let token = await sessionStore.csrfToken
        guard let token, !token.isEmpty else {
            throw APIError.missingCSRF
        }
        return token
    }

    private func sendJSONRequest(
        baseURL: String,
        path: String,
        method: String,
        query: [String: String],
        headers: [String: String],
        body: Data?,
        signedByWBI: Bool,
        includeCookies: Bool
    ) async throws -> Any {
        var finalQuery = query
        if signedByWBI {
            finalQuery = try await WBISigner.shared.sign(finalQuery, session: session)
        }

        guard var components = URLComponents(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        if !finalQuery.isEmpty {
            components.queryItems = finalQuery
                .sorted { $0.key < $1.key }
                .map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.httpShouldHandleCookies = includeCookies
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw APIError.invalidResponse
        }

        do {
            return try await Task.detached(priority: .utility) {
                try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            }.value
        } catch {
            throw APIError.decoding(L10n.invalidJSON(error.localizedDescription))
        }
    }

    private func extractEnvelopeValue(from object: Any) throws -> Any {
        guard let root = object as? [String: Any] else {
            throw APIError.invalidPayload
        }

        let code = JSONValue.int(root["code"]) ?? -1
        if code != 0 {
            let message = JSONValue.string(root["message"]) ?? L10n.requestFailed(code: code)
            throw APIError.server(message)
        }

        if let data = root["data"] {
            return data
        }
        if let result = root["result"] {
            return result
        }
        return [:]
    }

    private func formEncodedData(from form: [String: String]) -> Data? {
        let body = form
            .sorted { $0.key < $1.key }
            .map { "\($0.key.percentEncodedForForm)=\($0.value.percentEncodedForForm)" }
            .joined(separator: "&")
        return body.data(using: .utf8)
    }
}

private extension String {
    var percentEncodedForForm: String {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.~")
        return addingPercentEncoding(withAllowedCharacters: allowed) ?? self
    }
}
