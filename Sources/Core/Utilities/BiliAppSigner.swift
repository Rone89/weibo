import CryptoKit
import Foundation

enum BiliAppSigner {
    private static let appKey = "dfca71928277209b"
    private static let appSecret = "b5475a8825547a4fc26c7d518eaaa02e"

    static func sign(_ parameters: [String: String]) -> [String: String] {
        var params = parameters
        params["appkey"] = appKey
        params["ts"] = "\(Int(Date().timeIntervalSince1970))"

        let sortedPairs = params
            .filter { !$0.value.isEmpty }
            .sorted { $0.key < $1.key }
            .map { "\($0.key.percentEncodedForAppSign)=\($0.value.percentEncodedForAppSign)" }
            .joined(separator: "&")

        let digest = Insecure.MD5.hash(data: Data((sortedPairs + appSecret).utf8))
        let sign = digest.map { String(format: "%02hhx", $0) }.joined()
        params["sign"] = sign
        return params
    }
}

private extension String {
    var percentEncodedForAppSign: String {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.~")
        return addingPercentEncoding(withAllowedCharacters: allowed) ?? self
    }
}
