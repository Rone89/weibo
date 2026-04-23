import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var hasSession: Bool
    @Published private(set) var rawCookie: String
    @Published private(set) var profile: UserProfile?
    @Published private(set) var stat: UserStat?
    @Published private(set) var favoriteFolders: [FavoriteFolder] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMoreFavoriteFolders = false
    @Published private(set) var canLoadMoreFavoriteFolders = false
    @Published private(set) var errorMessage: String?

    let apiClient: BiliAPIClient
    private let sessionStore: SessionStore
    private var hasLoaded = false
    private let favoriteFolderPageSize = 20
    private var nextFavoriteFolderPage = 1
    private var totalFavoriteFolderCount = 0

    var hasLoadedContent: Bool {
        hasLoaded || profile != nil || stat != nil
    }

    init(apiClient: BiliAPIClient, sessionStore: SessionStore) {
        self.apiClient = apiClient
        self.sessionStore = sessionStore
        self.hasSession = sessionStore.hasCookie
        self.rawCookie = sessionStore.rawCookie
    }

    func loadIfNeeded() async {
        if hasSession && !hasLoaded {
            await reload()
        }
    }

    func reload() async {
        syncSessionMirror()
        guard hasSession else {
            clearData(keepSession: true)
            return
        }

        isLoading = true
        errorMessage = nil
        nextFavoriteFolderPage = 1
        totalFavoriteFolderCount = 0

        do {
            async let profile = fetchProfile()
            async let stat = fetchUserStat()
            let loadedProfile = try await profile
            let loadedStat = try await stat
            let (folders, totalCount, hasMore) = try await fetchFavoriteFoldersPage(
                mid: loadedProfile.mid,
                page: nextFavoriteFolderPage
            )

            self.profile = loadedProfile
            self.stat = loadedStat
            self.favoriteFolders = folders
            self.totalFavoriteFolderCount = max(totalCount, folders.count)
            self.nextFavoriteFolderPage = 2
            self.canLoadMoreFavoriteFolders = hasMore || self.favoriteFolders.count < self.totalFavoriteFolderCount
            self.hasLoaded = true
        } catch {
            self.errorMessage = error.localizedDescription
            self.canLoadMoreFavoriteFolders = false
        }

        isLoading = false
    }

    func loadMoreFavoriteFolders() async {
        guard !isLoading else { return }
        guard !isLoadingMoreFavoriteFolders else { return }
        guard canLoadMoreFavoriteFolders else { return }
        guard let mid = profile?.mid, mid > 0 else { return }

        isLoadingMoreFavoriteFolders = true
        defer { isLoadingMoreFavoriteFolders = false }

        do {
            let (folders, totalCount, hasMore) = try await fetchFavoriteFoldersPage(
                mid: mid,
                page: nextFavoriteFolderPage
            )
            let existingIDs = Set(favoriteFolders.map(\.id))
            favoriteFolders.append(contentsOf: folders.filter { !existingIDs.contains($0.id) })
            totalFavoriteFolderCount = max(totalFavoriteFolderCount, totalCount)
            nextFavoriteFolderPage += 1
            canLoadMoreFavoriteFolders = hasMore || favoriteFolders.count < totalFavoriteFolderCount
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveCookie(_ rawCookie: String) async {
        sessionStore.updateCookie(rawCookie)
        syncSessionMirror()
        hasLoaded = false
        await reload()
    }

    func refreshFromCurrentCookieStorage() async {
        sessionStore.refreshFromStorage()
        syncSessionMirror()
        hasLoaded = false
        await reload()
    }

    func clearCookie() {
        sessionStore.clearSession()
        clearData(keepSession: false)
        syncSessionMirror()
    }

    private func syncSessionMirror() {
        hasSession = sessionStore.hasCookie
        rawCookie = sessionStore.rawCookie
    }

    private func clearData(keepSession: Bool) {
        if !keepSession {
            hasLoaded = false
        }
        profile = nil
        stat = nil
        favoriteFolders = []
        nextFavoriteFolderPage = 1
        totalFavoriteFolderCount = 0
        canLoadMoreFavoriteFolders = false
        errorMessage = nil
    }

    private func fetchProfile() async throws -> UserProfile {
        let data = try await apiClient.requestEnvelopeData(path: BiliEndpoint.nav)
        let profile = UserProfile(json: data)
        guard profile.isLogin else {
            throw APIError.server("\u{5f53}\u{524d}\u{5bfc}\u{5165}\u{7684} Cookie \u{5df2}\u{7ecf}\u{4e0d}\u{662f}\u{767b}\u{5f55}\u{72b6}\u{6001}\u{4e86}\u{ff0c}\u{8bf7}\u{91cd}\u{65b0}\u{4ece}\u{6d4f}\u{89c8}\u{5668}\u{590d}\u{5236}\u{6700}\u{65b0} Cookie\u{3002}")
        }
        return profile
    }

    private func fetchUserStat() async throws -> UserStat {
        let data = try await apiClient.requestEnvelopeData(path: BiliEndpoint.navStat)
        return UserStat(json: data)
    }

    private func fetchFavoriteFoldersPage(mid: Int, page: Int) async throws -> ([FavoriteFolder], Int, Bool) {
        let data = try await apiClient.requestEnvelopeData(
            path: BiliEndpoint.userFavoriteFolders,
            query: [
                "up_mid": "\(mid)",
                "pn": "\(page)",
                "ps": "\(favoriteFolderPageSize)"
            ]
        )
        return (
            JSONValue.dictionaries(data["list"]).map(FavoriteFolder.init),
            JSONValue.int(data["count"]) ?? 0,
            JSONValue.bool(data["has_more"]) ?? false
        )
    }
}
