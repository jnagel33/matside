import SwiftUI

struct EventView: View {
    @State private var presenter = EventPresenter()

    var body: some View {
        Group {
            if presenter.isLoading {
                ProgressView()
            } else {
                List(presenter.bouts) { bout in
                    NavigationLink(value: bout) {
                        BoutRow(bout: bout)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(presenter.event?.name ?? "Live")
        .navigationDestination(for: Bout.self) { bout in
            BoutDetailView(bout: bout)
        }
        .task { await presenter.onAppear() }
        .onDisappear { presenter.onDisappear() }
    }
}

struct BoutRow: View {
    let bout: Bout

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Mat \(bout.mat)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(bout.red).foregroundStyle(.red)
                Text(bout.blue).foregroundStyle(.blue)
            }
            Spacer()
            if bout.streamId != nil {
                Label("Watch", systemImage: "play.fill")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.tint.opacity(0.15), in: Capsule())
            }
            VStack(alignment: .trailing, spacing: 4) {
                StatusBadge(status: bout.status, period: bout.period)
                Text("\(bout.redScore) – \(bout.blueScore)")
                    .font(.title3.monospacedDigit().bold())
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: BoutStatus
    let period: Int

    var body: some View {
        Text(label)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2), in: Capsule())
            .foregroundStyle(color)
    }

    private var label: String {
        switch status {
        case .scheduled: "UP NEXT"
        case .live: "LIVE · P\(period)"
        case .final: "FINAL"
        }
    }

    private var color: Color {
        switch status {
        case .scheduled: .gray
        case .live: .green
        case .final: .primary
        }
    }
}

extension Bout: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
