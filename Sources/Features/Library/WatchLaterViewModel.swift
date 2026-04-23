import Foundation

@MainActor
final class WatchLaterViewModel: ObservableObject {
    @Published private(set) var entries: [WatchLaterEntry] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var canLoadMore = false
    @Published private(set) var errorMessage: String?

    let apiClient: BiliAPIClient
    private let pageSize = 20
    private var nextPage = 1
    private var totalCount = 0

    init(apiClient: BiliAPIClient) {
        self.apiClient = apiClient
    }

    func reload() async {
        isLoading = true
        errorMessage = nil
        nextPage = 1
        totalCount = 0

        do {
            let (loadedEntries, count) = try await fetchWatchLater(page: nextPage)
            entries = loadedEntries
            totalCount = count
            nextPage = 2
            canLoadMore = entries.count < totalCount
        } catch {
            errorMessage = error.localizedDescription
            entries = []
            canLoadMore = false
        }

        isLoading = false
    }

    func loadMore() async {
        guard !isLoading else { return }
        guard !isLoadingMore else { return }
        guard canLoadMore else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let (loadedEntries, count) = try await fetchWatchLater(page: nextPage)
            let existingIDs = Set(entries.map(\.id))
            entries.append(contentsOf: loadedEntries.filter { !existingIDs.contains($0.id) })
            totalCount = max(totalCount, count)
            nextPage += 1
            canLoadMore = entries.count < totalCount && !loadedEntries.isEmpty
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func remove(_ entry: WatchLaterEntry) async {
        guard let aid = entry.video.aid else {
            errorMessage = "\u{7f3a}\u{5c11} aid\u{ff0c}\u{6682}\u{65f6}\u{65e0}\u{6cd5}\u{79fb}\u{9664}\u{3002}"
            return
        }

        do {
            let csrf = try await apiClient.requireCSRFToken()
            _ = try await apiClient.postEnvelopeValue(
                path: BiliEndpoint.watchLaterDelete,
                form: [
                    "csrf": csrf,
                    "resources": "\(aid):2"
                ]
            )
            entries.removeAll { $0.id == entry.id }
            totalCount = max(0, totalCount - 1)
            canLoadMore = entries.count < totalCount
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func fetchWatchLater(page: Int) async throws -> ([WatchLaterEntry], Int) {
        let data = try await apiClient.requestEnvelopeData(
            path: BiliEndpoint.watchLaterList,
            query: [
                "pn": "\(page)",
                "ps": "\(pageSize)",
                "viewed": "0",
                "key": "",
                "asc": "false",
                "need_split": "true",
                "web_location": "333.881"
            ],
            signedByWBI: true
        )
        return (
            JSONValue.dictionaries(data["list"]).map(WatchLaterEntry.init),
            JSONValue.int(data["count"]) ?? 0
        )
    }
}
