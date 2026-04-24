import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var recommendedVideos: [VideoSummary] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isRefreshingRecommended = false
    @Published private(set) var isLoadingMoreRecommended = false
    @Published private(set) var canLoadMoreRecommended = false
    @Published private(set) var errorMessage: String?

    private let apiClient: BiliAPIClient
    private var hasLoaded = false
    private var nextRecommendedFreshIndex = 0
    private let recommendedPageSize = 20

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
        defer { isLoading = false }

        do {
            let loadedVideos = try await fetchRecommendedVideos(freshIndex: 0)
            withAnimation(.linear(duration: 0.12)) {
                recommendedVideos = loadedVideos
            }
            nextRecommendedFreshIndex = 1
            canLoadMoreRecommended = loadedVideos.count >= recommendedPageSize
            hasLoaded = !loadedVideos.isEmpty
        } catch {
            errorMessage = error.localizedDescription
            recommendedVideos = []
            canLoadMoreRecommended = false
        }
    }

    func refreshRecommendedVideos() async {
        guard !isLoading else { return }
        guard !isRefreshingRecommended else { return }

        if recommendedVideos.isEmpty {
            await reload()
            return
        }

        isRefreshingRecommended = true
        errorMessage = nil
        defer { isRefreshingRecommended = false }

        do {
            let existingIDs = Set(recommendedVideos.map(\.id))
            var candidateFreshIndex = nextRecommendedFreshIndex
            var appendedVideos: [VideoSummary] = []
            var pendingIDs = existingIDs

            for _ in 0..<3 {
                let loadedVideos = try await fetchRecommendedVideos(freshIndex: candidateFreshIndex)
                candidateFreshIndex += 1

                let uniqueVideos = loadedVideos.filter { incoming in
                    guard !pendingIDs.contains(incoming.id) else { return false }
                    pendingIDs.insert(incoming.id)
                    return true
                }

                if !uniqueVideos.isEmpty {
                    appendedVideos.append(contentsOf: uniqueVideos)
                }

                if !appendedVideos.isEmpty || loadedVideos.count < recommendedPageSize {
                    break
                }
            }

            nextRecommendedFreshIndex = candidateFreshIndex
            if !appendedVideos.isEmpty {
                withAnimation(.linear(duration: 0.12)) {
                    recommendedVideos = appendedVideos + recommendedVideos
                }
            }
            canLoadMoreRecommended = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMoreRecommendedVideos() async {
        guard !isLoading else { return }
        guard !isRefreshingRecommended else { return }
        guard !isLoadingMoreRecommended else { return }
        guard canLoadMoreRecommended else { return }

        isLoadingMoreRecommended = true
        defer { isLoadingMoreRecommended = false }

        do {
            let existingIDs = Set(recommendedVideos.map(\.id))
            var candidateFreshIndex = nextRecommendedFreshIndex
            var lastBatchCount = 0

            for _ in 0..<3 {
                let loadedVideos = try await fetchRecommendedVideos(freshIndex: candidateFreshIndex)
                lastBatchCount = loadedVideos.count
                candidateFreshIndex += 1

                let uniqueVideos = loadedVideos.filter { incoming in
                    !existingIDs.contains(incoming.id)
                }

                if !uniqueVideos.isEmpty || loadedVideos.count < recommendedPageSize {
                    recommendedVideos.append(contentsOf: uniqueVideos)
                    nextRecommendedFreshIndex = candidateFreshIndex
                    canLoadMoreRecommended = loadedVideos.count >= recommendedPageSize
                    return
                }
            }

            nextRecommendedFreshIndex = candidateFreshIndex
            canLoadMoreRecommended = lastBatchCount >= recommendedPageSize
        } catch {
            errorMessage = error.localizedDescription
        }
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
}
