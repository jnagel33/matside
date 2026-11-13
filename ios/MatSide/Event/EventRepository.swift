import Foundation

/// Loads the event and its bouts. Backed by the bundled script; the delay stands in for a request.
struct EventRepository {
    var server: FakeLiveServer = .shared

    func loadEvent() async -> (LiveEvent, [Bout]) {
        try? await Task.sleep(for: .milliseconds(400))
        return (server.script.event, server.script.bouts)
    }
}
