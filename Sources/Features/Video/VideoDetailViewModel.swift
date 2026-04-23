import Foundation

@MainActor
final class VideoDetailViewModel: ObservableObject {
    @Published private(set) var detail: VideoDetail?
    @Published private(set) var relatedVideos: [VideoSummary] = []
    @Published private(set) var remoteResumeSeconds: TimeInterval?
    @Published private(set) var remoteResumeCID: Int?
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
        remoteResumeSeconds = nil
        remoteResumeCID = nil

        do {
            async let detail = fetchVideoDetail()
            async let related = fetchRelatedVideos()
            let loadedDetail = try await detail
            self.detail = loadedDetail
            self.relatedVideos = try await related
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

    private func hydrateRemoteResume(detail: VideoDetail) async throws {
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
            signedByWBI: true
        )

        let lastPlayTime = JSONValue.double(data["last_play_time"]) ?? 0
        let lastPlayCID = JSONValue.int(data["last_play_cid"]) ?? 0
        guard lastPlayTime > 5, lastPlayCID > 0 else { return }

        remoteResumeSeconds = lastPlayTime
        remoteResumeCID = lastPlayCID
    }
}
