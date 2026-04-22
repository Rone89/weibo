import CryptoKit
import Foundation

actor WBISigner {
    static let shared = WBISigner()

    private let mixinKeyEncTab = [
        46, 47, 18, 2, 53, 8, 23, 32,
        15, 50, 10, 31, 58, 3, 45, 35,
        27, 43, 5, 49, 33, 9, 42, 19,
        29, 28, 14, 39, 12, 38, 41, 13
    ]

    private var cachedMixinKey: String?
    private var cachedDayOrdinal: Int?

    func sign(_ parameters: [String: String], session: URLSession) async throws -> [String: String] {
        let mixinKey = try await currentMixinKey(session: session)
        var signedParameters = parameters
        signedParameters["wts"] = String(Int(Date().timeIntervalSince1970))

        let filtered = signedParameters.mapValues {
            $0.replacingOccurrences(of: "[!'()*]", with: "", options: .regularExpression)
        }
        let query = filtered
            .sorted { $0.key < $1.key }
            .map { "\($0.key.percentEncodedForWBI)=\($0.value.percentEncodedForWBI)" }
            .joined(separator: "&")

        let digest = Insecure.MD5.hash(data: Data((query + mixinKey).utf8))
        signedParameters["w_rid"] = digest.map { String(format: "%02x", $0) }.joined()
        return signedParameters
    }

    private func currentMixinKey(session: URLSession) async throws -> String {
        let dayOrdinal = Calendar(identifier: .gregorian)
            .ordinality(of: .day, in: .year, for: Date()) ?? 0

        if let cachedMixinKey, cachedDayOrdinal == dayOrdinal {
            return cachedMixinKey
        }

        guard let navURL = URL(string: BiliBaseURL.api + BiliEndpoint.nav) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: navURL)
        request.setValue(BiliAPIClient.userAgent, forHTTPHeaderField: "User-Agent")

        let (data, _) = try await session.data(for: request)
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataDict = root["data"] as? [String: Any],
              let wbi = dataDict["wbi_img"] as? [String: Any],
              let imageURL = JSONValue.string(wbi["img_url"]),
              let subURL = JSONValue.string(wbi["sub_url"]) else {
            throw APIError.invalidPayload
        }

        let source = fileNameWithoutExtension(imageURL) + fileNameWithoutExtension(subURL)
        let mixinKey = String(
            mixinKeyEncTab.compactMap { offset in
                guard offset < source.count else { return nil }
                return source[offset]
            }
        )

        cachedMixinKey = mixinKey
        cachedDayOrdinal = dayOrdinal
        return mixinKey
    }

    private func fileNameWithoutExtension(_ urlString: String) -> String {
        URL(string: urlString.normalizedBiliURLString)?
            .deletingPathExtension()
            .lastPathComponent ?? ""
    }
}

private extension String {
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }

    var percentEncodedForWBI: String {
        let allowed = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.~".utf8)
        return utf8.map { byte in
            if allowed.contains(byte) {
                return String(UnicodeScalar(byte))
            }
            return String(format: "%%%02X", byte)
        }.joined()
    }
}
