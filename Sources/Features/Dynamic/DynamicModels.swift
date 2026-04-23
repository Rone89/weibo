import Foundation

struct DynamicFeedPage: Hashable {
    let items: [DynamicFeedItem]
    let nextOffset: String
    let hasMore: Bool
}

struct DynamicFeedItem: Identifiable, Hashable {
    let id: String
    let author: DynamicFeedAuthor
    let text: String
    let topic: String?
    let images: [DynamicFeedImage]
    let video: VideoSummary?
    let stats: DynamicFeedStats
    let publishedAt: Date?
    let publishLabel: String?
    let actionLabel: String?
    let commentOID: Int?
    let commentType: Int?
    let quoted: DynamicFeedQuotedContent?

    var hasDisplayContent: Bool {
        !text.isEmpty || !images.isEmpty || video != nil || quoted?.hasDisplayContent == true
    }

    init(json: [String: Any]) {
        let modules = JSONValue.dictionary(json["modules"]) ?? [:]
        let authorJSON = JSONValue.dictionary(modules["module_author"]) ?? [:]
        let dynamicJSON = JSONValue.dictionary(modules["module_dynamic"]) ?? [:]
        let statJSON = JSONValue.dictionary(modules["module_stat"]) ?? [:]
        let basicJSON = JSONValue.dictionary(json["basic"]) ?? [:]

        self.id = JSONValue.string(json["id_str"]) ?? UUID().uuidString
        self.author = DynamicFeedAuthor(json: authorJSON)
        self.text = DynamicFeedItem.composedText(dynamicJSON: dynamicJSON)
        self.topic = JSONValue.string(JSONValue.dictionary(dynamicJSON["topic"])?["name"])
        self.images = DynamicFeedItem.images(dynamicJSON: dynamicJSON)
        self.video = DynamicFeedItem.embeddedVideo(dynamicJSON: dynamicJSON)
        self.stats = DynamicFeedStats(json: statJSON)
        self.publishedAt = JSONValue.int(authorJSON["pub_ts"]).map { Date(timeIntervalSince1970: TimeInterval($0)) }
        self.publishLabel = JSONValue.string(authorJSON["pub_time"])
        self.actionLabel = JSONValue.string(authorJSON["pub_action"])
        self.commentOID = JSONValue.int(basicJSON["comment_id_str"]) ?? JSONValue.int(basicJSON["comment_id"])
        self.commentType = JSONValue.int(basicJSON["comment_type"])

        if let original = JSONValue.dictionary(json["orig"]) {
            self.quoted = DynamicFeedQuotedContent(json: original)
        } else {
            self.quoted = nil
        }
    }

    fileprivate static func snippet(json: [String: Any]) -> DynamicFeedSnippet {
        let modules = JSONValue.dictionary(json["modules"]) ?? [:]
        let authorJSON = JSONValue.dictionary(modules["module_author"]) ?? [:]
        let dynamicJSON = JSONValue.dictionary(modules["module_dynamic"]) ?? [:]

        return DynamicFeedSnippet(
            authorName: JSONValue.string(authorJSON["name"]) ?? L10n.unknownUP,
            text: composedText(dynamicJSON: dynamicJSON),
            topic: JSONValue.string(JSONValue.dictionary(dynamicJSON["topic"])?["name"]),
            images: images(dynamicJSON: dynamicJSON),
            video: embeddedVideo(dynamicJSON: dynamicJSON)
        )
    }

    private static func composedText(dynamicJSON: [String: Any]) -> String {
        let desc = HTMLSanitizer.plainText(JSONValue.string(JSONValue.dictionary(dynamicJSON["desc"])?["text"]))
        let major = JSONValue.dictionary(dynamicJSON["major"]) ?? [:]
        let opus = JSONValue.dictionary(major["opus"]) ?? [:]
        let title = HTMLSanitizer.plainText(JSONValue.string(opus["title"]))
        let summary = HTMLSanitizer.plainText(JSONValue.string(JSONValue.dictionary(opus["summary"])?["text"]))

        let pieces = [desc, title, summary].filter { !$0.isEmpty }
        return pieces.joined(separator: "\n")
    }

