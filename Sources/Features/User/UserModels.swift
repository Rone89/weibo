import Foundation

struct UserReference: Identifiable, Hashable {
    let mid: Int
    let name: String
    let avatarURL: String?

    var id: Int { mid }
}

struct UserCardProfile: Hashable {
    let mid: Int
    let name: String
    let avatarURL: String?
    let signature: String?
    let level: Int?
    let vipStatus: Int
    let archiveCount: Int
    let followerCount: Int

    init(json: [String: Any]) {
        let card = JSONValue.dictionary(json["card"]) ?? json
        self.mid = JSONValue.int(card["mid"]) ?? 0
        self.name = HTMLSanitizer.plainText(JSONValue.string(card["name"])).isEmpty
            ? L10n.unknownUP
            : HTMLSanitizer.plainText(JSONValue.string(card["name"]))
        self.avatarURL = JSONValue.string(card["face"])?.normalizedBiliURLString
        self.signature = HTMLSanitizer.plainText(JSONValue.string(card["sign"]))
        self.level = JSONValue.int(card["level"])
        self.vipStatus = JSONValue.int(JSONValue.dictionary(card["vip"])?["vipStatus"]) ?? 0
        self.archiveCount = JSONValue.int(json["archive_count"]) ?? JSONValue.int(card["archive_count"]) ?? 0
        self.followerCount = JSONValue.int(json["follower"]) ?? JSONValue.int(card["fans"]) ?? 0
    }

    var reference: UserReference {
        UserReference(mid: mid, name: name, avatarURL: avatarURL)
    }
}

struct UserRelationStat: Hashable {
    let followingCount: Int
    let followerCount: Int
    let dynamicCount: Int

    init(json: [String: Any]) {
        self.followingCount = JSONValue.int(json["following"]) ?? 0
        self.followerCount = JSONValue.int(json["follower"]) ?? 0
        self.dynamicCount = JSONValue.int(json["dynamic_count"]) ?? 0
    }
}

struct UserRelationState: Hashable {
    var attribute: Int
    var special: Int
    var tag: [Int]

    init(json: [String: Any]) {
        self.attribute = JSONValue.int(json["attribute"]) ?? 0
        self.special = JSONValue.int(json["special"]) ?? 0
        self.tag = (json["tag"] as? [Int]) ??
            (json["tag"] as? [NSNumber])?.map(\.intValue) ??
            JSONValue.stringArray(json["tag"]).compactMap(Int.init)
    }

    var isFollowing: Bool {
        attribute != 0 && attribute != 128 && attribute != -1
    }

    var isBlocked: Bool {
        attribute == 128
    }
}

enum UserRelationListKind: String, Identifiable {
    case followings
    case fans

    var id: String { rawValue }

    var title: String {
        switch self {
        case .followings:
            return L10n.userRelationFollowings
        case .fans:
            return L10n.userRelationFans
        }
    }

    var systemImage: String {
        switch self {
        case .followings:
            return "person.2.fill"
        case .fans:
            return "person.3.fill"
        }
    }
}

struct UserRelationListItem: Identifiable, Hashable {
    let mid: Int
    let name: String
    let avatarURL: String?
    let signature: String?
    let officialType: Int?
    var attribute: Int

    var id: Int { mid }

    init(json: [String: Any]) {
        let official = JSONValue.dictionary(json["official_verify"])
        self.mid = JSONValue.int(json["mid"]) ?? 0
        self.name = HTMLSanitizer.plainText(JSONValue.string(json["uname"])).isEmpty
            ? L10n.unknownUP
            : HTMLSanitizer.plainText(JSONValue.string(json["uname"]))
        self.avatarURL = JSONValue.string(json["face"])?.normalizedBiliURLString
        self.signature = HTMLSanitizer.plainText(JSONValue.string(json["sign"]))
        self.officialType = JSONValue.int(official?["type"])
        self.attribute = JSONValue.int(json["attribute"]) ?? -1
    }

    var reference: UserReference {
        UserReference(mid: mid, name: name, avatarURL: avatarURL)
    }

    var isFollowingByCurrentUser: Bool {
        attribute != -1
    }

    func updatedFollowState(_ isFollowing: Bool) -> UserRelationListItem {
        var copy = self
        copy.attribute = isFollowing ? 2 : -1
        return copy
    }
}
