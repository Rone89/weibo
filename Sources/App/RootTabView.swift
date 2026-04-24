import SwiftUI

struct RootTabView: View {
    enum RootTab: Hashable {
        case home
        case search
        case dynamic
        case profile
    }

    @ObservedObject var appEnvironment: AppEnvironment
    @State private var selection: RootTab = .home

    var body: some View {
        TabView(selection: $selection) {
            HomeView(apiClient: appEnvironment.apiClient)
                .tabItem {
                    Label(L10n.tabHome, systemImage: selection == .home ? "house.fill" : "house")
                }
            .tag(RootTab.home)

            SearchView(apiClient: appEnvironment.apiClient)
                .tabItem {
                    Label(L10n.tabSearch, systemImage: selection == .search ? "magnifyingglass.circle.fill" : "magnifyingglass")
                }
                .tag(RootTab.search)

            DynamicView(
                apiClient: appEnvironment.apiClient,
                sessionStore: appEnvironment.sessionStore,
                onTapProfile: { selection = .profile }
            )
            .tabItem {
                Label(L10n.tabDynamic, systemImage: selection == .dynamic ? "square.grid.2x2.fill" : "square.grid.2x2")
            }
            .tag(RootTab.dynamic)

            ProfileView(
                apiClient: appEnvironment.apiClient,
                sessionStore: appEnvironment.sessionStore
            )
            .tabItem {
                Label(L10n.tabProfile, systemImage: selection == .profile ? "person.fill" : "person")
            }
            .tag(RootTab.profile)
        }
        .tint(Color("AccentColor"))
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(Color(.systemBackground).opacity(0.96), for: .tabBar)
    }
}