    private static func images(dynamicJSON: [String: Any]) -> [DynamicFeedImage] {
        let major = JSONValue.dictionary(dynamicJSON["major"]) ?? [:]
        let opus = JSONValue.dictionary(major["opus"]) ?? [:]
        return JSONValue.dictionaries(opus["pics"]).enumerated().map { index, picJSON in
            DynamicFeedImage(json: picJSON, fallbackID: "img-\(index)")
        }
    }

    private static func embeddedVideo(dynamicJSON: [String: Any]) -> VideoSummary? {
        let major = JSONValue.dictionary(dynamicJSON["major"]) ?? [:]
        let videoJSON =
            JSONValue.dictionary(major["archive"]) ??
            JSONValue.dictionary(major["ugc_season"]) ??
            JSONValue.dictionary(major["pgc"]) ??
            JSONValue.dictionary(major["courses"])

        guard let videoJSON else { return nil }

        let stat = JSONValue.dictionary(videoJSON["stat"])
        let id = JSONValue.int(videoJSON["aid"]) ?? JSONValue.int(videoJSON["id"])
        let bvid = JSONValue.string(videoJSON["bvid"]) ?? ""

        return VideoSummary(
            aid: id,
            bvid: bvid,
            cid: nil,
            title: HTMLSanitizer.plainText(JSONValue.string(videoJSON["title"])),
            subtitle: HTMLSanitizer.plainText(
                JSONValue.string(videoJSON["desc"]) ??
                JSONValue.string(JSONValue.dictionary(videoJSON["badge"])?["text"])
            ),
            coverURL: JSONValue.string(videoJSON["cover"])?.normalizedBiliURLString,
            duration: BiliFormatting.parseDuration(JSONValue.string(videoJSON["duration_text"])),
            publishDate: nil,
            authorName: L10n.unknownUP,
            authorID: nil,
            authorAvatarURL: nil,
            viewCount: JSONValue.int(stat?["play"]),
            likeCount: nil,
            danmakuCount: JSONValue.int(stat?["danmaku"]),
            reason: nil
        )
    }
}

struct DynamicFeedAuthor: Hashable {
    let mid: Int?
    let name: String
    let avatarURL: String?
    let badgeText: String?

    init(json: [String: Any]) {
        self.mid = JSONValue.int(json["mid"])
        self.name = JSONValue.string(json["name"]) ?? L10n.unknownUP
        self.avatarURL = JSONValue.string(json["face"])?.normalizedBiliURLString
        self.badgeText = JSONValue.string(JSONValue.dictionary(json["icon_badge"])?["text"])
    }
}

struct DynamicFeedStats: Hashable {
    let likeCount: Int
    let commentCount: Int
    let shareCount: Int
    let isLiked: Bool

    init(json: [String: Any]) {
        let like = JSONValue.dictionary(json["like"])
        let comment = JSONValue.dictionary(json["comment"])
        let forward = JSONValue.dictionary(json["forward"])

        self.likeCount = JSONValue.int(like?["count"]) ?? 0
        self.commentCount = JSONValue.int(comment?["count"]) ?? 0
        self.shareCount = JSONValue.int(forward?["count"]) ?? 0
        self.isLiked = JSONValue.bool(like?["status"]) ?? false
    }
}

struct DynamicFeedImage: Identifiable, Hashable {
    let id: String
    let url: String?
    let width: Int?
    let height: Int?

    init(json: [String: Any], fallbackID: String) {
        self.id = JSONValue.string(json["url"]) ?? JSONValue.string(json["src"]) ?? fallbackID
        self.url = (JSONValue.string(json["url"]) ?? JSONValue.string(json["src"]))?.normalizedBiliURLString
        self.width = JSONValue.int(json["width"])
        self.height = JSONValue.int(json["height"])
    }
}

struct DynamicFeedQuotedContent: Hashable {
    let authorName: String
    let text: String
    let topic: String?
    let images: [DynamicFeedImage]
    let video: VideoSummary?

    var hasDisplayContent: Bool {
        !text.isEmpty || !images.isEmpty || video != nil
    }

    init(json: [String: Any]) {
        let snippet = DynamicFeedItem.snippet(json: json)
        self.authorName = snippet.authorName
        self.text = snippet.text
        self.topic = snippet.topic
        self.images = snippet.images
        self.video = snippet.video
    }
}

private struct DynamicFeedSnippet: Hashable {
    let authorName: String
    let text: String
    let topic: String?
    let images: [DynamicFeedImage]
    let video: VideoSummary?
}
