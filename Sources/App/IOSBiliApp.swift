import SwiftUI

@main
struct IOSBiliApp: App {
    @StateObject private var appEnvironment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootTabView(appEnvironment: appEnvironment)
                .environmentObject(appEnvironment)
        }
    }
}
