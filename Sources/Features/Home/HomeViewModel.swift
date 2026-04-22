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
    @Published private(set) var errorMessage: String?

    private let apiClient: BiliAPIClient
    private var hasLoaded = false

    init(apiClient: BiliAPIClient) {
        self.apiClient = apiClient
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await reload()
    }

    func reload() async {
        isLoading = true
        errorMessage = nil

        do {
            async let placeholder = fetchSearchPlaceholder()
            async let recommended = fetchRecommendedVideos()
            async let hot = fetchHotVideos()

            searchPlaceholder = try await placeholder
            recommendedVideos = try await recommended
            hotVideos = try await hot
            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func fetchSearchPlaceholder() async throws -> String {
        let data = try await apiClient.requestEnvelopeData(
            path: BiliEndpoint.searchDefault,
            query: ["web_location": "333.1365"],
            signedByWBI: true
        )
        return JSONValue.string(data["name"]) ?? L10n.searchPlaceholderDefault
    }

    private func fetchRecommendedVideos() async throws -> [VideoSummary] {
        let data = try await apiClient.requestEnvelopeData(
            path: BiliEndpoint.recommendFeed,
            query: [
                "version": "1",
                "feed_version": "V8",
                "homepage_ver": "1",
                "ps": "20",
                "fresh_idx": "1",
                "brush": "1",
                "fresh_type": "4"
            ],
            signedByWBI: true
        )

        return JSONValue.dictionaries(data["item"])
            .filter { (JSONValue.string($0["goto"]) ?? "av") == "av" }
            .map(VideoSummary.init)
    }

    private func fetchHotVideos() async throws -> [VideoSummary] {
        let data = try await apiClient.requestEnvelopeData(
            path: BiliEndpoint.hotVideos,
            query: [
                "pn": "1",
                "ps": "20"
            ]
        )
        return JSONValue.dictionaries(data["list"]).map(VideoSummary.init)
    }
}
