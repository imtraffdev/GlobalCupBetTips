import SwiftUI

final class GlobalCupBettingViewModel: ObservableObject {
    enum GlobalCupMarket: String, CaseIterable, Identifiable {
        case matchWinner = "Match Winner"
        case draw = "Draw"
        case firstScorer = "First Scorer"
        case correctScore = "Correct Score"
        case corners = "Total Corners"
        case cards = "Total Cards"
        case firstGoalTime = "First Goal Time"
        case penalty = "Penalty Awarded"

        var id: String { rawValue }
    }

    @Published var GlobalCupHomeTeam: GlobalCupTeam
    @Published var GlobalCupAwayTeam: GlobalCupTeam
    @Published var GlobalCupGame: GlobalCupBettingGame
    @Published var GlobalCupMarketSelection: GlobalCupMarket = .matchWinner
    @Published var GlobalCupSelectedTeam: GlobalCupTeam?
    @Published var GlobalCupSelectedPlayer: GlobalCupPlayer?
    @Published var GlobalCupHomeScore = 1
    @Published var GlobalCupAwayScore = 1
    @Published var GlobalCupCorners = 8
    @Published var GlobalCupCards = 4
    @Published var GlobalCupFirstGoalMinute = 18
    @Published var GlobalCupPenaltyExpected = false
    @Published var GlobalCupLastProfit: Double?

    init() {
        let pair = GlobalCupTeamRepository.GlobalCupRandomPair()
        GlobalCupHomeTeam = pair.0
        GlobalCupAwayTeam = pair.1
        GlobalCupGame = GlobalCupBettingGame(homeTeam: pair.0, awayTeam: pair.1, balance: 100_000)
    }

    func GlobalCupNewMatch(keepBalance: Bool = true) {
        let balance = keepBalance ? GlobalCupGame.GlobalCupBalance : 100_000
        let pair = GlobalCupTeamRepository.GlobalCupRandomPair()
        GlobalCupHomeTeam = pair.0
        GlobalCupAwayTeam = pair.1
        GlobalCupGame = GlobalCupBettingGame(homeTeam: pair.0, awayTeam: pair.1, balance: balance)
        GlobalCupSelectedTeam = nil
        GlobalCupSelectedPlayer = nil
        GlobalCupLastProfit = nil
    }

    func GlobalCupBetType() -> GlobalCupBetType? {
        switch GlobalCupMarketSelection {
        case .matchWinner:
            guard let team = GlobalCupSelectedTeam else { return nil }
            return team == GlobalCupHomeTeam ? .homeWin : .awayWin
        case .draw:
            return .draw
        case .firstScorer:
            guard let player = GlobalCupSelectedPlayer else { return nil }
            return .firstGoalScorer(player)
        case .correctScore:
            return .correctScore(GlobalCupHomeScore, GlobalCupAwayScore)
        case .corners:
            return .totalCorners(GlobalCupCorners)
        case .cards:
            return .totalCards(GlobalCupCards)
        case .firstGoalTime:
            return .firstGoalTime(GlobalCupFirstGoalMinute)
        case .penalty:
            return .penalty(GlobalCupPenaltyExpected)
        }
    }

    func GlobalCupCurrentOdds() -> Double {
        switch GlobalCupMarketSelection {
        case .matchWinner:
            guard let team = GlobalCupSelectedTeam else { return 0 }
            return team == GlobalCupHomeTeam ? GlobalCupGame.GlobalCupCoefficients.homeWin : GlobalCupGame.GlobalCupCoefficients.awayWin
        case .draw:
            return GlobalCupGame.GlobalCupCoefficients.draw
        case .firstScorer:
            guard let player = GlobalCupSelectedPlayer else { return 0 }
            return GlobalCupGame.GlobalCupCoefficients.firstGoalScorer[player] ?? 0
        case .correctScore:
            return GlobalCupGame.GlobalCupCoefficients.correctScore["\(GlobalCupHomeScore)-\(GlobalCupAwayScore)"] ?? 0
        case .corners:
            return GlobalCupGame.GlobalCupCoefficients.totalCorners[GlobalCupCorners] ?? 0
        case .cards:
            return GlobalCupGame.GlobalCupCoefficients.totalCards[GlobalCupCards] ?? 0
        case .firstGoalTime:
            return GlobalCupGame.GlobalCupCoefficients.firstGoalTime[GlobalCupFirstGoalMinute] ?? 0
        case .penalty:
            return GlobalCupGame.GlobalCupCoefficients.penalty[GlobalCupPenaltyExpected] ?? 0
        }
    }
}

struct BettingView: View {
    @StateObject private var GlobalCupVM = GlobalCupBettingViewModel()
    @State private var GlobalCupStake: Double = 1_000
    @State private var GlobalCupShowsResult = false
    @State private var GlobalCupAlert = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GlobalCupMatchHeader(vm: GlobalCupVM)

