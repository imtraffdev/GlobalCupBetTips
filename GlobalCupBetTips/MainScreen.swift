import SwiftUI

enum GlobalCupTab: String, CaseIterable {
    case dashboard = "Dashboard"
    case simulator = "Simulator"
    case knowledge = "Knowledge"
    case slip = "Slip"

    var GlobalCupIcon: String {
        switch self {
        case .dashboard: "chart.line.uptrend.xyaxis"
        case .simulator: "soccerball"
        case .knowledge: "book.closed"
        case .slip: "list.clipboard"
        }
    }
}

struct MainScreen: View {
    @State private var GlobalCupSelectedTab: GlobalCupTab = .dashboard

    var body: some View {
        ZStack {
            GlobalCupBackground()
            VStack(spacing: 0) {
                Group {
                    switch GlobalCupSelectedTab {
                    case .dashboard:
                        GlobalCupDashboardScreen()
                    case .simulator:
                        BettingView()
                    case .knowledge:
                        StudyScreen()
                    case .slip:
                        GlobalCupSlipScreen()
                    }
                }
                GlobalCupTabBar(GlobalCupSelectedTab: $GlobalCupSelectedTab)
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct GlobalCupDashboardScreen: View {
    private let GlobalCupTeams = GlobalCupDataModule.GlobalCupTeams

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GlobalCupHeroCard()

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    GlobalCupStatCard(title: "Team Pool", value: "\(GlobalCupTeams.count)", detail: "Local database")
                    GlobalCupStatCard(title: "Markets", value: "8", detail: "Practice modes")
                    GlobalCupStatCard(title: "Guide Sets", value: "\(GlobalCupDataModule.GlobalCupKnowledge.count)", detail: "Knowledge base")
                    GlobalCupStatCard(title: "Mode", value: "Sim", detail: "No real stakes")
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Sharp Checklist")
                        .font(.system(size: 20, weight: .black))
                    GlobalCupChecklistRow(title: "Compare implied probability", detail: "Do not follow odds without your own estimate.")
                    GlobalCupChecklistRow(title: "Check tactical matchup", detail: "Tempo, width and pressing shape drive many markets.")
                    GlobalCupChecklistRow(title: "Keep stakes consistent", detail: "The simulator rewards disciplined practice.")
                }
                .padding(16)
                .GlobalCupPanel()
            }
            .padding(18)
        }
        .scrollIndicators(.hidden)
    }
}

struct GlobalCupHeroCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Global Cup Bet Tips")
                        .font(.system(size: 30, weight: .black))
                    Text("MATCH INTELLIGENCE")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(GlobalCupTheme.GlobalCupGreen)
                }
                Spacer()
                Image(systemName: "soccerball")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(GlobalCupTheme.GlobalCupWhite)
                    .padding(14)
                    .background(GlobalCupTheme.GlobalCupRoyal, in: Circle())
            }

            Text("Practice football market reading with local team data, simulated match outcomes and a focused knowledge base.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GlobalCupTheme.GlobalCupMuted)
                .lineSpacing(3)
        }
        .padding(18)
        .background(
            LinearGradient(colors: [GlobalCupTheme.GlobalCupBlue, GlobalCupTheme.GlobalCupRoyal], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 22)
        )
    }
}

struct GlobalCupStatCard: View {
    var title: String
    var value: String
    var detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.system(size: 28, weight: .black))
            Text(title)
                .font(.system(size: 13, weight: .black))
            Text(detail)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(GlobalCupTheme.GlobalCupMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .GlobalCupPanel()
    }
}

