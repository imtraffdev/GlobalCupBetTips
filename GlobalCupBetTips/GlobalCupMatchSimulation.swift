import Foundation

final class GlobalCupMatchSimulation {
    var GlobalCupHomeTeam: GlobalCupTeam
    var GlobalCupAwayTeam: GlobalCupTeam

    init(homeTeam: GlobalCupTeam, awayTeam: GlobalCupTeam) {
        self.GlobalCupHomeTeam = homeTeam
        self.GlobalCupAwayTeam = awayTeam
    }

    func GlobalCupSimulateMatch() -> GlobalCupSimulationResult {
        let homeGoalsCount = GlobalCupGenerateEventCount(maxCount: 7, probabilities: [0.34, 0.27, 0.18, 0.10, 0.06, 0.03, 0.02])
        let awayGoalsCount = GlobalCupGenerateEventCount(maxCount: 7, probabilities: [0.37, 0.28, 0.17, 0.09, 0.05, 0.025, 0.015])
        let homeCorners = GlobalCupGenerateEventCount(maxCount: 12, probabilities: [0.12, 0.12, 0.14, 0.15, 0.14, 0.11, 0.08, 0.06, 0.04, 0.02, 0.01, 0.01])
        let awayCorners = GlobalCupGenerateEventCount(maxCount: 12, probabilities: [0.14, 0.13, 0.14, 0.14, 0.12, 0.10, 0.08, 0.06, 0.04, 0.02, 0.02, 0.01])
        let homeCards = GlobalCupGenerateEventCount(maxCount: 6, probabilities: [0.32, 0.28, 0.20, 0.11, 0.06, 0.03])
        let awayCards = GlobalCupGenerateEventCount(maxCount: 6, probabilities: [0.30, 0.27, 0.21, 0.12, 0.07, 0.03])
        let homeGoals = GlobalCupDistributeEvents(count: homeGoalsCount, players: GlobalCupHomeTeam.players)
        let awayGoals = GlobalCupDistributeEvents(count: awayGoalsCount, players: GlobalCupAwayTeam.players)
        let penaltyAwarded = Double.random(in: 0...1) < 0.18

        return GlobalCupSimulationResult(
            homeGoals: homeGoals,
            awayGoals: awayGoals,
            homeCorners: homeCorners,
            awayCorners: awayCorners,
            homeCards: homeCards,
            awayCards: awayCards,
            penaltyAwarded: penaltyAwarded
        )
    }

    private func GlobalCupGenerateEventCount(maxCount: Int, probabilities: [Double]) -> Int {
        var randomValue = Double.random(in: 0...1)
        for index in 0..<probabilities.count {
            if randomValue <= probabilities[index] {
                return index
            }
            randomValue -= probabilities[index]
        }
        return maxCount
    }

    private func GlobalCupDistributeEvents(count: Int, players: [GlobalCupPlayer]) -> [GlobalCupGoal] {
        guard !players.isEmpty else { return [] }
        return (0..<count)
            .map { _ in GlobalCupGoal(timeInMinute: Int.random(in: 1...90), player: players.randomElement()!) }
            .sorted { $0.timeInMinute < $1.timeInMinute }
    }
}

struct GlobalCupSimulationResult {
    var homeGoals: [GlobalCupGoal]
    var awayGoals: [GlobalCupGoal]
    var homeCorners: Int
    var awayCorners: Int
    var homeCards: Int
    var awayCards: Int
    var penaltyAwarded: Bool
}

struct GlobalCupGoal: Hashable {
    var timeInMinute: Int
    var player: GlobalCupPlayer
}
