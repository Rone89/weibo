import SwiftUI
import UIKit

@main
struct IOSBiliApp: App {
    @StateObject private var appEnvironment = AppEnvironment()

    init() {
        configureTabBarAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(appEnvironment: appEnvironment)
                .environmentObject(appEnvironment)
        }
    }

    private func configureTabBarAppearance() {
        let accentColor = UIColor(named: "AccentColor") ?? .systemPink
        let backgroundColor = UIColor(red: 0.995, green: 0.985, blue: 0.985, alpha: 0.98)

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = backgroundColor
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.08)

        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.secondaryLabel,
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: accentColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]

        let layouts = [
            appearance.stackedLayoutAppearance,
            appearance.inlineLayoutAppearance,
            appearance.compactInlineLayoutAppearance
        ]

        layouts.forEach { layout in
            layout.normal.iconColor = UIColor.secondaryLabel
            layout.normal.titleTextAttributes = normalAttributes
            layout.selected.iconColor = accentColor
            layout.selected.titleTextAttributes = selectedAttributes
        }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = .secondaryLabel
        UITabBar.appearance().tintColor = accentColor
        UITabBar.appearance().isTranslucent = false
    }
}
