import AVKit
import SwiftUI

struct BoutDetailView: View {
    @State private var model: BoutDetailModel

    init(bout: Bout) {
        _model = State(initialValue: BoutDetailModel(bout: bout))
    }

    var body: some View {
        VStack(spacing: 24) {
            if model.bout.streamId != nil {
                VideoPlayer(player: model.player)
                    .aspectRatio(16 / 9, contentMode: .fit)
            } else {
                ContentUnavailableView("No stream for this mat", systemImage: "tv.slash")
                    .frame(height: 200)
            }

            HStack {
                scoreColumn(name: model.bout.red, score: model.bout.redScore, color: .red)
                Spacer()
                StatusBadge(status: model.bout.status, period: model.bout.period)
                Spacer()
                scoreColumn(name: model.bout.blue, score: model.bout.blueScore, color: .blue)
            }
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("Mat \(model.bout.mat)")
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.start() }
    }

    private func scoreColumn(name: String, score: Int, color: Color) -> some View {
        VStack(spacing: 8) {
            Text("\(score)")
                .font(.system(size: 56, weight: .bold).monospacedDigit())
                .foregroundStyle(color)
            Text(name)
                .font(.headline)
        }
    }
}
