import Foundation

@MainActor
final class UserProfileViewModel: ObservableObject {
    @Published private(set) var profile: UserCardProfile?
    @Published private(set) var relationStat: UserRelationStat?
    @Published private(set) var relation: UserRelationState?
    @Published private(set) var recentVideos: [VideoSummary] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSubmittingFollow = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var actionMessage: String?

    let apiClient: BiliAPIClient
    let reference: UserReference
    private var hasLoaded = false

    init(apiClient: BiliAPIClient, reference: UserReference) {
        self.apiClient = apiClient
        self.reference = reference
    }

    var isCurrentUser: Bool {
        guard let currentID = apiClient.sessionStore.dedeUserID.flatMap(Int.init) else { return false }
        return currentID == reference.mid
    }

    var displayName: String {
        profile?.name ?? reference.name
    }

    var isFollowing: Bool {
        relation?.isFollowing ?? false
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await reload()
    }

    func reload() async {
        guard reference.mid > 0 else {
            errorMessage = L10n.userProfileMissingMID
            return
        }

        isLoading = true
        errorMessage = nil
        actionMessage = nil

        do {
            async let cardTask = fetchCardProfile()
            async let statTask = fetchRelationStat()
            async let videosTask = fetchRecentVideos()

            let loadedProfile = try await cardTask
            self.profile = loadedProfile
            self.relationStat = try await statTask
            self.recentVideos = try await videosTask

            if apiClient.sessionStore.hasCookie, !isCurrentUser {
                relation = try? await fetchRelationState()
            } else {
                relation = nil
            }

            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func toggleFollow() async {
        guard !isCurrentUser else { return }
        guard !isSubmittingFollow else { return }
        guard apiClient.sessionStore.hasCookie else {
            errorMessage = L10n.userProfileFollowLoginHint
            return
        }

        let currentlyFollowing = isFollowing
        let action = currentlyFollowing ? 2 : 1

        isSubmittingFollow = true
        errorMessage = nil
        defer { isSubmittingFollow = false }

        do {
            let csrf = try await apiClient.requireCSRFToken()
            _ = try await apiClient.postEnvelopeValue(
                path: BiliEndpoint.userRelationModify,
                form: [
                    "fid": "\(reference.mid)",
                    "act": "\(action)",
                    "re_src": "11",
                    "gaia_source": "web_main",
                    "spmid": "333.1387",
                    "extend_content": #"{"entity":"user","entity_id":\#(reference.mid),"fp":"\#(BiliAPIClient.userAgent)"}"#,
                    "csrf": csrf
                ],
                query: [
                    "statistics": #"{"appId":100,"platform":5}"#,
                    "x-bili-device-req-json": #"{"platform":"web","device":"pc","spmid":"333.1387"}"#
                ],
                headers: relationHeaders
            )

            var updated = relation ?? UserRelationState(json: [:])
            updated.attribute = currentlyFollowing ? 0 : 2
            updated.special = currentlyFollowing ? 0 : updated.special
            relation = updated

            if let relationStat {
                self.relationStat = UserRelationStat(
                    json: [
                        "following": relationStat.followingCount,
                        "follower": max(0, relationStat.followerCount + (currentlyFollowing ? -1 : 1)),
                        "dynamic_count": relationStat.dynamicCount
                    ]
                )
            }

            actionMessage = currentlyFollowing ? L10n.userProfileUnfollowed : L10n.userProfileFollowed
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func fetchCardProfile() async throws -> UserCardProfile {
        let data = try await apiClient.requestEnvelopeData(
            path: BiliEndpoint.memberCardInfo,
            query: [
                "mid": "\(reference.mid)",
                "photo": "false"
            ]
        )
        return UserCardProfile(json: data)
    }

    private func fetchRelationStat() async throws -> UserRelationStat {
        let data = try await apiClient.requestEnvelopeData(
            path: BiliEndpoint.userRelationStat,
            query: ["vmid": "\(reference.mid)"]
        )
        return UserRelationStat(json: data)
    }

    private func fetchRelationState() async throws -> UserRelationState {
        let data = try await apiClient.requestEnvelopeData(
            path: BiliEndpoint.userRelation,
            query: ["fid": "\(reference.mid)"]
        )
        return UserRelationState(json: data)
    }

    private func fetchRecentVideos() async throws -> [VideoSummary] {
        let data = try await apiClient.requestEnvelopeData(
            path: BiliEndpoint.userArchiveSearch,
            query: [
                "mid": "\(reference.mid)",
                "ps": "20",
                "pn": "1",
                "order": "pubdate",
                "platform": "web",
                "web_location": "333.1387",
                "order_avoided": "true"
            ],
            headers: relationHeaders,
            signedByWBI: true
        )

        let list = JSONValue.dictionary(data["list"])
        return JSONValue.dictionaries(list?["vlist"]).map { item in
            VideoSummary(
                aid: JSONValue.int(item["aid"]),
                bvid: JSONValue.string(item["bvid"]) ?? "",
                cid: nil,
                title: HTMLSanitizer.plainText(JSONValue.string(item["title"])),
                subtitle: HTMLSanitizer.plainText(JSONValue.string(item["description"])),
                coverURL: JSONValue.string(item["pic"])?.normalizedBiliURLString,
                duration: BiliFormatting.parseDuration(item["length"]),
                publishDate: JSONValue.double(item["created"]).map { Date(timeIntervalSince1970: $0) },
                authorName: HTMLSanitizer.plainText(JSONValue.string(item["author"])).isEmpty
                    ? displayName
                    : HTMLSanitizer.plainText(JSONValue.string(item["author"])),
                authorID: JSONValue.int(item["mid"]) ?? reference.mid,
                authorAvatarURL: profile?.avatarURL ?? reference.avatarURL,
                viewCount: JSONValue.int(item["play"]),
                likeCount: nil,
                danmakuCount: JSONValue.int(item["video_review"]),
                reason: nil
            )
        }
    }

    private var relationHeaders: [String: String] {
        [
            "origin": "https://space.bilibili.com",
            "referer": "https://space.bilibili.com/\(reference.mid)/dynamic",
            "user-agent": BiliAPIClient.userAgent
        ]
    }
}
