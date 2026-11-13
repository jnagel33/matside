import Foundation

enum BoutStatus: String, Codable {
    case scheduled
    case live
    case final
}

struct LiveEvent: Codable, Equatable {
    let id: String
    let name: String
    var status: BoutStatus
}

struct Bout: Codable, Identifiable, Equatable {
    let id: String
    let mat: Int
    let red: String
    let blue: String
    var redScore: Int
    var blueScore: Int
    var period: Int
    var status: BoutStatus
    var streamId: String?
    var seq: Int?
}

/// A change to one bout pushed by the live feed. Fields that didn't change are omitted.
struct LiveUpdate: Codable, Equatable {
    let seq: Int
    let boutId: String
    var redScore: Int?
    var blueScore: Int?
    var period: Int?
    var status: BoutStatus?
    var streamId: String?
}

extension Bout {
    mutating func apply(_ update: LiveUpdate) {
        redScore = update.redScore ?? redScore
        blueScore = update.blueScore ?? blueScore
        period = update.period ?? period
        status = update.status ?? status
        streamId = update.streamId
        seq = update.seq
    }
}
