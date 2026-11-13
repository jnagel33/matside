import Foundation

/// Stands in for the realtime backend. Replays `feed.json` on a loop, timed from app launch,
/// so every connection sees the same timeline. Nothing here touches the network.
final class FakeLiveServer: @unchecked Sendable {
    private(set) static var shared = FakeLiveServer(script: .bundled())

    /// Starts a fresh server whose timeline begins now.
    static func restart() {
        shared = FakeLiveServer(script: shared.script)
    }

    let script: FeedScript
    private let startDate = Date()

    init(script: FeedScript) {
        self.script = script
    }

    /// Opens a connection that yields raw JSON frames, like a WebSocket would.
    func connect() -> AsyncStream<String> {
        AsyncStream { continuation in
            let task = Task {
                await self.replay(into: continuation)
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func replay(into continuation: AsyncStream<String>.Continuation) async {
        let loop = script.loopSeconds
        var elapsed = Date().timeIntervalSince(startDate)
        var loopIndex = Int(elapsed / loop)

        while !Task.isCancelled {
            let loopStart = Double(loopIndex) * loop
            if loopIndex > 0, elapsed - loopStart < 1 {
                continuation.yield(Self.encode(.snapshot(seq: loopIndex * 100, bouts: script.bouts)))
            }
            for frame in script.frames where loopStart + frame.at > elapsed {
                let wait = loopStart + frame.at - Date().timeIntervalSince(startDate)
                if wait > 0 {
                    try? await Task.sleep(for: .seconds(wait))
                }
                if Task.isCancelled { return }
                var update = frame.update
                update = LiveUpdate(
                    seq: loopIndex * 100 + update.seq,
                    boutId: update.boutId,
                    redScore: update.redScore,
                    blueScore: update.blueScore,
                    period: update.period,
                    status: update.status,
                    streamId: update.streamId
                )
                continuation.yield(Self.encode(.update(update)))
            }
            loopIndex += 1
            let nextLoop = Double(loopIndex) * loop - Date().timeIntervalSince(startDate)
            if nextLoop > 0 {
                try? await Task.sleep(for: .seconds(nextLoop))
            }
            elapsed = Date().timeIntervalSince(startDate)
        }
        continuation.finish()
    }

    private static func encode(_ frame: FeedFrame) -> String {
        let data = (try? JSONEncoder().encode(frame)) ?? Data()
        return String(decoding: data, as: UTF8.self)
    }
}

/// The wire format of a frame on the live connection.
enum FeedFrame: Codable {
    case snapshot(seq: Int, bouts: [Bout])
    case update(LiveUpdate)

    private enum CodingKeys: String, CodingKey { case type, seq, bouts, update }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(String.self, forKey: .type) {
        case "snapshot":
            self = .snapshot(
                seq: try container.decode(Int.self, forKey: .seq),
                bouts: try container.decode([Bout].self, forKey: .bouts)
            )
        default:
            self = .update(try container.decode(LiveUpdate.self, forKey: .update))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .snapshot(seq, bouts):
            try container.encode("snapshot", forKey: .type)
            try container.encode(seq, forKey: .seq)
            try container.encode(bouts, forKey: .bouts)
        case let .update(update):
            try container.encode("update", forKey: .type)
            try container.encode(update, forKey: .update)
        }
    }
}

struct FeedScript: Decodable {
    struct Frame: Decodable {
        let at: Double
        let update: LiveUpdate
    }

    let event: LiveEvent
    let bouts: [Bout]
    let loopSeconds: Double
    let frames: [Frame]

    static func bundled() -> FeedScript {
        guard
            let url = Bundle.main.url(forResource: "feed", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let script = try? JSONDecoder().decode(FeedScript.self, from: data)
        else {
            fatalError("feed.json is missing or invalid")
        }
        return script
    }
}
