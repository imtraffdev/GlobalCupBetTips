import Foundation

final class GlobalCupCoefficientCalculator {
    let GlobalCupHomeTeam: GlobalCupTeam
    let GlobalCupAwayTeam: GlobalCupTeam

    init(homeTeam: GlobalCupTeam, awayTeam: GlobalCupTeam) {
        self.GlobalCupHomeTeam = homeTeam
        self.GlobalCupAwayTeam = awayTeam
    }

    func GlobalCupCalculateCoefficients() -> GlobalCupBettingCoefficients {
        let homeStrength = max(GlobalCupHomeTeam.GlobalCupAttackRating, 0.1)
        let awayStrength = max(GlobalCupAwayTeam.GlobalCupAttackRating, 0.1)
        let homeWinProbability = min(max(homeStrength / (homeStrength + awayStrength) * Double.random(in: 0.92...1.08), 0.18), 0.68)
        let awayWinProbability = min(max(awayStrength / (homeStrength + awayStrength) * Double.random(in: 0.92...1.08), 0.18), 0.68)
        let drawProbability = min(max(0.30 - abs(homeStrength - awayStrength) * 0.025, 0.18), 0.34)

        return GlobalCupBettingCoefficients(
            homeWin: GlobalCupOdds(from: homeWinProbability),
            awayWin: GlobalCupOdds(from: awayWinProbability),
            draw: GlobalCupOdds(from: drawProbability),
            firstGoalScorer: GlobalCupFirstScorerOdds(),
            correctScore: GlobalCupCorrectScoreOdds(homeStrength: homeStrength, awayStrength: awayStrength),
            totalCorners: GlobalCupCountOdds(max: 18, lambda: GlobalCupHomeTeam.GlobalCupRiskRating + GlobalCupAwayTeam.GlobalCupRiskRating + 4.0),
            totalCards: GlobalCupCountOdds(max: 10, lambda: GlobalCupHomeTeam.GlobalCupRiskRating + GlobalCupAwayTeam.GlobalCupRiskRating + 1.5),
            firstGoalTime: GlobalCupMinuteOdds(),
            penalty: [true: GlobalCupOdds(from: 0.18), false: GlobalCupOdds(from: 0.82)]
        )
    }

    private func GlobalCupFirstScorerOdds() -> [GlobalCupPlayer: Double] {
        var odds: [GlobalCupPlayer: Double] = [:]
        for player in GlobalCupHomeTeam.players + GlobalCupAwayTeam.players {
            odds[player] = GlobalCupOdds(from: min(max(player.goalProbability * 0.62, 0.03), 0.42))
        }
        return odds
    }

    private func GlobalCupCorrectScoreOdds(homeStrength: Double, awayStrength: Double) -> [String: Double] {
        var odds: [String: Double] = [:]
        let homeLambda = max(0.45, min(2.40, homeStrength / 3.0))
        let awayLambda = max(0.40, min(2.20, awayStrength / 3.2))
        for home in 0...6 {
            for away in 0...6 {
                let probability = GlobalCupPoisson(home, homeLambda) * GlobalCupPoisson(away, awayLambda)
                odds["\(home)-\(away)"] = GlobalCupOdds(from: probability)
            }
        }
        return odds
    }

    private func GlobalCupCountOdds(max: Int, lambda: Double) -> [Int: Double] {
        var odds: [Int: Double] = [:]
        for count in 0...max {
            odds[count] = GlobalCupOdds(from: GlobalCupPoisson(count, lambda))
        }
        return odds
    }

    private func GlobalCupMinuteOdds() -> [Int: Double] {
        var odds: [Int: Double] = [:]
        for minute in 1...90 {
            let earlyBias = minute < 16 ? 0.026 : 0.012
            let probability = max(0.004, earlyBias * exp(-Double(minute) / 90.0))
            odds[minute] = GlobalCupOdds(from: probability)
        }
        return odds
    }

    private func GlobalCupPoisson(_ count: Int, _ lambda: Double) -> Double {
        exp(-lambda) * pow(lambda, Double(count)) / Double(GlobalCupFactorial(count))
    }

    private func GlobalCupFactorial(_ value: Int) -> Int {
        value <= 1 ? 1 : (1...value).reduce(1, *)
    }

    private func GlobalCupOdds(from probability: Double) -> Double {
        guard probability > 0 else { return 100 }
        return min(max(1 / probability, 1.05), 80)
    }
}

struct GlobalCupBettingCoefficients {
    let homeWin: Double
    let awayWin: Double
    let draw: Double
    let firstGoalScorer: [GlobalCupPlayer: Double]
    let correctScore: [String: Double]
    let totalCorners: [Int: Double]
    let totalCards: [Int: Double]
    let firstGoalTime: [Int: Double]
    let penalty: [Bool: Double]
}
