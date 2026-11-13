import AVFoundation
import SwiftUI

@main
struct MatSideApp: App {
    @State private var session = UUID()

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback)
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                EventView(onRestart: restart)
            }
            .id(session)
        }
    }

    /// Equivalent to relaunching: the feed restarts at 0:00 and every screen is rebuilt.
    private func restart() {
        LiveEventManager.restart()
        session = UUID()
    }
}
