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

        do {
            let previousRecommendedIDs = Set(recommendedVideos.map(\.id))
            async let placeholder = fetchSearchPlaceholder()
            async let recommended = fetchInitialRecommendedVideos(avoiding: previousRecommendedIDs)
            async let hot = fetchHotVideos(page: 1)

            searchPlaceholder = try await placeholder
            let loadedRecommendedVideos = try await recommended
            recommendedVideos = loadedRecommendedVideos
            nextRecommendedFreshIndex = max(1, loadedRecommendedVideos.isEmpty ? 0 : nextRecommendedFreshIndex)
            canLoadMoreRecommended = loadedRecommendedVideos.count >= recommendedPageSize
            let loadedHotVideos = try await hot
            hotVideos = loadedHotVideos
            nextHotPage = 2
            canLoadMoreHot = loadedHotVideos.count >= hotPageSize
            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
        }

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
            signedByWBI: true
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
            ]
        )
        return JSONValue.dictionaries(data["list"]).map(VideoSummary.init)
    }
}
