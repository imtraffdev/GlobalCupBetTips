import Foundation

enum GlobalCupBetType: Hashable {
    case homeWin
    case awayWin
    case draw
    case firstGoalScorer(GlobalCupPlayer)
    case correctScore(Int, Int)
    case totalCorners(Int)
    case totalCards(Int)
    case firstGoalTime(Int)
    case penalty(Bool)
}

final class GlobalCupBettingGame {
    var GlobalCupHomeTeam: GlobalCupTeam
    var GlobalCupAwayTeam: GlobalCupTeam
    var GlobalCupBalance: Double
    var GlobalCupSimulationResult: GlobalCupSimulationResult
    var GlobalCupCoefficients: GlobalCupBettingCoefficients

    private let GlobalCupSimulation: GlobalCupMatchSimulation
    private let GlobalCupCalculator: GlobalCupCoefficientCalculator

    init(homeTeam: GlobalCupTeam, awayTeam: GlobalCupTeam, balance: Double) {
        self.GlobalCupHomeTeam = homeTeam
        self.GlobalCupAwayTeam = awayTeam
        self.GlobalCupBalance = balance
        self.GlobalCupSimulation = GlobalCupMatchSimulation(homeTeam: homeTeam, awayTeam: awayTeam)
        self.GlobalCupCalculator = GlobalCupCoefficientCalculator(homeTeam: homeTeam, awayTeam: awayTeam)
        self.GlobalCupSimulationResult = GlobalCupSimulation.GlobalCupSimulateMatch()
        self.GlobalCupCoefficients = GlobalCupCalculator.GlobalCupCalculateCoefficients()
    }

    func GlobalCupSettle(type: GlobalCupBetType, stake: Double) -> Double {
        let winningReturn: Double
        switch type {
        case .homeWin:
            winningReturn = GlobalCupSimulationResult.homeGoals.count > GlobalCupSimulationResult.awayGoals.count ? stake * GlobalCupCoefficients.homeWin : 0
        case .awayWin:
            winningReturn = GlobalCupSimulationResult.awayGoals.count > GlobalCupSimulationResult.homeGoals.count ? stake * GlobalCupCoefficients.awayWin : 0
        case .draw:
            winningReturn = GlobalCupSimulationResult.homeGoals.count == GlobalCupSimulationResult.awayGoals.count ? stake * GlobalCupCoefficients.draw : 0
        case .firstGoalScorer(let player):
            let firstGoal = (GlobalCupSimulationResult.homeGoals + GlobalCupSimulationResult.awayGoals).sorted { $0.timeInMinute < $1.timeInMinute }.first
            winningReturn = firstGoal?.player == player ? stake * (GlobalCupCoefficients.firstGoalScorer[player] ?? 0) : 0
        case .correctScore(let home, let away):
            winningReturn = GlobalCupSimulationResult.homeGoals.count == home && GlobalCupSimulationResult.awayGoals.count == away ? stake * (GlobalCupCoefficients.correctScore["\(home)-\(away)"] ?? 0) : 0
        case .totalCorners(let total):
            winningReturn = GlobalCupSimulationResult.homeCorners + GlobalCupSimulationResult.awayCorners == total ? stake * (GlobalCupCoefficients.totalCorners[total] ?? 0) : 0
        case .totalCards(let total):
            winningReturn = GlobalCupSimulationResult.homeCards + GlobalCupSimulationResult.awayCards == total ? stake * (GlobalCupCoefficients.totalCards[total] ?? 0) : 0
        case .firstGoalTime(let minute):
            let firstGoal = (GlobalCupSimulationResult.homeGoals + GlobalCupSimulationResult.awayGoals).sorted { $0.timeInMinute < $1.timeInMinute }.first
            winningReturn = firstGoal?.timeInMinute == minute ? stake * (GlobalCupCoefficients.firstGoalTime[minute] ?? 0) : 0
        case .penalty(let expected):
            winningReturn = GlobalCupSimulationResult.penaltyAwarded == expected ? stake * (GlobalCupCoefficients.penalty[expected] ?? 0) : 0
        }

        let profit = winningReturn - stake
        GlobalCupBalance += profit
        return profit
    }
}
