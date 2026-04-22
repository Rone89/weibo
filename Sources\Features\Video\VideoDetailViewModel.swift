import Foundation

@MainActor
final class VideoDetailViewModel: ObservableObject {
    @Published private(set) var detail: VideoDetail?
    @Published private(set) var relatedVideos: [VideoSummary] = []
    @Published private(set) var favoriteFolders: [FavoriteFolder] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingFavoriteFolders = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var actionMessage: String?

    let seedVideo: VideoSummary
    let apiClient: BiliAPIClient
    private var hasLoaded = false

    init(apiClient: BiliAPIClient, seedVideo: VideoSummary) {
        self.apiClient = apiClient
        self.seedVideo = seedVideo
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

        do {
            async let detail = fetchVideoDetail()
            async let related = fetchRelatedVideos()
            self.detail = try await detail
            self.relatedVideos = try await related
            self.hasLoaded = true
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func prepareFavoriteFolders() async {
        guard favoriteFolders.isEmpty else { return }
        isLoadingFavoriteFolders = true
        defer { isLoadingFavoriteFolders = false }

        do {
            let nav = try await apiClient.requestEnvelopeData(path: BiliEndpoint.nav)
            let mid = JSONValue.int(nav["mid"]) ?? 0
            let data = try await apiClient.requestEnvelopeData(
                path: BiliEndpoint.userFavoriteFolders,
                query: [
                    "up_mid": "\(mid)",
                    "pn": "1",
                    "ps": "20"
                ]
            )
            favoriteFolders = JSONValue.dictionaries(data["list"]).map(FavoriteFolder.init)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addToWatchLater() async {
        do {
            let csrf = try apiClient.requireCSRFToken()
            var form: [String: String] = [
                "csrf": csrf
            ]
            if let aid = detail?.aid ?? seedVideo.aid {
                form["aid"] = "\(aid)"
            }
            if !(detail?.bvid ?? seedVideo.bvid).isEmpty {
                form["bvid"] = detail?.bvid ?? seedVideo.bvid
            }

            _ = try await apiClient.postEnvelopeValue(
                path: BiliEndpoint.watchLaterAdd,
                form: form
            )
            actionMessage = L10n.addedWatchLater
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addToFavorite(folder: FavoriteFolder) async {
        guard let aid = detail?.aid ?? seedVideo.aid else {
            errorMessage = L10n.missingAidForFavorite
            return
        }

        do {
            let csrf = try apiClient.requireCSRFToken()
            _ = try await apiClient.postEnvelopeValue(
                path: BiliEndpoint.favoriteVideoBatchDeal,
                form: [
                    "resources": "\(aid):2",
                    "add_media_ids": "\(folder.id)",
                    "del_media_ids": "",
                    "csrf": csrf
                ]
            )
            actionMessage = L10n.addedToFavorite(folder.title)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func webPlayURL(for page: VideoDetailPage?) -> URL? {
        let bvid = detail?.bvid ?? seedVideo.bvid
        guard !bvid.isEmpty else { return nil }
        let pageIndex = page?.page ?? 1
        return URL(string: "https://www.bilibili.com/video/\(bvid)?p=\(pageIndex)")
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

    private func fetchVideoDetail() async throws -> VideoDetail {
        let data = try await apiClient.requestEnvelopeData(
            path: BiliEndpoint.videoDetail,
            query: ["bvid": seedVideo.bvid]
        )
        return VideoDetail(json: data)
    }

    private func fetchRelatedVideos() async throws -> [VideoSummary] {
        let data = try await apiClient.requestEnvelopeArray(
            path: BiliEndpoint.relatedVideos,
            query: ["bvid": seedVideo.bvid]
        )
        return data.map(VideoSummary.init)
    }
}
