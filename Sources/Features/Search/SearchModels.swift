import Foundation

enum SearchScope: String, CaseIterable, Identifiable {
    case video
    case bangumi
    case liveRoom
    case user

    var id: String { rawValue }

    var title: String {
        switch self {
        case .video:
            return L10n.searchScopeVideo
        case .bangumi:
            return L10n.searchScopeBangumi
        case .liveRoom:
            return L10n.searchScopeLive
        case .user:
            return L10n.searchScopeUser
        }
    }

    var searchTypeValue: String {
        switch self {
        case .video:
            return "video"
        case .bangumi:
            return "media_bangumi"
        case .liveRoom:
            return "live_room"
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
        case .bangumi:
            return "sparkles.tv"
        case .liveRoom:
            return "dot.radiowaves.left.and.right"
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
    case bangumi(SearchBangumiResult)
    case liveRoom(SearchLiveRoomResult)
    case user(SearchUserResult)

    var id: String {
        switch self {
        case .video(let video):
            return "video-\(video.id)"
        case .bangumi(let item):
            return "bangumi-\(item.id)"
        case .liveRoom(let item):
            return "live-\(item.id)"
        case .user(let item):
            return "user-\(item.id)"
        }
    }
}

struct SearchBangumiResult: Identifiable, Hashable {
    let mediaID: Int
    let seasonID: Int?
    let title: String
    let originalTitle: String?
    let seasonTypeName: String?
    let coverURL: String?
    let areas: String?
    let styles: String?
    let description: String?
    let indexShow: String?
    let score: String?

    var id: Int { mediaID }

    init(json: [String: Any]) {
        let mediaScore = JSONValue.dictionary(json["media_score"])
        let rawScore = JSONValue.string(mediaScore?["score"]) ?? JSONValue.string(mediaScore?["user_count"])

        self.mediaID = JSONValue.int(json["media_id"]) ?? JSONValue.int(json["season_id"]) ?? 0
        self.seasonID = JSONValue.int(json["season_id"])
        self.title = HTMLSanitizer.plainText(JSONValue.string(json["title"]))
        self.originalTitle = HTMLSanitizer.plainText(JSONValue.string(json["org_title"]))
        self.seasonTypeName = JSONValue.string(json["season_type_name"])
        self.coverURL = JSONValue.string(json["cover"])?.normalizedBiliURLString
        self.areas = HTMLSanitizer.plainText(JSONValue.string(json["areas"]))
        self.styles = HTMLSanitizer.plainText(JSONValue.string(json["styles"]))
        self.description = HTMLSanitizer.plainText(JSONValue.string(json["desc"]))
        self.indexShow = JSONValue.string(json["index_show"])
        self.score = rawScore
    }
}

struct SearchLiveRoomResult: Identifiable, Hashable {
    let roomID: Int
    let title: String
    let coverURL: String?
    let streamerName: String
    let streamerAvatarURL: String?
    let onlineCount: Int?
    let categoryName: String?
    let liveTimeLabel: String?
    let tags: String?

    var id: Int { roomID }

    init(json: [String: Any]) {
        let rawName = HTMLSanitizer.plainText(JSONValue.string(json["uname"]))
        self.roomID = JSONValue.int(json["roomid"]) ?? 0
        self.title = HTMLSanitizer.plainText(JSONValue.string(json["title"]))
        self.coverURL = (JSONValue.string(json["cover"]) ?? JSONValue.string(json["pic"]))?.normalizedBiliURLString
        self.streamerName = rawName.isEmpty ? L10n.unknownUP : rawName
        self.streamerAvatarURL = JSONValue.string(json["uface"])?.normalizedBiliURLString
        self.onlineCount = JSONValue.int(json["online"])
        self.categoryName = HTMLSanitizer.plainText(JSONValue.string(json["cate_name"]))
        self.liveTimeLabel = JSONValue.string(json["live_time"])
        self.tags = HTMLSanitizer.plainText(JSONValue.string(json["tags"]))
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
