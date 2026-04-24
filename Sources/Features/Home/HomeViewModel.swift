import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    enum FeedMode: String, CaseIterable, Identifiable {
        case recommended
        case hot

        var id: String { rawValue }

        var title: String {
            switch self {
            case .recommended:
                return L10n.feedRecommended
            case .hot:
                return L10n.feedHot
            }
        }
    }

    @Published var selectedFeed: FeedMode = .recommended
    @Published private(set) var recommendedVideos: [VideoSummary] = []
    @Published private(set) var hotVideos: [VideoSummary] = []
    @Published private(set) var liveHighlights: [HomeLiveSummary] = []
    @Published private(set) var bangumiHighlights: [HomeBangumiSummary] = []
    @Published private(set) var searchPlaceholder = ""
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMoreRecommended = false
    @Published private(set) var canLoadMoreRecommended = false
    @Published private(set) var isLoadingMoreHot = false
    @Published private(set) var canLoadMoreHot = false
    @Published private(set) var errorMessage: String?

    private let apiClient: BiliAPIClient
    private var hasLoaded = false
    private var nextRecommendedFreshIndex = 0
    private var nextHotPage = 1
    private let recommendedPageSize = 20
    private let hotPageSize = 20

    init(apiClient: BiliAPIClient) {
        self.apiClient = apiClient
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await reload()
    }

    func reload() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        let previousRecommendedIDs = Set(recommendedVideos.map(\.id))
        async let placeholderResult = captureResult { try await self.fetchSearchPlaceholder() }
        async let recommendedResult = captureResult { try await self.fetchInitialRecommendedVideos(avoiding: previousRecommendedIDs) }
        async let hotResult = captureResult { try await self.fetchHotVideos(page: 1) }
        async let liveResult = captureResult { try await self.fetchLiveHighlights() }
        async let bangumiResult = captureResult { try await self.fetchBangumiHighlights() }

        let (placeholderValue, recommendedValue, hotValue, liveValue, bangumiValue) = await (
            placeholderResult,
            recommendedResult,
            hotResult,
            liveResult,
            bangumiResult
        )
        var loadErrors: [String] = []

        switch placeholderValue {
        case .success(let placeholder):
            searchPlaceholder = placeholder
        case .failure:
            if searchPlaceholder.isEmpty {
                searchPlaceholder = L10n.searchPlaceholderDefault
            }
        }

        switch recommendedValue {
        case .success(let loadedRecommendedVideos):
            recommendedVideos = loadedRecommendedVideos
            nextRecommendedFreshIndex = max(1, loadedRecommendedVideos.isEmpty ? 0 : nextRecommendedFreshIndex)
            canLoadMoreRecommended = loadedRecommendedVideos.count >= recommendedPageSize
        case .failure:
            canLoadMoreRecommended = !recommendedVideos.isEmpty
            loadErrors.append(L10n.homeRecommendedLoadFailed)
        }

        switch hotValue {
        case .success(let loadedHotVideos):
            hotVideos = loadedHotVideos
            nextHotPage = 2
            canLoadMoreHot = loadedHotVideos.count >= hotPageSize
        case .failure:
            canLoadMoreHot = !hotVideos.isEmpty
            loadErrors.append(L10n.homeHotLoadFailed)
        }

        if case .success(let loadedLiveHighlights) = liveValue {
            liveHighlights = loadedLiveHighlights
        }

        if case .success(let loadedBangumiHighlights) = bangumiValue {
            bangumiHighlights = loadedBangumiHighlights
        }

        hasLoaded =
            !recommendedVideos.isEmpty ||
            !hotVideos.isEmpty ||
            !liveHighlights.isEmpty ||
            !bangumiHighlights.isEmpty ||
            !searchPlaceholder.isEmpty
        errorMessage = loadErrors.first

        isLoading = false
    }

    func loadMoreRecommendedVideos() async {
        guard !isLoading else { return }
        guard !isLoadingMoreRecommended else { return }
        guard canLoadMoreRecommended else { return }

        isLoadingMoreRecommended = true
        defer { isLoadingMoreRecommended = false }

        do {
            let existingIDs = Set(recommendedVideos.map(\.id))
            var candidateFreshIndex = nextRecommendedFreshIndex
            var lastBatchCount = 0

            for _ in 0..<3 {
                let loadedRecommendedVideos = try await fetchRecommendedVideos(freshIndex: candidateFreshIndex)
                lastBatchCount = loadedRecommendedVideos.count
                candidateFreshIndex += 1

                let uniqueVideos = loadedRecommendedVideos.filter { incoming in
                    !existingIDs.contains(incoming.id)
                }

                if !uniqueVideos.isEmpty || loadedRecommendedVideos.count < recommendedPageSize {
                    recommendedVideos.append(contentsOf: uniqueVideos)
                    nextRecommendedFreshIndex = candidateFreshIndex
                    canLoadMoreRecommended = loadedRecommendedVideos.count >= recommendedPageSize
                    return
                }
            }

            nextRecommendedFreshIndex = candidateFreshIndex
            canLoadMoreRecommended = lastBatchCount >= recommendedPageSize
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMoreHotVideos() async {
        guard !isLoading else { return }
        guard !isLoadingMoreHot else { return }
        guard canLoadMoreHot else { return }

        isLoadingMoreHot = true
        defer { isLoadingMoreHot = false }

        do {
            let loadedHotVideos = try await fetchHotVideos(page: nextHotPage)
            hotVideos.append(contentsOf: loadedHotVideos.filter { incoming in
                !hotVideos.contains(where: { $0.id == incoming.id })
            })
            nextHotPage += 1
            canLoadMoreHot = loadedHotVideos.count >= hotPageSize
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func fetchSearchPlaceholder() async throws -> String {
        let data = try await apiClient.requestEnvelopeData(
            path: BiliEndpoint.searchDefault,
            query: ["web_location": "333.1365"],
            signedByWBI: true
        )
        return JSONValue.string(data["name"]) ?? L10n.searchPlaceholderDefault
    }

    private func fetchInitialRecommendedVideos(avoiding previousIDs: Set<String>) async throws -> [VideoSummary] {
        var candidateFreshIndex = 0
        var lastBatch: [VideoSummary] = []

        for _ in 0..<3 {
            let loadedVideos = try await fetchRecommendedVideos(freshIndex: candidateFreshIndex)
            lastBatch = loadedVideos

            let hasNewContent = previousIDs.isEmpty || loadedVideos.contains { !previousIDs.contains($0.id) }
            if hasNewContent || loadedVideos.count < recommendedPageSize {
                nextRecommendedFreshIndex = candidateFreshIndex + 1
                return loadedVideos
            }

            candidateFreshIndex += 1
        }

        nextRecommendedFreshIndex = candidateFreshIndex
        return lastBatch
    }

    private func fetchRecommendedVideos(freshIndex: Int) async throws -> [VideoSummary] {
        let data = try await apiClient.requestEnvelopeData(
            path: BiliEndpoint.recommendFeed,
            query: [
                "version": "1",
                "feed_version": "V8",
                "homepage_ver": "1",
                "ps": "\(recommendedPageSize)",
                "fresh_idx": "\(freshIndex)",
                "brush": "\(freshIndex)",
                "fresh_type": "4"
            ],
            signedByWBI: true,
            includeCookies: !apiClient.preferencesStore.isGuestRecommendationEnabled
        )

        return JSONValue.dictionaries(data["item"])
            .filter { (JSONValue.string($0["goto"]) ?? "av") == "av" }
            .map(VideoSummary.init)
    }

    private func fetchHotVideos(page: Int) async throws -> [VideoSummary] {
        let data = try await apiClient.requestEnvelopeData(
            path: BiliEndpoint.hotVideos,
            query: [
                "pn": "\(page)",
                "ps": "\(hotPageSize)"
            ],
            headers: [
                "Referer": "\(BiliBaseURL.web)/",
                "Origin": BiliBaseURL.web
            ]
        )
        return JSONValue.dictionaries(data["list"]).map(VideoSummary.init)
    }

    private func fetchLiveHighlights() async throws -> [HomeLiveSummary] {
        let liveParameters: [String: String] = [
            "channel": "master",
            "actionKey": "appkey",
            "build": "8430300",
            "version": "8.43.0",
            "c_locale": "zh_CN",
            "device": "android",
            "device_name": "android",
            "device_type": "0",
            "fnval": "912",
            "disable_rcmd": "0",
            "https_url_req": "1",
            "mobi_app": "android",
            "network": "wifi",
            "page": "1",
            "platform": "android",
            "relation_page": apiClient.sessionStore.hasCookie ? "1" : "",
            "s_locale": "zh_CN",
            "scale": "2",
            "statistics": #"{"appId":1,"platform":3,"version":"8.43.0","abtest":""}"#
        ]
        let filteredParameters = Dictionary(uniqueKeysWithValues: liveParameters.filter { !$0.value.isEmpty })
        let params = BiliAppSigner.sign(filteredParameters)

        let data = try await apiClient.requestEnvelopeData(
            baseURL: BiliBaseURL.live,
            path: BiliEndpoint.liveFeedIndex,
            query: params,
            headers: [
                "env": "prod",
                "app-key": "android",
                "User-Agent": "Mozilla/5.0 BiliDroid/8.43.0 (bbcallen@gmail.com) os/android model/android mobi_app/android build/8430300 channel/master innerVer/8430300 osVer/15 network/2",
                "buvid": "00000000-0000-0000-0000-000000000000",
                "fp_local": "1111111111111111111111111111111111111111111111111111111111111111",
                "fp_remote": "1111111111111111111111111111111111111111111111111111111111111111",
                "session_id": "11111111",
                "x-bili-trace-id": "11111111111111111111111111111111:1111111111111111:0:0",
                "x-bili-aurora-eid": "",
                "x-bili-aurora-zone": "",
                "bili-http-engine": "cronet"
            ],
            includeCookies: false
        )

        let cardList = JSONValue.dictionaries(data["card_list"])
        return cardList
            .filter { JSONValue.string($0["card_type"]) == "small_card_v1" }
            .compactMap { card in
                let cardData = JSONValue.dictionary(card["card_data"])
                let item = JSONValue.dictionary(cardData?["small_card_v1"])
                guard let item else { return nil }
                return HomeLiveSummary(json: item)
            }
            .filter { $0.roomID > 0 }
            .prefix(8)
            .map { $0 }
    }

    private func fetchBangumiHighlights() async throws -> [HomeBangumiSummary] {
        let object = try await apiClient.requestJSON(
            path: BiliEndpoint.pgcRank,
            query: [
                "day": "3",
                "season_type": "1"
            ],
            signedByWBI: true,
            includeCookies: false
        )

        guard let root = object as? [String: Any] else {
            throw APIError.invalidPayload
        }
        let code = JSONValue.int(root["code"]) ?? -1
        guard code == 0 else {
            throw APIError.server(JSONValue.string(root["message"]) ?? L10n.homeBangumiLoadFailed)
        }

        let result = JSONValue.dictionary(root["result"])
        return JSONValue.dictionaries(result?["list"])
            .map(HomeBangumiSummary.init)
            .filter { $0.seasonID > 0 }
            .prefix(8)
            .map { $0 }
    }

    private func captureResult<T>(_ operation: @escaping () async throws -> T) async -> Result<T, Error> {
        do {
            return .success(try await operation())
        } catch {
            return .failure(error)
        }
    }
}
