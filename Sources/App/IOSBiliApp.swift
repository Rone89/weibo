import SwiftUI

@main
struct IOSBiliApp: App {
    @StateObject private var appEnvironment = AppEnvironment()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootTabView(appEnvironment: appEnvironment)
                .environmentObject(appEnvironment)
        }
        .onChange(of: scenePhase) { newPhase in
            guard newPhase == .active else { return }
            Task {
                await appEnvironment.syncLoginState()
            }
        }
    }
}
