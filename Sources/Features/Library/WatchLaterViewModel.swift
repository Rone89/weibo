import Foundation

@MainActor
final class WatchLaterViewModel: ObservableObject {
    @Published private(set) var entries: [WatchLaterEntry] = []
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
                path: BiliEndpoint.watchLaterList,
                query: [
                    "pn": "1",
                    "ps": "20",
                    "viewed": "0",
                    "key": "",
                    "asc": "false",
                    "need_split": "true",
                    "web_location": "333.881"
                ],
                signedByWBI: true
            )
            entries = JSONValue.dictionaries(data["list"]).map(WatchLaterEntry.init)
        } catch {
            errorMessage = error.localizedDescription
            entries = []
        }

        isLoading = false
    }

    func remove(_ entry: WatchLaterEntry) async {
        guard let aid = entry.video.aid else {
            errorMessage = "\u{7f3a}\u{5c11} aid\u{ff0c}\u{6682}\u{65f6}\u{65e0}\u{6cd5}\u{79fb}\u{9664}\u{3002}"
            return
        }

        do {
            let csrf = try apiClient.requireCSRFToken()
            _ = try await apiClient.postEnvelopeValue(
                path: BiliEndpoint.watchLaterDelete,
                form: [
                    "csrf": csrf,
                    "resources": "\(aid):2"
                ]
            )
            entries.removeAll { $0.id == entry.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
