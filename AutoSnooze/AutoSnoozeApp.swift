import SwiftUI
import UIKit

@main
struct AutoSnoozeApp: App {
    @State private var store = AlarmStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { _, phase in
            // Bedside clock: never let the screen sleep while we're frontmost.
            if phase == .active {
                UIApplication.shared.isIdleTimerDisabled = true
            }
        }
    }
}