struct GlobalCupChecklistRow: View {
    var title: String
    var detail: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle")
                .foregroundStyle(GlobalCupTheme.GlobalCupGreen)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .black))
                Text(detail)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GlobalCupTheme.GlobalCupMuted)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct GlobalCupSlipScreen: View {
    struct GlobalCupJournalEntry: Identifiable, Hashable {
        let id = UUID()
        let GlobalCupMarket: String
        let GlobalCupConfidence: String
        let GlobalCupUnits: Int
        let GlobalCupReason: String
        let GlobalCupRisk: String
    }

    private let GlobalCupMarkets = ["Match Winner", "Draw", "First Scorer", "Correct Score", "Total Corners", "Total Cards", "First Goal Time", "Penalty Awarded"]
    private let GlobalCupConfidenceLevels = ["Lean", "Standard", "Strong"]

    @State private var GlobalCupSelectedMarket = "Match Winner"
    @State private var GlobalCupSelectedConfidence = "Standard"
    @State private var GlobalCupUnits = 1
    @State private var GlobalCupReason = ""
    @State private var GlobalCupRisk = ""
    @State private var GlobalCupEntries: [GlobalCupJournalEntry] = [
        GlobalCupJournalEntry(
            GlobalCupMarket: "Total Corners",
            GlobalCupConfidence: "Lean",
            GlobalCupUnits: 1,
            GlobalCupReason: "Wide attacks and repeated pressure profile.",
            GlobalCupRisk: "Early lead could slow crossing volume."
        )
    ]
    @State private var GlobalCupChecklist: Set<String> = ["Price threshold"]

    private var GlobalCupTotalUnits: Int {
        GlobalCupEntries.reduce(0) { $0 + $1.GlobalCupUnits }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Bet Slip Practice")
                        .font(.system(size: 28, weight: .black))
                    Text("Plan practice selections before running simulations. Record the price idea, risk factor and confidence tier.")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(GlobalCupTheme.GlobalCupMuted)

                    HStack(spacing: 10) {
                        GlobalCupSlipMetric(title: "Entries", value: "\(GlobalCupEntries.count)")
                        GlobalCupSlipMetric(title: "Units", value: "\(GlobalCupTotalUnits)")
                        GlobalCupSlipMetric(title: "Checklist", value: "\(GlobalCupChecklist.count)/4")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .GlobalCupPanel()

                GlobalCupPlannerCard
                GlobalCupDecisionChecklist
                GlobalCupJournalList
            }
            .padding(18)
        }
        .scrollIndicators(.hidden)
    }

    private var GlobalCupPlannerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Decision Planner")
                .font(.system(size: 21, weight: .black))

            Picker("Market", selection: $GlobalCupSelectedMarket) {
                ForEach(GlobalCupMarkets, id: \.self) { GlobalCupMarket in
                    Text(GlobalCupMarket).tag(GlobalCupMarket)
                }
            }
            .pickerStyle(.menu)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

            Picker("Confidence", selection: $GlobalCupSelectedConfidence) {
                ForEach(GlobalCupConfidenceLevels, id: \.self) { GlobalCupLevel in
                    Text(GlobalCupLevel).tag(GlobalCupLevel)
                }
            }
            .pickerStyle(.segmented)

            Stepper("Stake units: \(GlobalCupUnits)", value: $GlobalCupUnits, in: 1...5)
                .font(.system(size: 15, weight: .black))

            TextField("Reasoning note", text: $GlobalCupReason, axis: .vertical)
                .lineLimit(2...4)
                .padding(12)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

            TextField("Main risk factor", text: $GlobalCupRisk, axis: .vertical)
                .lineLimit(2...4)
                .padding(12)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

            Button {
                GlobalCupAddEntry()
            } label: {
                Label("Add to Journal", systemImage: "plus.circle.fill")
            }
            .buttonStyle(GlobalCupPrimaryButtonStyle())
            .disabled(GlobalCupReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(GlobalCupReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
        }
        .padding(16)
        .GlobalCupPanel()
    }

    private var GlobalCupDecisionChecklist: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Before Simulation")
                .font(.system(size: 20, weight: .black))

            ForEach(["Match context", "Price threshold", "Risk note", "Review plan"], id: \.self) { GlobalCupItem in
                Button {
                    if GlobalCupChecklist.contains(GlobalCupItem) {
                        GlobalCupChecklist.remove(GlobalCupItem)
                    } else {
                        GlobalCupChecklist.insert(GlobalCupItem)
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: GlobalCupChecklist.contains(GlobalCupItem) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(GlobalCupChecklist.contains(GlobalCupItem) ? GlobalCupTheme.GlobalCupGreen : GlobalCupTheme.GlobalCupMuted)
                        Text(GlobalCupItem)
                            .font(.system(size: 15, weight: .black))
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .GlobalCupPanel()
    }

    private var GlobalCupJournalList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Saved Notes")
                    .font(.system(size: 20, weight: .black))
                Spacer()
                Button("Clear") {
                    GlobalCupEntries.removeAll()
                }
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(GlobalCupTheme.GlobalCupMuted)
                .disabled(GlobalCupEntries.isEmpty)
            }

            if GlobalCupEntries.isEmpty {
                Text("No saved practice notes yet.")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(GlobalCupTheme.GlobalCupMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(GlobalCupEntries) { GlobalCupEntry in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(GlobalCupEntry.GlobalCupMarket)
                                    .font(.system(size: 16, weight: .black))
                                Text("\(GlobalCupEntry.GlobalCupConfidence) / \(GlobalCupEntry.GlobalCupUnits) unit\(GlobalCupEntry.GlobalCupUnits == 1 ? "" : "s")")
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundStyle(GlobalCupTheme.GlobalCupGreen)
                            }
                            Spacer()
                            Button {
                                GlobalCupEntries.removeAll { $0.id == GlobalCupEntry.id }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(GlobalCupTheme.GlobalCupMuted)
                            }
                        }
                        Text(GlobalCupEntry.GlobalCupReason)
                            .font(.system(size: 13, weight: .semibold))
                        if !GlobalCupEntry.GlobalCupRisk.isEmpty {
                            Text("Risk: \(GlobalCupEntry.GlobalCupRisk)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(GlobalCupTheme.GlobalCupMuted)
                        }
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding(16)
        .GlobalCupPanel()
    }

    private func GlobalCupAddEntry() {
        let GlobalCupTrimmedReason = GlobalCupReason.trimmingCharacters(in: .whitespacesAndNewlines)
        let GlobalCupTrimmedRisk = GlobalCupRisk.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !GlobalCupTrimmedReason.isEmpty else { return }

        GlobalCupEntries.insert(
            GlobalCupJournalEntry(
                GlobalCupMarket: GlobalCupSelectedMarket,
                GlobalCupConfidence: GlobalCupSelectedConfidence,
                GlobalCupUnits: GlobalCupUnits,
                GlobalCupReason: GlobalCupTrimmedReason,
                GlobalCupRisk: GlobalCupTrimmedRisk
            ),
            at: 0
        )
        GlobalCupReason = ""
        GlobalCupRisk = ""
        GlobalCupUnits = 1
    }
}

struct GlobalCupSlipMetric: View {
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .black))
            Text(title)
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(GlobalCupTheme.GlobalCupMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct GlobalCupTabBar: View {
    @Binding var GlobalCupSelectedTab: GlobalCupTab

    var body: some View {
        HStack(spacing: 8) {
            ForEach(GlobalCupTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.80)) {
                        GlobalCupSelectedTab = tab
                    }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.GlobalCupIcon)
                            .font(.system(size: 17, weight: .bold))
                        Text(tab.rawValue)
                            .font(.system(size: 9, weight: .black))
                            .lineLimit(1)
                            .minimumScaleFactor(0.70)
                    }
                    .foregroundStyle(GlobalCupSelectedTab == tab ? GlobalCupTheme.GlobalCupWhite : GlobalCupTheme.GlobalCupMuted)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(GlobalCupSelectedTab == tab ? GlobalCupTheme.GlobalCupRoyal : Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(GlobalCupTheme.GlobalCupLine))
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
}
