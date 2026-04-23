import Foundation

enum JSONValue {
    static func string(_ value: Any?) -> String? {
        switch value {
        case let value as String:
            return value
        case let value as NSNumber:
            return value.stringValue
        default:
            return nil
        }
    }

    static func int(_ value: Any?) -> Int? {
        switch value {
        case let value as Int:
            return value
        case let value as NSNumber:
            return value.intValue
        case let value as String:
            return Int(value)
        default:
            return nil
        }
    }

    static func double(_ value: Any?) -> Double? {
        switch value {
        case let value as Double:
            return value
        case let value as NSNumber:
            return value.doubleValue
        case let value as String:
            return Double(value)
        default:
            return nil
        }
    }

    static func bool(_ value: Any?) -> Bool? {
        switch value {
        case let value as Bool:
            return value
        case let value as NSNumber:
            return value.boolValue
        case let value as String:
            return ["1", "true", "yes"].contains(value.lowercased())
        default:
            return nil
        }
    }

    static func dictionary(_ value: Any?) -> [String: Any]? {
        value as? [String: Any]
    }

    static func dictionaries(_ value: Any?) -> [[String: Any]] {
        if let dictionaries = value as? [[String: Any]] {
            return dictionaries
        }
        if let array = value as? [Any] {
            return array.compactMap { $0 as? [String: Any] }
        }
        return []
    }

    static func stringArray(_ value: Any?) -> [String] {
        if let strings = value as? [String] {
            return strings
        }
        if let values = value as? [Any] {
            return values.compactMap(string)
        }
        return []
    }
}

struct VideoSummary: Identifiable, Hashable {
    let aid: Int?
    let bvid: String
    let cid: Int?
    let title: String
    let subtitle: String?
    let coverURL: String?
    let duration: Int?
    let publishDate: Date?
    let authorName: String
    let authorID: Int?
    let authorAvatarURL: String?
    let viewCount: Int?
    let likeCount: Int?
    let danmakuCount: Int?
    let reason: String?

    var id: String {
        if !bvid.isEmpty { return bvid }
        if let aid { return "av\(aid)" }
        if let cid { return "cid\(cid)" }
        return title
    }

    init(
        aid: Int?,
        bvid: String,
        cid: Int?,
        title: String,
        subtitle: String?,
        coverURL: String?,
        duration: Int?,
        publishDate: Date?,
        authorName: String,
        authorID: Int?,
        authorAvatarURL: String?,
        viewCount: Int?,
        likeCount: Int?,
        danmakuCount: Int?,
        reason: String?
    ) {
        self.aid = aid
        self.bvid = bvid
        self.cid = cid
        self.title = title
        self.subtitle = subtitle
        self.coverURL = coverURL
        self.duration = duration
        self.publishDate = publishDate
        self.authorName = authorName
        self.authorID = authorID
        self.authorAvatarURL = authorAvatarURL
        self.viewCount = viewCount
        self.likeCount = likeCount
        self.danmakuCount = danmakuCount
        self.reason = reason
    }

    init(json: [String: Any]) {
        let owner = JSONValue.dictionary(json["owner"])
        let stat = JSONValue.dictionary(json["stat"])
        let args = JSONValue.dictionary(json["args"])
        let reasonPayload = JSONValue.dictionary(json["rcmd_reason"])

        self.aid = JSONValue.int(json["aid"]) ?? JSONValue.int(json["id"]) ?? JSONValue.int(args?["aid"])
        self.bvid = JSONValue.string(json["bvid"]) ?? JSONValue.string(args?["bvid"]) ?? ""
        self.cid = JSONValue.int(json["cid"])
        self.title = HTMLSanitizer.plainText(JSONValue.string(json["title"]) ?? JSONValue.string(json["name"]))
        self.subtitle = HTMLSanitizer.plainText(JSONValue.string(json["desc"]) ?? JSONValue.string(json["description"]))
        self.coverURL = JSONValue.string(json["pic"])?.normalizedBiliURLString ??
            JSONValue.string(json["cover"])?.normalizedBiliURLString
        self.duration = BiliFormatting.parseDuration(json["duration"])
        if let timestamp = JSONValue.double(json["pubdate"]) ?? JSONValue.double(json["senddate"]) {
            self.publishDate = Date(timeIntervalSince1970: timestamp)
        } else {
            self.publishDate = nil
        }
        self.authorName = JSONValue.string(owner?["name"]) ??
            JSONValue.string(json["author"]) ??
            JSONValue.string(json["uname"]) ??
            L10n.unknownUP
        self.authorID = JSONValue.int(owner?["mid"]) ?? JSONValue.int(json["mid"]) ?? JSONValue.int(args?["up_id"])
        self.authorAvatarURL = JSONValue.string(owner?["face"])?.normalizedBiliURLString ??
            JSONValue.string(json["upic"])?.normalizedBiliURLString
        self.viewCount = JSONValue.int(stat?["view"]) ?? JSONValue.int(stat?["play"]) ?? JSONValue.int(json["play"])
        self.likeCount = JSONValue.int(stat?["like"]) ?? JSONValue.int(json["like"])
        self.danmakuCount = JSONValue.int(stat?["danmaku"]) ?? JSONValue.int(json["danmaku"])
        self.reason = HTMLSanitizer.plainText(
            JSONValue.string(reasonPayload?["content"]) ?? JSONValue.string(json["rcmd_reason"])
        )
    }
}

