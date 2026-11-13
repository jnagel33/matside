import Foundation

/// Reports a playback heartbeat every few seconds while a session is open.
@MainActor
final class PlaybackAnalytics {
    static let shared = PlaybackAnalytics()

    private struct Session {
        let boutId: String
        let position: () -> Double
    }

    private var sessions: [UUID: Session] = [:]
    private var timer: Timer?

    func begin(boutId: String, position: @escaping () -> Double) -> UUID {
        let id = UUID()
        sessions[id] = Session(boutId: boutId, position: position)
        startTimerIfNeeded()
        return id
    }

    func end(_ id: UUID) {
        sessions[id] = nil
    }

    private func startTimerIfNeeded() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.sendHeartbeats() }
        }
    }

    private func sendHeartbeats() {
        for session in sessions.values {
            print("[analytics] heartbeat bout=\(session.boutId) position=\(Int(session.position()))s")
        }
    }
}
