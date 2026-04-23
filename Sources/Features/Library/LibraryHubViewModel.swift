import Foundation

@MainActor
final class LibraryHubViewModel: ObservableObject {
    @Published private(set) var hasSession: Bool
    @Published private(set) var favoriteFolders: [FavoriteFolder] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    let apiClient: BiliAPIClient
    private let sessionStore: SessionStore
    private var hasLoaded = false

    init(apiClient: BiliAPIClient, sessionStore: SessionStore) {
        self.apiClient = apiClient
        self.sessionStore = sessionStore
        self.hasSession = sessionStore.hasCookie
    }

    func loadIfNeeded() async {
        let latestSessionState = sessionStore.hasCookie
        if latestSessionState != hasSession {
            hasLoaded = false
        }
        hasSession = latestSessionState

        guard !hasLoaded else { return }
        await reload()
    }

    func reload() async {
        hasSession = sessionStore.hasCookie
        errorMessage = nil

        guard hasSession else {
            favoriteFolders = []
            hasLoaded = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let nav = try await apiClient.requestEnvelopeData(path: BiliEndpoint.nav)
            let mid = JSONValue.int(nav["mid"]) ?? 0
            guard mid > 0 else {
                favoriteFolders = []
                hasLoaded = true
                return
            }

            let data = try await apiClient.requestEnvelopeData(
                path: BiliEndpoint.userFavoriteFoldersAll,
                query: ["up_mid": "\(mid)"]
            )
            favoriteFolders = JSONValue.dictionaries(data["list"]).map(FavoriteFolder.init)
            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
            favoriteFolders = []
        }
    }
}
