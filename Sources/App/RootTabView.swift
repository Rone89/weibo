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
            HomeView(apiClient: appEnvironment.apiClient)
            .tabItem {
                Image(systemName: "house")
                Text(L10n.tabHome)
            }
            .tag(RootTab.home)

            SearchView(apiClient: appEnvironment.apiClient)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text(L10n.tabSearch)
                }
                .tag(RootTab.search)

            DynamicView(
                apiClient: appEnvironment.apiClient,
                sessionStore: appEnvironment.sessionStore,
                onTapProfile: { selection = .profile }
            )
            .tabItem {
                Image(systemName: "square.grid.2x2")
                Text(L10n.tabDynamic)
            }
            .tag(RootTab.dynamic)

            NavigationStack {
                HistoryView(apiClient: appEnvironment.apiClient)
            }
                .tabItem {
                    Image(systemName: "clock")
                    Text(L10n.historyTitle)
                }
            .tag(RootTab.history)

            ProfileView(
                apiClient: appEnvironment.apiClient,
                sessionStore: appEnvironment.sessionStore
            )
            .tabItem {
                Image(systemName: "person")
                Text(L10n.tabProfile)
            }
            .tag(RootTab.profile)
        }
        .tint(Color("AccentColor"))
    }
}
