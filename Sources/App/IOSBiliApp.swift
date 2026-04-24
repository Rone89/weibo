import SwiftUI
import UIKit

@main
struct IOSBiliApp: App {
    @StateObject private var appEnvironment = AppEnvironment()

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.96)
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.06)

        let normalColor = UIColor.label.withAlphaComponent(0.78)
        let selectedColor = UIColor(named: "AccentColor") ?? .systemPink
        let layouts = [
            appearance.stackedLayoutAppearance,
            appearance.inlineLayoutAppearance,
            appearance.compactInlineLayoutAppearance
        ]

        for layout in layouts {
            layout.normal.iconColor = normalColor
            layout.normal.titleTextAttributes = [.foregroundColor: normalColor]
            layout.selected.iconColor = selectedColor
            layout.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = normalColor
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(appEnvironment: appEnvironment)
                .environmentObject(appEnvironment)
        }
    }
}
