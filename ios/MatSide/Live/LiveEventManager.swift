import Foundation

/// Shares one live connection between every screen that needs event updates.
/// The connection opens with the first subscriber and closes when the last one leaves.
@MainActor
final class LiveEventManager {
    static let shared = LiveEventManager(server: .shared)

    private let server: FakeLiveServer
    private var subscribers: [UUID: (FeedFrame) -> Void] = [:]
    private var connection: Task<Void, Never>?

    init(server: FakeLiveServer) {
        self.server = server
    }

    func subscribe(_ handler: @escaping (FeedFrame) -> Void) -> UUID {
        let id = UUID()
        subscribers[id] = handler
        if connection == nil {
            open()
        }
        return id
    }

    func unsubscribe(_ id: UUID) {
        subscribers[id] = nil
        if subscribers.isEmpty {
            connection?.cancel()
            connection = nil
        }
    }

    private func open() {
        connection = Task { [weak self, server] in
            let decoder = JSONDecoder()
            for await raw in server.connect() {
                guard let frame = try? decoder.decode(FeedFrame.self, from: Data(raw.utf8)) else { continue }
                self?.broadcast(frame)
            }
        }
    }

    private func broadcast(_ frame: FeedFrame) {
        for handler in subscribers.values {
            handler(frame)
        }
    }
}
