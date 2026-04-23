import Foundation

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published private(set) var entries: [HistoryEntry] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var canLoadMore = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var actionMessage: String?

    let apiClient: BiliAPIClient
    private let pageSize = 20
    private var nextCursorMax = 0
    private var nextCursorViewAt = 0

    init(apiClient: BiliAPIClient) {
        self.apiClient = apiClient
    }

    func reload() async {
        isLoading = true
        errorMessage = nil
        actionMessage = nil
        nextCursorMax = 0
        nextCursorViewAt = 0

        do {
            let loadedEntries = try await fetchHistory(max: nextCursorMax, viewAt: nextCursorViewAt)
            entries = loadedEntries
            updateCursor(using: loadedEntries)
            canLoadMore = loadedEntries.count >= pageSize
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
            let loadedEntries = try await fetchHistory(max: nextCursorMax, viewAt: nextCursorViewAt)
            let existingIDs = Set(entries.map(\.id))
            entries.append(contentsOf: loadedEntries.filter { !existingIDs.contains($0.id) })
            updateCursor(using: loadedEntries)
            canLoadMore = loadedEntries.count >= pageSize
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func remove(_ entry: HistoryEntry) async {
        guard !isLoading else { return }
        guard !isLoadingMore else { return }

        do {
            let csrf = try await apiClient.requireCSRFToken()
            _ = try await apiClient.postEnvelopeValue(
                path: BiliEndpoint.historyDelete,
                form: [
                    "kid": entry.deleteKey,
                    "jsonp": "jsonp",
                    "csrf": csrf
                ]
            )
            entries.removeAll { $0.id == entry.id }
            actionMessage = L10n.historyRemoved
            canLoadMore = !entries.isEmpty && canLoadMore
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearAll() async {
        guard !isLoading else { return }
        guard !isLoadingMore else { return }

        do {
            let csrf = try await apiClient.requireCSRFToken()
            _ = try await apiClient.postEnvelopeValue(
                path: BiliEndpoint.historyClear,
                form: [
                    "jsonp": "jsonp",
                    "csrf": csrf
                ]
            )
            entries = []
            canLoadMore = false
            nextCursorMax = 0
            nextCursorViewAt = 0
            actionMessage = L10n.historyCleared
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func fetchHistory(max: Int, viewAt: Int) async throws -> [HistoryEntry] {
        let data = try await apiClient.requestEnvelopeData(
            path: BiliEndpoint.historyList,
            query: [
                "type": "archive",
                "ps": "\(pageSize)",
                "max": "\(max)",
                "view_at": "\(viewAt)"
            ]
        )
        return JSONValue.dictionaries(data["list"]).map(HistoryEntry.init)
    }

    private func updateCursor(using loadedEntries: [HistoryEntry]) {
        guard let last = loadedEntries.last else {
            canLoadMore = false
            return
        }
        nextCursorMax = last.cursorMax
        nextCursorViewAt = last.cursorViewAt
    }

}
