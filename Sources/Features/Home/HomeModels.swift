import Foundation

struct HomeLiveSummary: Identifiable, Hashable {
    let roomID: Int
    let streamerID: Int?
    let streamerName: String
    let avatarURL: String?
    let coverURL: String?
    let title: String
    let areaName: String?

    var id: Int { roomID }

    init(json: [String: Any]) {
        self.roomID = JSONValue.int(json["roomid"]) ?? JSONValue.int(json["id"]) ?? 0
        self.streamerID = JSONValue.int(json["uid"])
        let rawName = HTMLSanitizer.plainText(JSONValue.string(json["uname"]))
        self.streamerName = rawName.isEmpty ? L10n.unknownUP : rawName
        self.avatarURL = JSONValue.string(json["face"])?.normalizedBiliURLString
        self.coverURL = (JSONValue.string(json["system_cover"]) ?? JSONValue.string(json["cover"]))?.normalizedBiliURLString
        self.title = HTMLSanitizer.plainText(JSONValue.string(json["title"]))
        self.areaName = HTMLSanitizer.plainText(JSONValue.string(json["area_name"]))
    }

    var streamerReference: UserReference? {
        guard let streamerID, streamerID > 0 else { return nil }
        return UserReference(mid: streamerID, name: streamerName, avatarURL: avatarURL)
    }
}

struct HomeBangumiSummary: Identifiable, Hashable {
    let seasonID: Int
    let title: String
    let coverURL: String?
    let updateLabel: String?
    let ratingLabel: String?

    var id: Int { seasonID }

    init(json: [String: Any]) {
        let newEpisode = JSONValue.dictionary(json["new_ep"])
        let stat = JSONValue.dictionary(json["stat"])

        self.seasonID = JSONValue.int(json["season_id"]) ?? JSONValue.int(json["media_id"]) ?? 0
        self.title = HTMLSanitizer.plainText(JSONValue.string(json["title"]))
        self.coverURL = JSONValue.string(json["cover"])?.normalizedBiliURLString
        self.updateLabel = HTMLSanitizer.plainText(JSONValue.string(newEpisode?["index_show"]))
        self.ratingLabel = JSONValue.string(stat?["score"])
    }
}
