import Foundation

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published private(set) var entries: [HistoryEntry] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    let apiClient: BiliAPIClient

    init(apiClient: BiliAPIClient) {
        self.apiClient = apiClient
    }

    func reload() async {
        isLoading = true
        errorMessage = nil

        do {
            let data = try await apiClient.requestEnvelopeData(
                path: BiliEndpoint.historyList,
                query: [
                    "type": "archive",
                    "ps": "20",
                    "max": "0",
                    "view_at": "0"
                ]
            )
            entries = JSONValue.dictionaries(data["list"]).map(HistoryEntry.init)
        } catch {
            errorMessage = error.localizedDescription
            entries = []
        }

        isLoading = false
    }
}
