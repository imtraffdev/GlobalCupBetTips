import SwiftUI

struct GlobalCupTeam: Hashable, Identifiable {
    var id: String { name }
    var name: String
    var players: [GlobalCupPlayer]

    var GlobalCupAttackRating: Double {
        players.reduce(0) { $0 + $1.goalProbability }
    }

    var GlobalCupRiskRating: Double {
        players.reduce(0) { $0 + $1.faultProbability }
    }

    var GlobalCupFlagAssetName: String {
        name.uppercased().replacingOccurrences(of: " ", with: "")
    }

    var GlobalCupFlag: Image {
        Image(GlobalCupFlagAssetName)
    }
}

enum GlobalCupTeamRepository {
    static var GlobalCupAllTeams: [GlobalCupTeam] {
        GlobalCupDataModule.GlobalCupTeams
    }

    static func GlobalCupRandomPair() -> (GlobalCupTeam, GlobalCupTeam) {
        var teams = GlobalCupAllTeams
        guard teams.count >= 2 else {
            let fallback = GlobalCupDataModule.GlobalCupTeams
            return (fallback[0], fallback[1])
        }
        let first = teams.remove(at: Int.random(in: 0..<teams.count))
        let second = teams[Int.random(in: 0..<teams.count)]
        return (first, second)
    }
}
