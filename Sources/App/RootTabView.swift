import SwiftUI

struct RootTabView: View {
    enum RootTab: Hashable {
        case home
        case search
        case profile
    }

    @ObservedObject var appEnvironment: AppEnvironment
    @State private var selection: RootTab = .home

    var body: some View {
        TabView(selection: $selection) {
            HomeView(apiClient: appEnvironment.apiClient) {
                selection = .search
            }
            .tabItem {
                Label(L10n.tabHome, systemImage: "house.fill")
            }
            .tag(RootTab.home)

            SearchView(apiClient: appEnvironment.apiClient)
                .tabItem {
                    Label(L10n.tabSearch, systemImage: "magnifyingglass")
                }
                .tag(RootTab.search)

            ProfileView(
                apiClient: appEnvironment.apiClient,
                sessionStore: appEnvironment.sessionStore
            )
            .tabItem {
                Label(L10n.tabProfile, systemImage: "person.crop.circle")
            }
            .tag(RootTab.profile)
        }
        .tint(Color("AccentColor"))
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(Color(.systemBackground), for: .tabBar)
        .toolbarColorScheme(.light, for: .tabBar)
    }
}
