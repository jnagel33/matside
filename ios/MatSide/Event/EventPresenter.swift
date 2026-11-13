import Foundation
import Observation

@MainActor
@Observable
final class EventPresenter {
    private(set) var event: LiveEvent?
    private(set) var bouts: [Bout] = []
    private(set) var isLoading = true

    private let repository: EventRepository
    private let liveEvents: LiveEventManager
    private var subscription: UUID?
    private var hasLoaded = false

    init(repository: EventRepository = EventRepository(), liveEvents: LiveEventManager? = nil) {
        self.repository = repository
        self.liveEvents = liveEvents ?? .shared
    }

    func onAppear() async {
        guard !hasLoaded else { return }
        hasLoaded = true

        let (event, bouts) = await repository.loadEvent()
        self.event = event
        self.bouts = bouts
        isLoading = false

        subscription = liveEvents.subscribe { [weak self] frame in
            self?.handle(frame)
        }
    }

    func onDisappear() {
        if let subscription {
            liveEvents.unsubscribe(subscription)
            self.subscription = nil
        }
    }

    private func handle(_ frame: FeedFrame) {
        switch frame {
        case let .snapshot(_, bouts):
            self.bouts = bouts
        case let .update(update):
            guard let index = bouts.firstIndex(where: { $0.id == update.boutId }) else { return }
            bouts[index].apply(update)
        }
    }
}
