import AVFoundation
import Foundation
import Observation

@MainActor
@Observable
final class BoutDetailModel {
    private(set) var bout: Bout
    let player: AVQueuePlayer

    private var looper: AVPlayerLooper?
    private var analyticsSession: UUID?
    private let server: FakeLiveServer

    init(bout: Bout, server: FakeLiveServer = .shared) {
        self.bout = bout
        self.server = server
        player = AVQueuePlayer()
    }

    deinit {
        player.pause()
    }

    func start() async {
        startPlayback()
        await followLiveScore()
    }

    private func startPlayback() {
        guard bout.streamId != nil, looper == nil,
              let url = Bundle.main.url(forResource: "bout", withExtension: "mp4") else { return }
        looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
        player.play()
        analyticsSession = PlaybackAnalytics.shared.begin(boutId: bout.id) {
            self.player.currentTime().seconds
        }
    }

    private func followLiveScore() async {
        for await raw in server.connect() {
            guard
                let json = try? JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: Any],
                json["type"] as? String == "update",
                let update = json["update"] as? [String: Any],
                update["boutId"] as? String == bout.id
            else { continue }

            if let red = update["redScore"] as? Int { bout.redScore = red }
            if let blue = update["blueScore"] as? Int { bout.blueScore = blue }
            if let period = update["period"] as? Int { bout.period = period }
            if let status = (update["status"] as? String).flatMap(BoutStatus.init(rawValue:)) { bout.status = status }
        }
    }
}
