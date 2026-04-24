import Foundation

@MainActor
final class VideoDetailViewModel: ObservableObject {
    @Published private(set) var detail: VideoDetail?
    @Published private(set) var relation: VideoRelationState?
    @Published private(set) var favoriteFolders: [FavoriteFolder] = []
    @Published private(set) var remoteResumeSeconds: TimeInterval?
    @Published private(set) var remoteResumeCID: Int?
    @Published private(set) var isLoadingFavoriteFolders = false
    @Published private(set) var isSubmittingLike = false
    @Published private(set) var isSubmittingCoin = false
    @Published private(set) var isSubmittingFavorite = false
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var actionMessage: String?

    let seedVideo: VideoSummary
    let apiClient: BiliAPIClient
    private var hasLoaded = false

    init(apiClient: BiliAPIClient, seedVideo: VideoSummary) {
        self.apiClient = apiClient
        self.seedVideo = seedVideo
    }

    var hasSession: Bool {
        apiClient.sessionStore.hasCookie
    }

    var isLiked: Bool {
        relation?.like ?? false
    }

    var isFavorited: Bool {
        (relation?.favorite ?? false) || (relation?.seasonFavorite ?? false)
    }

    var userCoinCount: Int {
        relation?.coin ?? 0
    }

    var maxCoinCount: Int {
        detail?.copyright == 2 ? 1 : 2
    }

    var remainingCoinCount: Int {
        max(0, maxCoinCount - userCoinCount)
    }

    var displayedLikeCount: Int {
        detail?.likeCount ?? seedVideo.likeCount ?? 0
    }

    var displayedReplyCount: Int {
        detail?.replyCount ?? 0
    }

    var displayedFavoriteCount: Int {
        detail?.favoriteCount ?? 0
    }

    var displayedCoinCount: Int {
        detail?.coinCount ?? 0
    }

    private var currentBVID: String {
        let detailBVID = detail?.bvid ?? ""
        return detailBVID.isEmpty ? seedVideo.bvid : detailBVID
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await reload()
    }