struct SearchSuggestion: Identifiable, Hashable {
    let term: String
    let highlightedText: String

    var id: String { term }

    init(json: [String: Any]) {
        self.term = JSONValue.string(json["term"]) ?? ""
        self.highlightedText = HTMLSanitizer.plainText(JSONValue.string(json["name"]))
    }
}

struct TrendingKeyword: Identifiable, Hashable {
    let keyword: String
    let reason: String?
    let iconURL: String?

    var id: String { keyword }

    init(json: [String: Any]) {
        self.keyword = JSONValue.string(json["keyword"]) ?? ""
        self.reason = JSONValue.string(json["recommend_reason"])
        self.iconURL = JSONValue.string(json["icon"])?.normalizedBiliURLString
    }
}

struct UserProfile: Hashable {
    let isLogin: Bool
    let mid: Int
    let name: String
    let avatarURL: String?
    let level: Int?
    let coinBalance: Double?
    let vipStatus: Int?
    let signature: String?

    init(json: [String: Any]) {
        let levelInfo = JSONValue.dictionary(json["level_info"])
        self.isLogin = JSONValue.bool(json["isLogin"]) ?? false
        self.mid = JSONValue.int(json["mid"]) ?? 0
        self.name = JSONValue.string(json["uname"]) ?? L10n.notLoggedIn
        self.avatarURL = JSONValue.string(json["face"])?.normalizedBiliURLString
        self.level = JSONValue.int(levelInfo?["current_level"])
        self.coinBalance = JSONValue.double(json["money"])
        self.vipStatus = JSONValue.int(json["vipStatus"])
        self.signature = JSONValue.string(json["sign"])
    }
}

struct UserStat: Hashable {
    let followingCount: Int
    let followerCount: Int
    let dynamicCount: Int

    init(json: [String: Any]) {
        self.followingCount = JSONValue.int(json["following"]) ?? 0
        self.followerCount = JSONValue.int(json["follower"]) ?? 0
        self.dynamicCount = JSONValue.int(json["dynamic_count"]) ?? 0
    }
}

struct FavoriteFolder: Identifiable, Hashable {
    let id: Int
    let title: String
    let mediaCount: Int
    let coverURL: String?
    let intro: String?

    init(json: [String: Any]) {
        self.id = JSONValue.int(json["id"]) ?? 0
        self.title = JSONValue.string(json["title"]) ?? L10n.unnamedFavoriteFolder
        self.mediaCount = JSONValue.int(json["media_count"]) ?? 0
        self.coverURL = JSONValue.string(json["cover"])?.normalizedBiliURLString
        self.intro = JSONValue.string(json["intro"])
    }
}

struct VideoDetailPage: Identifiable, Hashable {
    let cid: Int
    let page: Int
    let part: String
    let duration: Int?

    var id: String { "\(cid)-\(page)" }

    init(json: [String: Any]) {
        self.cid = JSONValue.int(json["cid"]) ?? 0
        self.page = JSONValue.int(json["page"]) ?? 1
        self.part = JSONValue.string(json["part"]) ?? "P\(page)"
        self.duration = BiliFormatting.parseDuration(json["duration"])
    }
}

struct VideoDetail: Hashable {
    let aid: Int?
    let bvid: String
    let title: String
    let description: String
    let coverURL: String?
    let duration: Int?
    let publishDate: Date?
    let authorName: String
    let authorID: Int?
    let authorAvatarURL: String?
    let viewCount: Int?
    let likeCount: Int?
    let danmakuCount: Int?
    let pages: [VideoDetailPage]

    init(json: [String: Any]) {
        let owner = JSONValue.dictionary(json["owner"])
        let stat = JSONValue.dictionary(json["stat"])
        self.aid = JSONValue.int(json["aid"])
        self.bvid = JSONValue.string(json["bvid"]) ?? ""
        self.title = HTMLSanitizer.plainText(JSONValue.string(json["title"]))
        self.description = HTMLSanitizer.plainText(JSONValue.string(json["desc"]))
        self.coverURL = JSONValue.string(json["pic"])?.normalizedBiliURLString
        self.duration = BiliFormatting.parseDuration(json["duration"])
        if let timestamp = JSONValue.double(json["pubdate"]) {
            self.publishDate = Date(timeIntervalSince1970: timestamp)
        } else {
            self.publishDate = nil
        }
        self.authorName = JSONValue.string(owner?["name"]) ?? L10n.unknownUP
        self.authorID = JSONValue.int(owner?["mid"])
        self.authorAvatarURL = JSONValue.string(owner?["face"])?.normalizedBiliURLString
        self.viewCount = JSONValue.int(stat?["view"])
        self.likeCount = JSONValue.int(stat?["like"])
        self.danmakuCount = JSONValue.int(stat?["danmaku"])
        self.pages = JSONValue.dictionaries(json["pages"]).map(VideoDetailPage.init)
    }
}