                if GlobalCupShowsResult {
                    GlobalCupResultPanel(vm: GlobalCupVM) {
                        GlobalCupVM.GlobalCupNewMatch()
                        GlobalCupShowsResult = false
                    }
                } else {
                    GlobalCupMarketBuilder
                    GlobalCupStakePanel
                    Button("Run Simulation") {
                        GlobalCupPlacePracticeBet()
                    }
                    .buttonStyle(GlobalCupPrimaryButtonStyle())
                }
            }
            .padding(18)
        }
        .scrollIndicators(.hidden)
        .alert("Selection Needed", isPresented: .constant(!GlobalCupAlert.isEmpty)) {
            Button("OK") { GlobalCupAlert = "" }
        } message: {
            Text(GlobalCupAlert)
        }
        .onChange(of: GlobalCupVM.GlobalCupMarketSelection) { _ in
            GlobalCupVM.GlobalCupSelectedTeam = nil
            GlobalCupVM.GlobalCupSelectedPlayer = nil
        }
        .onChange(of: GlobalCupVM.GlobalCupSelectedTeam) { _ in
            GlobalCupVM.GlobalCupSelectedPlayer = nil
        }
    }

    private var GlobalCupMarketBuilder: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Market Builder")
                .font(.system(size: 22, weight: .black))

            Picker("Market", selection: $GlobalCupVM.GlobalCupMarketSelection) {
                ForEach(GlobalCupBettingViewModel.GlobalCupMarket.allCases) { market in
                    Text(market.rawValue).tag(market)
                }
            }
            .pickerStyle(.menu)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

            GlobalCupMarketControls

            HStack {
                Text("Estimated odds")
                    .foregroundStyle(GlobalCupTheme.GlobalCupMuted)
                Spacer()
                Text(GlobalCupVM.GlobalCupCurrentOdds() == 0 ? "--" : String(format: "%.2f", GlobalCupVM.GlobalCupCurrentOdds()))
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(GlobalCupTheme.GlobalCupGreen)
            }
        }
        .padding(16)
        .GlobalCupPanel()
    }

    @ViewBuilder
    private var GlobalCupMarketControls: some View {
        switch GlobalCupVM.GlobalCupMarketSelection {
        case .matchWinner:
            Picker("Team", selection: $GlobalCupVM.GlobalCupSelectedTeam) {
                Text("Choose").tag(nil as GlobalCupTeam?)
                Text(GlobalCupVM.GlobalCupHomeTeam.name).tag(GlobalCupVM.GlobalCupHomeTeam as GlobalCupTeam?)
                Text(GlobalCupVM.GlobalCupAwayTeam.name).tag(GlobalCupVM.GlobalCupAwayTeam as GlobalCupTeam?)
            }
            .pickerStyle(.segmented)
        case .draw:
            GlobalCupInfoRow(text: "Draw selected. The simulator will compare the final scoreline.")
        case .firstScorer:
            Picker("Team", selection: $GlobalCupVM.GlobalCupSelectedTeam) {
                Text("Choose").tag(nil as GlobalCupTeam?)
                Text(GlobalCupVM.GlobalCupHomeTeam.name).tag(GlobalCupVM.GlobalCupHomeTeam as GlobalCupTeam?)
                Text(GlobalCupVM.GlobalCupAwayTeam.name).tag(GlobalCupVM.GlobalCupAwayTeam as GlobalCupTeam?)
            }
            .pickerStyle(.segmented)
            if let team = GlobalCupVM.GlobalCupSelectedTeam {
                Picker("Player", selection: $GlobalCupVM.GlobalCupSelectedPlayer) {
                    Text("Choose player").tag(nil as GlobalCupPlayer?)
                    ForEach(team.players) { player in
                        Text(player.name).tag(player as GlobalCupPlayer?)
                    }
                }
                .pickerStyle(.menu)
                .padding(12)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            }
        case .correctScore:
            HStack {
                GlobalCupStepper(label: GlobalCupVM.GlobalCupHomeTeam.name, value: $GlobalCupVM.GlobalCupHomeScore, range: 0...6)
                GlobalCupStepper(label: GlobalCupVM.GlobalCupAwayTeam.name, value: $GlobalCupVM.GlobalCupAwayScore, range: 0...6)
            }
        case .corners:
            GlobalCupStepper(label: "Corners", value: $GlobalCupVM.GlobalCupCorners, range: 0...18)
        case .cards:
            GlobalCupStepper(label: "Cards", value: $GlobalCupVM.GlobalCupCards, range: 0...10)
        case .firstGoalTime:
            GlobalCupStepper(label: "Minute", value: $GlobalCupVM.GlobalCupFirstGoalMinute, range: 1...90)
        case .penalty:
            Toggle("Penalty awarded", isOn: $GlobalCupVM.GlobalCupPenaltyExpected)
                .font(.system(size: 15, weight: .black))
        }
    }

    private var GlobalCupStakePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Practice Stake")
                    .font(.system(size: 18, weight: .black))
                Spacer()
                Text("\(Int(GlobalCupStake))")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(GlobalCupTheme.GlobalCupGreen)
            }
            Slider(value: $GlobalCupStake, in: 100...10_000, step: 100)
                .tint(GlobalCupTheme.GlobalCupRoyal)
            Text("Balance: \(Int(GlobalCupVM.GlobalCupGame.GlobalCupBalance))")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(GlobalCupTheme.GlobalCupMuted)
        }
        .padding(16)
        .GlobalCupPanel()
    }

    private func GlobalCupPlacePracticeBet() {
        guard GlobalCupStake <= GlobalCupVM.GlobalCupGame.GlobalCupBalance else {
            GlobalCupAlert = "The practice stake is higher than the current simulator balance."
            return
        }
        guard let type = GlobalCupVM.GlobalCupBetType() else {
            GlobalCupAlert = "Complete the market selection before running the simulation."
            return
        }
        GlobalCupVM.GlobalCupLastProfit = GlobalCupVM.GlobalCupGame.GlobalCupSettle(type: type, stake: GlobalCupStake)
        GlobalCupShowsResult = true
    }
}

