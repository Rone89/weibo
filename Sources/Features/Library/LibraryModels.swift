import Foundation

struct HistoryEntry: Identifiable, Hashable {
    let id: String
    let video: VideoSummary
    let viewedAt: Date?
    let progress: Int?
    let badge: String?
    let pageTitle: String?

    init(json: [String: Any]) {
        let history = JSONValue.dictionary(json["history"])
        let oid = JSONValue.int(history?["oid"]) ?? JSONValue.int(json["kid"]) ?? 0
        let bvid = JSONValue.string(history?["bvid"]) ?? ""
        let cid = JSONValue.int(history?["cid"])
        self.id = !bvid.isEmpty ? bvid : "history-\(oid)-\(cid ?? 0)"
        self.video = VideoSummary(
            aid: oid == 0 ? nil : oid,
            bvid: bvid,
            cid: cid,
            title: HTMLSanitizer.plainText(JSONValue.string(json["title"])),
            subtitle: HTMLSanitizer.plainText(JSONValue.string(json["show_title"]) ?? JSONValue.string(json["tag_name"])),
            coverURL: JSONValue.string(json["cover"])?.normalizedBiliURLString,
            duration: JSONValue.int(json["duration"]),
            publishDate: nil,
            authorName: JSONValue.string(json["author_name"]) ?? L10n.unknownUP,
            authorID: JSONValue.int(json["author_mid"]),
            authorAvatarURL: nil,
            viewCount: nil,
            likeCount: nil,
            danmakuCount: nil,
            reason: nil
        )
        if let timestamp = JSONValue.double(json["view_at"]) {
            self.viewedAt = Date(timeIntervalSince1970: timestamp)
        } else {
            self.viewedAt = nil
        }
        self.progress = JSONValue.int(json["progress"])
        self.badge = JSONValue.string(json["badge"])
        self.pageTitle = JSONValue.string(json["show_title"])
    }
}

struct WatchLaterEntry: Identifiable, Hashable {
    let id: String
    let video: VideoSummary
    let progress: Int?

    init(json: [String: Any]) {
        let owner = JSONValue.dictionary(json["owner"])
        let stat = JSONValue.dictionary(json["stat"])
        let aid = JSONValue.int(json["aid"])
        let bvid = JSONValue.string(json["bvid"]) ?? ""
        let cid = JSONValue.int(json["cid"]) ?? JSONValue.int(JSONValue.dictionary(json["ugc"])?["first_cid"])
        self.id = !bvid.isEmpty ? bvid : "later-\(aid ?? 0)"
        self.video = VideoSummary(
            aid: aid,
            bvid: bvid,
            cid: cid,
            title: HTMLSanitizer.plainText(JSONValue.string(json["title"])),
            subtitle: HTMLSanitizer.plainText(JSONValue.string(json["subtitle"]) ?? JSONValue.string(json["pgc_label"])),
            coverURL: JSONValue.string(json["pic"])?.normalizedBiliURLString,
            duration: JSONValue.int(json["duration"]),
            publishDate: JSONValue.double(json["pubdate"]).map { Date(timeIntervalSince1970: $0) },
            authorName: JSONValue.string(owner?["name"]) ?? L10n.unknownUP,
            authorID: JSONValue.int(owner?["mid"]),
            authorAvatarURL: JSONValue.string(owner?["face"])?.normalizedBiliURLString,
            viewCount: JSONValue.int(stat?["view"]) ?? JSONValue.int(stat?["play"]),
            likeCount: JSONValue.int(stat?["like"]),
            danmakuCount: JSONValue.int(stat?["danmaku"]),
            reason: nil
        )
        self.progress = JSONValue.int(json["progress"])
    }
}

struct FavoriteFolderDetail: Hashable {
    let info: FavoriteFolder?
    var medias: [FavoriteMedia]
    let hasMore: Bool
}

struct FavoriteMedia: Identifiable, Hashable {
    let id: String
    let video: VideoSummary
    let favoriteTime: Date?

    init(json: [String: Any]) {
        let upper = JSONValue.dictionary(json["upper"])
        let cntInfo = JSONValue.dictionary(json["cnt_info"])
        let ugc = JSONValue.dictionary(json["ugc"])
        let rawID = JSONValue.int(json["id"]) ?? 0
        let bvid = JSONValue.string(json["bvid"]) ?? JSONValue.string(json["bv_id"]) ?? ""
        self.id = !bvid.isEmpty ? bvid : "fav-\(rawID)"
        self.video = VideoSummary(
            aid: rawID == 0 ? nil : rawID,
            bvid: bvid,
            cid: JSONValue.int(ugc?["first_cid"]),
            title: HTMLSanitizer.plainText(JSONValue.string(json["title"])),
            subtitle: HTMLSanitizer.plainText(JSONValue.string(json["intro"])),
            coverURL: JSONValue.string(json["cover"])?.normalizedBiliURLString,
            duration: JSONValue.int(json["duration"]),
            publishDate: nil,
            authorName: JSONValue.string(upper?["name"]) ?? L10n.unknownUP,
            authorID: JSONValue.int(upper?["mid"]),
            authorAvatarURL: JSONValue.string(upper?["face"])?.normalizedBiliURLString,
            viewCount: JSONValue.int(cntInfo?["play"]),
            likeCount: nil,
            danmakuCount: JSONValue.int(cntInfo?["danmaku"]),
            reason: nil
        )
        if let timestamp = JSONValue.double(json["fav_time"]) {
            self.favoriteTime = Date(timeIntervalSince1970: timestamp)
        } else {
            self.favoriteTime = nil
        }
    }
}
