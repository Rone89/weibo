import SwiftUI

struct RootTabView: View {
    enum RootTab: Hashable {
        case home
        case search
        case dynamic
        case history
        case profile
    }

    @ObservedObject var appEnvironment: AppEnvironment
    @State private var selection: RootTab = .home

    var body: some View {
        TabView(selection: $selection) {
            HomeView(
                apiClient: appEnvironment.apiClient,
                onTapSearch: { selection = .search },
                onTapDynamic: { selection = .dynamic },
                onTapHistory: { selection = .history },
                onTapProfile: { selection = .profile }
            )
            .tabItem {
                Label(L10n.tabHome, systemImage: "house.fill")
            }
            .tag(RootTab.home)

            SearchView(apiClient: appEnvironment.apiClient)
                .tabItem {
                    Label(L10n.tabSearch, systemImage: "magnifyingglass")
                }
                .tag(RootTab.search)

            DynamicView(
                apiClient: appEnvironment.apiClient,
                sessionStore: appEnvironment.sessionStore,
                onTapProfile: { selection = .profile }
            )
            .tabItem {
                Label(L10n.tabDynamic, systemImage: "bubble.left.and.bubble.right.fill")
            }
            .tag(RootTab.dynamic)

            NavigationStack {
                HistoryView(apiClient: appEnvironment.apiClient)
            }
                .tabItem {
                    Label(L10n.historyTitle, systemImage: "clock.arrow.circlepath")
                }
            .tag(RootTab.history)

            ProfileView(
                apiClient: appEnvironment.apiClient,
                sessionStore: appEnvironment.sessionStore
            )
            .tabItem {
                Label(L10n.tabProfile, systemImage: "person.crop.circle.fill")
            }
            .tag(RootTab.profile)
        }
        .tint(Color("AccentColor"))
    }
}
