import Foundation

struct VideoCommentPage: Hashable {
    let topReplies: [VideoComment]
    let replies: [VideoComment]
    let nextOffset: String
    let isEnd: Bool
    let totalCount: Int
    let inputPlaceholder: String?
    let childInputPlaceholder: String?

    init(json: [String: Any]) {
        let cursor = JSONValue.dictionary(json["cursor"]) ?? [:]
        let pagination = JSONValue.dictionary(cursor["pagination_reply"]) ?? [:]
        let control = JSONValue.dictionary(json["control"]) ?? [:]

        self.topReplies = JSONValue.dictionaries(json["top_replies"]).map(VideoComment.init)
        self.replies = JSONValue.dictionaries(json["replies"]).map(VideoComment.init)
        self.nextOffset = JSONValue.string(pagination["next_offset"]) ?? ""
        self.isEnd = JSONValue.bool(cursor["is_end"]) ?? false
        self.totalCount = JSONValue.int(cursor["all_count"]) ?? 0
        self.inputPlaceholder = JSONValue.string(control["root_input_text"])
        self.childInputPlaceholder = JSONValue.string(control["child_input_text"])
    }
}

struct VideoCommentReplyPage: Hashable {
    let rootComment: VideoComment?
    let replies: [VideoComment]
    let pageNumber: Int
    let pageSize: Int
    let totalCount: Int
    let inputPlaceholder: String?

    init(json: [String: Any]) {
        let page = JSONValue.dictionary(json["page"]) ?? [:]
        let control = JSONValue.dictionary(json["control"]) ?? [:]

        self.rootComment = JSONValue.dictionary(json["root"]).map(VideoComment.init)
        self.replies = JSONValue.dictionaries(json["replies"]).map(VideoComment.init)
        self.pageNumber = JSONValue.int(page["num"]) ?? 1
        self.pageSize = JSONValue.int(page["size"]) ?? 10
        self.totalCount = JSONValue.int(page["count"]) ?? replies.count
        self.inputPlaceholder = JSONValue.string(control["child_input_text"]) ?? JSONValue.string(control["root_input_text"])
    }
}

struct VideoComment: Identifiable, Hashable {
    let id: String
    let oid: Int?
    let type: Int?
    let rootID: String?
    let parentID: String?
    let author: VideoCommentAuthor
    let message: String
    let likeCount: Int
    let replyCount: Int
    let previewReplies: [VideoComment]
    let publishedAt: Date?
    let timeLabel: String?
    let replySummaryLabel: String?
    let parentReplyUserName: String?

    var numericID: Int? {
        Int(id)
    }

    var rootNumericID: Int? {
        if let rootID, let parsed = Int(rootID), parsed > 0 {
            return parsed
        }
        return numericID
    }

    init(json: [String: Any]) {
        let member = JSONValue.dictionary(json["member"]) ?? [:]
        let content = JSONValue.dictionary(json["content"]) ?? [:]
        let replyControl = JSONValue.dictionary(json["reply_control"]) ?? [:]
        let parentReplyMember = JSONValue.dictionary(json["parent_reply_member"])

        self.id = JSONValue.string(json["rpid_str"]) ?? "\(JSONValue.int(json["rpid"]) ?? 0)"
        self.oid = JSONValue.int(json["oid"])
        self.type = JSONValue.int(json["type"])
        self.rootID = JSONValue.string(json["root_str"])
        self.parentID = JSONValue.string(json["parent_str"])
        self.author = VideoCommentAuthor(json: member)
        self.message = HTMLSanitizer.plainText(JSONValue.string(content["message"]))
        self.likeCount = JSONValue.int(json["like"]) ?? 0
        self.replyCount = JSONValue.int(json["rcount"]) ?? JSONValue.int(json["count"]) ?? 0
        self.previewReplies = JSONValue.dictionaries(json["replies"]).map(VideoComment.init)
        self.publishedAt = JSONValue.int(json["ctime"]).map { Date(timeIntervalSince1970: TimeInterval($0)) }
        self.timeLabel = JSONValue.string(replyControl["time_desc"])
        self.replySummaryLabel = JSONValue.string(replyControl["sub_reply_entry_text"])
        self.parentReplyUserName = JSONValue.string(parentReplyMember?["name"])
    }
}

struct VideoCommentAuthor: Hashable {
    let id: Int?
    let name: String
    let avatarURL: String?
    let level: Int?
    let isVIP: Bool

    init(json: [String: Any]) {
        let levelInfo = JSONValue.dictionary(json["level_info"])
        let vip = JSONValue.dictionary(json["vip"])

        self.id = JSONValue.int(json["mid"])
        self.name = JSONValue.string(json["uname"]) ?? L10n.unknownUP
        self.avatarURL = JSONValue.string(json["avatar"])?.normalizedBiliURLString
        self.level = JSONValue.int(levelInfo?["current_level"])
        self.isVIP = (JSONValue.int(vip?["vipStatus"]) ?? 0) > 0
    }
}
