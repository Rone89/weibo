import Foundation

enum SearchScope: String, CaseIterable, Identifiable {
    case video
    case user

    var id: String { rawValue }

    var title: String {
        switch self {
        case .video:
            return L10n.searchScopeVideo
        case .user:
            return L10n.searchScopeUser
        }
    }

    var searchTypeValue: String {
        switch self {
        case .video:
            return "video"
        case .user:
            return "bili_user"
        }
    }

    var refererPathComponent: String {
        searchTypeValue
    }

    var systemImage: String {
        switch self {
        case .video:
            return "play.rectangle.fill"
        case .user:
            return "person.2.fill"
        }
    }
}

enum VideoSearchOrder: String, CaseIterable, Identifiable {
    case totalrank
    case click
    case pubdate
    case dm
    case stow
    case scores

    var id: String { rawValue }

    var title: String {
        switch self {
        case .totalrank:
            return L10n.searchSortDefault
        case .click:
            return L10n.searchSortPlays
        case .pubdate:
            return L10n.searchSortNewest
        case .dm:
            return L10n.searchSortDanmaku
        case .stow:
            return L10n.searchSortFavorites
        case .scores:
            return L10n.searchSortComments
        }
    }
}

enum VideoDurationFilter: Int, CaseIterable, Identifiable {
    case all = 0
    case tenMinutes = 1
    case halfHour = 2
    case hour = 3
    case hourPlus = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .all:
            return L10n.searchDurationAll
        case .tenMinutes:
            return L10n.searchDurationShort
        case .halfHour:
            return L10n.searchDurationMedium
        case .hour:
            return L10n.searchDurationLong
        case .hourPlus:
            return L10n.searchDurationXL
        }
    }
}

enum SearchResultItem: Identifiable, Hashable {
    case video(VideoSummary)
    case user(SearchUserResult)

    var id: String {
        switch self {
        case .video(let video):
            return "video-\(video.id)"
        case .user(let item):
            return "user-\(item.id)"
        }
    }
}

struct SearchUserResult: Identifiable, Hashable {
    let mid: Int
    let name: String
    let signature: String?
    let avatarURL: String?
    let fansCount: Int?
    let videosCount: Int?
    let level: Int?
    let verifyInfo: String?
    let isLive: Bool
    let roomID: Int?

    var id: Int { mid }

    init(json: [String: Any]) {
        let rawName = HTMLSanitizer.plainText(JSONValue.string(json["uname"]))
        self.mid = JSONValue.int(json["mid"]) ?? 0
        self.name = rawName.isEmpty ? L10n.unknownUP : rawName
        self.signature = HTMLSanitizer.plainText(JSONValue.string(json["usign"]))
        self.avatarURL = JSONValue.string(json["upic"])?.normalizedBiliURLString
        self.fansCount = JSONValue.int(json["fans"])
        self.videosCount = JSONValue.int(json["videos"])
        self.level = JSONValue.int(json["level"])
        self.verifyInfo = HTMLSanitizer.plainText(JSONValue.string(json["verify_info"]))
        self.isLive = (JSONValue.int(json["is_live"]) ?? 0) > 0
        self.roomID = JSONValue.int(json["room_id"])
    }

    var reference: UserReference {
        UserReference(mid: mid, name: name, avatarURL: avatarURL)
    }
}
