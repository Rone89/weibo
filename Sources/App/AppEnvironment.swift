import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    let sessionStore: SessionStore
    let apiClient: BiliAPIClient
    private var hasPreparedLaunchState = false

    init() {
        let sessionStore = SessionStore()
        self.sessionStore = sessionStore
        self.apiClient = BiliAPIClient(sessionStore: sessionStore)
    }

    func prepareForLaunch() async {
        guard !hasPreparedLaunchState else { return }
        hasPreparedLaunchState = true

        sessionStore.restorePersistedCookieIfNeeded()
        await sessionStore.mergeCookieStateFromStores()
    }

    func syncLoginState() async {
        sessionStore.restorePersistedCookieIfNeeded()
        await sessionStore.mergeCookieStateFromStores()
    }
}