    func reload() async {
        guard !seedVideo.bvid.isEmpty else {
            errorMessage = L10n.missingBVID
            return
        }

        isLoading = true
        errorMessage = nil
        actionMessage = nil
        relation = nil
        favoriteFolders = []
        remoteResumeSeconds = nil
        remoteResumeCID = nil

        do {
            let loadedDetail = try await fetchVideoDetail()
            self.detail = loadedDetail
            relation = try? await fetchVideoRelation(detail: loadedDetail)
            try? await hydrateRemoteResume(detail: loadedDetail)
            self.hasLoaded = true
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func currentPlayableVideo(page: VideoDetailPage?) -> VideoSummary {
        VideoSummary(
            aid: detail?.aid ?? seedVideo.aid,
            bvid: detail?.bvid ?? seedVideo.bvid,
            cid: page?.cid ?? detail?.pages.first?.cid ?? seedVideo.cid,
            title: detail?.title ?? seedVideo.title,
            subtitle: detail?.description ?? seedVideo.subtitle,
            coverURL: detail?.coverURL ?? seedVideo.coverURL,
            duration: page?.duration ?? detail?.duration ?? seedVideo.duration,
            publishDate: detail?.publishDate ?? seedVideo.publishDate,
            authorName: detail?.authorName ?? seedVideo.authorName,
            authorID: detail?.authorID ?? seedVideo.authorID,
            authorAvatarURL: detail?.authorAvatarURL ?? seedVideo.authorAvatarURL,
            viewCount: detail?.viewCount ?? seedVideo.viewCount,
            likeCount: detail?.likeCount ?? seedVideo.likeCount,
            danmakuCount: detail?.danmakuCount ?? seedVideo.danmakuCount,
            reason: seedVideo.reason
        )
    }

    var hasRemoteResume: Bool {
        (remoteResumeSeconds ?? 0) > 5
    }

    func loadFavoriteFoldersIfNeeded(force: Bool = false) async {
        guard !isLoadingFavoriteFolders else { return }
        guard force || favoriteFolders.isEmpty else { return }
        errorMessage = nil
        guard let aid = detail?.aid ?? seedVideo.aid else {
            errorMessage = L10n.missingAidForFavorite
            return
        }

        isLoadingFavoriteFolders = true
        defer { isLoadingFavoriteFolders = false }

        do {
            let mid = try await currentUserMID()
            let data = try await apiClient.requestEnvelopeData(
                path: BiliEndpoint.userFavoriteFoldersAll,
                query: [
                    "up_mid": "\(mid)",
                    "rid": "\(aid)",
                    "type": "2"
                ]
            )
            favoriteFolders = JSONValue.dictionaries(data["list"]).map(FavoriteFolder.init)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleLike() async {
        guard !isSubmittingLike else { return }
        errorMessage = nil
        guard let csrf = try? await apiClient.requireCSRFToken() else {
            errorMessage = L10n.errorMissingCSRF
            return
        }

        let bvid = currentBVID
        guard !bvid.isEmpty else {
            errorMessage = L10n.missingBVID
            return
        }

        isSubmittingLike = true
        defer { isSubmittingLike = false }

        let shouldLike = !isLiked

        do {
            _ = try await apiClient.postEnvelopeValue(
                path: BiliEndpoint.likeVideo,
                form: [
                    "aid": (detail?.aid ?? seedVideo.aid).map(String.init) ?? "",
                    "bvid": bvid,
                    "like": shouldLike ? "1" : "2",
                    "csrf": csrf
                ].filter { !$0.value.isEmpty },
                headers: interactionHeaders(bvid: bvid)
            )

            updateRelation {
                $0.like = shouldLike
                if shouldLike {
                    $0.dislike = false
                }
            }
            updateDetailCounts(likeDelta: shouldLike ? 1 : -1)
            actionMessage = shouldLike ? L10n.videoLiked : L10n.videoUnliked
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func coinVideo(amount: Int, alsoLike: Bool) async {
        guard !isSubmittingCoin else { return }
        guard amount > 0 else { return }
        errorMessage = nil
        guard let csrf = try? await apiClient.requireCSRFToken() else {
            errorMessage = L10n.errorMissingCSRF
            return
        }

        let bvid = currentBVID
        guard !bvid.isEmpty else {
            errorMessage = L10n.missingBVID
            return
        }

        if amount > remainingCoinCount {
            actionMessage = L10n.videoCoinLimitReached
            return
        }

        isSubmittingCoin = true
        defer { isSubmittingCoin = false }

        do {
            _ = try await apiClient.postEnvelopeValue(
                path: BiliEndpoint.coinVideo,
                form: [
                    "aid": (detail?.aid ?? seedVideo.aid).map(String.init) ?? "",
                    "bvid": bvid,
                    "multiply": "\(amount)",
                    "select_like": alsoLike ? "1" : "0",
                    "csrf": csrf
                ].filter { !$0.value.isEmpty },
                headers: interactionHeaders(bvid: bvid)
            )

            let shouldLike = alsoLike && !isLiked
            updateRelation {
                $0.coin += amount
                if shouldLike {
                    $0.like = true
                    $0.dislike = false
                }
            }
            updateDetailCounts(
                likeDelta: shouldLike ? 1 : 0,
                favoriteDelta: 0,
                coinDelta: amount
            )
            actionMessage = L10n.videoCoinedCount(amount)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addToFavorites(folder: FavoriteFolder) async {
        guard !isSubmittingFavorite else { return }
        errorMessage = nil
        guard let aid = detail?.aid ?? seedVideo.aid else {
            errorMessage = L10n.missingAidForFavorite
            return
        }
        guard let csrf = try? await apiClient.requireCSRFToken() else {
            errorMessage = L10n.errorMissingCSRF
            return
        }

        isSubmittingFavorite = true
        defer { isSubmittingFavorite = false }

        let wasFavorited = isFavorited
        let bvid = currentBVID

        do {
            _ = try await apiClient.postEnvelopeValue(
                path: BiliEndpoint.favoriteVideoBatchDeal,
                form: [
                    "resources": "\(aid):2",
                    "add_media_ids": "\(folder.id)",
                    "del_media_ids": "",
                    "csrf": csrf
                ],
                headers: bvid.isEmpty ? [:] : interactionHeaders(bvid: bvid)
            )

            updateRelation {
                $0.favorite = true
                $0.seasonFavorite = false
            }
            if !wasFavorited {
                updateDetailCounts(favoriteDelta: 1)
            }
            actionMessage = L10n.addedToFavorite(folder.title)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeFromFavorites() async {
        guard !isSubmittingFavorite else { return }
        errorMessage = nil
        guard let aid = detail?.aid ?? seedVideo.aid else {
            errorMessage = L10n.missingAidForFavorite
            return
        }
        guard let csrf = try? await apiClient.requireCSRFToken() else {
            errorMessage = L10n.errorMissingCSRF
            return
        }

        isSubmittingFavorite = true
        defer { isSubmittingFavorite = false }

        let wasFavorited = isFavorited
        let bvid = currentBVID

        do {
            _ = try await apiClient.postEnvelopeValue(
                path: BiliEndpoint.favoriteVideoUnfavAll,
                form: [
                    "rid": "\(aid)",
                    "type": "2",
                    "csrf": csrf
                ],
                headers: bvid.isEmpty ? [:] : interactionHeaders(bvid: bvid)
            )

            updateRelation {
                $0.favorite = false
                $0.seasonFavorite = false
            }
            if wasFavorited {
                updateDetailCounts(favoriteDelta: -1)
            }
            actionMessage = L10n.videoFavoriteRemoved
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func fetchVideoDetail() async throws -> VideoDetail {
        let data = try await apiClient.requestEnvelopeData(
            path: BiliEndpoint.videoDetail,
            query: ["bvid": seedVideo.bvid]
        )
        return VideoDetail(json: data)
    }
    private func fetchVideoRelation(detail: VideoDetail) async throws -> VideoRelationState {
        let aid = detail.aid ?? seedVideo.aid
        let bvid = detail.bvid.isEmpty ? seedVideo.bvid : detail.bvid

        let data = try await apiClient.requestEnvelopeData(
            path: BiliEndpoint.videoRelation,
            query: [
                "aid": aid.map(String.init) ?? "",
                "bvid": bvid
            ].filter { !$0.value.isEmpty },
            headers: interactionHeaders(bvid: bvid)
        )
        return VideoRelationState(json: data)
    }

    private func hydrateRemoteResume(detail: VideoDetail) async throws {
        let includeCookies = !apiClient.preferencesStore.isIncognitoPlaybackEnabled
        guard includeCookies else { return }
        let cid = detail.pages.first?.cid ?? seedVideo.cid
        guard let cid, cid > 0 else { return }

        let data = try await apiClient.requestEnvelopeData(
            path: BiliEndpoint.playInfo,
            query: [
                "bvid": detail.bvid.isEmpty ? seedVideo.bvid : detail.bvid,
                "cid": "\(cid)"
            ],
            headers: [
                "Referer": "\(BiliBaseURL.web)/",
                "Origin": BiliBaseURL.web
            ],
            signedByWBI: true,
            includeCookies: includeCookies
        )

        let lastPlayTime = JSONValue.double(data["last_play_time"]) ?? 0
        let lastPlayCID = JSONValue.int(data["last_play_cid"]) ?? 0
        guard lastPlayTime > 5, lastPlayCID > 0 else { return }

        remoteResumeSeconds = lastPlayTime
        remoteResumeCID = lastPlayCID
    }

    private func currentUserMID() async throws -> Int {
        if let userID = apiClient.sessionStore.dedeUserID,
           let mid = Int(userID),
           mid > 0 {
            return mid
        }

        let nav = try await apiClient.requestEnvelopeData(path: BiliEndpoint.nav)
        let mid = JSONValue.int(nav["mid"]) ?? 0
        guard mid > 0 else {
            throw APIError.invalidPayload
        }
        return mid
    }

    private func interactionHeaders(bvid: String) -> [String: String] {
        [
            "Referer": "\(BiliBaseURL.web)/video/\(bvid)",
            "Origin": BiliBaseURL.web
        ]
    }

    private func updateRelation(_ mutation: (inout VideoRelationState) -> Void) {
        var current = relation ?? VideoRelationState(json: [:])
        mutation(&current)
        relation = current
    }

    private func updateDetailCounts(likeDelta: Int = 0, favoriteDelta: Int = 0, coinDelta: Int = 0) {
        guard var currentDetail = detail else { return }

        if let likeCount = currentDetail.likeCount {
            currentDetail.likeCount = max(0, likeCount + likeDelta)
        } else if likeDelta > 0 {
            currentDetail.likeCount = likeDelta
        }

        if let favoriteCount = currentDetail.favoriteCount {
            currentDetail.favoriteCount = max(0, favoriteCount + favoriteDelta)
        } else if favoriteDelta > 0 {
            currentDetail.favoriteCount = favoriteDelta
        }

        if let coinCount = currentDetail.coinCount {
            currentDetail.coinCount = max(0, coinCount + coinDelta)
        } else if coinDelta > 0 {
            currentDetail.coinCount = coinDelta
        }

        detail = currentDetail
    }
}
