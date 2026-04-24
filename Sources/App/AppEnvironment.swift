import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    let sessionStore: SessionStore
    let preferencesStore: AppPreferencesStore
    let apiClient: BiliAPIClient

    init() {
        let sessionStore = SessionStore()
        let preferencesStore = AppPreferencesStore()
        self.sessionStore = sessionStore
        self.preferencesStore = preferencesStore
        self.apiClient = BiliAPIClient(sessionStore: sessionStore, preferencesStore: preferencesStore)
    }
}
