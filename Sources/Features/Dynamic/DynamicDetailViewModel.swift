import Foundation

@MainActor
final class DynamicDetailViewModel: ObservableObject {
    @Published private(set) var detailItem: DynamicFeedItem?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    let apiClient: BiliAPIClient
    let seedItem: DynamicFeedItem
    private var hasLoaded = false

    init(apiClient: BiliAPIClient, seedItem: DynamicFeedItem) {
        self.apiClient = apiClient
        self.seedItem = seedItem
        self.detailItem = seedItem
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await reload()
    }

    func reload() async {
        guard !seedItem.id.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let data = try await apiClient.requestEnvelopeData(
                path: BiliEndpoint.dynamicDetail,
                query: [
                    "id": seedItem.id,
                    "timezone_offset": "-480",
                    "features": "itemOpusStyle",
                    "web_location": "333.1330"
                ]
            )
            let itemJSON = JSONValue.dictionary(data["item"]) ?? data
            detailItem = DynamicFeedItem(json: itemJSON)
            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
            detailItem = seedItem
        }
    }
}
