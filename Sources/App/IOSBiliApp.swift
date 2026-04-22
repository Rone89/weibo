import SwiftUI

@main
struct IOSBiliApp: App {
    @StateObject private var appEnvironment = AppEnvironment()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootTabView(appEnvironment: appEnvironment)
                .environmentObject(appEnvironment)
                .task {
                    await appEnvironment.prepareForLaunch()
                }
        }
        .onChange(of: scenePhase) { newPhase in
            guard newPhase == .active else { return }
            Task {
                await appEnvironment.syncLoginState()
            }
        }
    }
}