struct GlobalCupMatchHeader: View {
    @ObservedObject var vm: GlobalCupBettingViewModel

    var body: some View {
        VStack(spacing: 14) {
            Text("Practice Match")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(GlobalCupTheme.GlobalCupGreen)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 12) {
                GlobalCupTeamBadge(team: vm.GlobalCupHomeTeam)
                Text("vs")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(GlobalCupTheme.GlobalCupMuted)
                GlobalCupTeamBadge(team: vm.GlobalCupAwayTeam)
            }
            HStack {
                Text("Home odds \(String(format: "%.2f", vm.GlobalCupGame.GlobalCupCoefficients.homeWin))")
                Spacer()
                Text("Draw \(String(format: "%.2f", vm.GlobalCupGame.GlobalCupCoefficients.draw))")
                Spacer()
                Text("Away \(String(format: "%.2f", vm.GlobalCupGame.GlobalCupCoefficients.awayWin))")
            }
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(GlobalCupTheme.GlobalCupMuted)
        }
        .padding(16)
        .GlobalCupPanel()
    }
}

struct GlobalCupTeamBadge: View {
    var team: GlobalCupTeam

    var body: some View {
        VStack(spacing: 8) {
            team.GlobalCupFlag
                .resizable()
                .scaledToFit()
                .frame(height: 34)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            Text(team.name)
                .font(.system(size: 13, weight: .black))
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct GlobalCupStepper: View {
    var label: String
    @Binding var value: Int
    var range: ClosedRange<Int>

    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(GlobalCupTheme.GlobalCupMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("\(value)")
                .font(.system(size: 24, weight: .black))
            Stepper(label, value: $value, in: range)
                .labelsHidden()
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct GlobalCupInfoRow: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(GlobalCupTheme.GlobalCupMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct GlobalCupResultPanel: View {
    @ObservedObject var vm: GlobalCupBettingViewModel
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Simulation Result")
                .font(.system(size: 26, weight: .black))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Text("\(vm.GlobalCupHomeTeam.name) \(vm.GlobalCupGame.GlobalCupSimulationResult.homeGoals.count)")
                Spacer()
                Text("\(vm.GlobalCupGame.GlobalCupSimulationResult.awayGoals.count) \(vm.GlobalCupAwayTeam.name)")
            }
            .font(.system(size: 22, weight: .black))

            Text((vm.GlobalCupLastProfit ?? 0) >= 0 ? "+\(Int(vm.GlobalCupLastProfit ?? 0))" : "\(Int(vm.GlobalCupLastProfit ?? 0))")
                .font(.system(size: 38, weight: .black))
                .foregroundStyle((vm.GlobalCupLastProfit ?? 0) >= 0 ? GlobalCupTheme.GlobalCupGreen : GlobalCupTheme.GlobalCupWarning)

            VStack(spacing: 8) {
                GlobalCupResultRow(title: "Corners", value: "\(vm.GlobalCupGame.GlobalCupSimulationResult.homeCorners + vm.GlobalCupGame.GlobalCupSimulationResult.awayCorners)")
                GlobalCupResultRow(title: "Cards", value: "\(vm.GlobalCupGame.GlobalCupSimulationResult.homeCards + vm.GlobalCupGame.GlobalCupSimulationResult.awayCards)")
                GlobalCupResultRow(title: "Penalty", value: vm.GlobalCupGame.GlobalCupSimulationResult.penaltyAwarded ? "Yes" : "No")
                GlobalCupResultRow(title: "Balance", value: "\(Int(vm.GlobalCupGame.GlobalCupBalance))")
            }

            Button("Next Match", action: onNext)
                .buttonStyle(GlobalCupPrimaryButtonStyle())
        }
        .padding(16)
        .GlobalCupPanel()
    }
}

struct GlobalCupResultRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(GlobalCupTheme.GlobalCupMuted)
            Spacer()
            Text(value)
                .fontWeight(.black)
        }
        .font(.system(size: 14, weight: .semibold))
    }
}
