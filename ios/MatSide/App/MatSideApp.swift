import AVFoundation
import SwiftUI

@main
struct MatSideApp: App {
    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback)
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                EventView()
            }
        }
    }
}
