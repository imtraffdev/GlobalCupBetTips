import Foundation

struct GlobalCupTeamDatabase: Codable {
    let teams: [GlobalCupTeamData]
}

struct GlobalCupTeamData: Codable, Hashable, Identifiable {
    var id: String { country }
    let country: String
    let players: [GlobalCupPlayerData]
}

struct GlobalCupPlayerData: Codable, Hashable, Identifiable {
    var id: String { name }
    let name: String
    let goalProbability: Double
    let faultProbability: Double
}

struct GlobalCupKnowledgeTopic: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let summary: String
    let chapters: [GlobalCupKnowledgeChapter]
}

struct GlobalCupKnowledgeChapter: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let text: String
}

enum GlobalCupDataModule {
    static var GlobalCupTeams: [GlobalCupTeam] {
        guard let url = Bundle.main.url(forResource: "data", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(GlobalCupTeamDatabase.self, from: data) else {
            return GlobalCupFallbackTeams
        }

        return decoded.teams.map { team in
            GlobalCupTeam(
                name: team.country,
                players: team.players.map {
                    GlobalCupPlayer(name: $0.name, goalProbability: $0.goalProbability, faultProbability: $0.faultProbability)
                }
            )
        }
    }

    static let GlobalCupKnowledge: [GlobalCupKnowledgeTopic] = [
        GlobalCupKnowledgeTopic(
            title: "Match Context",
            summary: "Build a pre-match view from tactical fit, player availability, schedule pressure and likely game state.",
            chapters: [
                GlobalCupKnowledgeChapter(title: "Start With Game State", text: "A useful preview starts with the way each side wants the match to look. Look at tempo, pressing habits, defensive height and whether either team is comfortable without the ball. A strong pick usually has a clear match-state story rather than only a favorite name."),
                GlobalCupKnowledgeChapter(title: "Schedule Pressure", text: "Short rest, long travel and rotation risk can change a market quickly. When teams play several intense fixtures close together, prioritize depth, recent minutes and whether key roles have reliable replacements."),
                GlobalCupKnowledgeChapter(title: "Lineup Signals", text: "Treat expected lineups as probability inputs, not certainties. A missing ball-winner can matter more than a missing forward if the team relies on transitions. A fullback absence can also change corner and crossing volume."),
                GlobalCupKnowledgeChapter(title: "Tactical Mismatch", text: "Look for where one style naturally stresses another. A high press can create chances against slow buildup, while a compact low block can frustrate possession-heavy sides if they lack runners behind the line."),
                GlobalCupKnowledgeChapter(title: "Motivation Without Hype", text: "Motivation matters only when it changes decisions on the pitch. A team needing a result may press earlier, leave more space late, or rotate less. Convert the narrative into a concrete football effect before using it.")
            ]
        ),
        GlobalCupKnowledgeTopic(
            title: "Odds Logic",
            summary: "Convert odds into implied probability and compare that number with your own read.",
            chapters: [
                GlobalCupKnowledgeChapter(title: "Implied Probability", text: "Decimal odds can be converted with 1 divided by the price. Odds of 2.00 imply roughly 50 percent before margin. The question is whether your own analysis puts the true chance above or below that number."),
                GlobalCupKnowledgeChapter(title: "Market Margin", text: "Book prices include margin, so every line is slightly tilted against the player. Compare several outcomes in the same market and avoid treating the displayed price as a neutral forecast."),
                GlobalCupKnowledgeChapter(title: "Value Discipline", text: "A good idea is not automatically a good selection. Value appears when the price is better than the probability you estimate. Passing on unclear markets is part of disciplined analysis."),
                GlobalCupKnowledgeChapter(title: "Closing Line Review", text: "After the match starts, compare your entry price with the final pre-match price. Beating the closing number is not a guarantee of profit, but it is a useful sign that your process found a better-than-market entry."),
                GlobalCupKnowledgeChapter(title: "Do Not Average Opinions", text: "Two weak angles do not become one strong angle. If the price is fair on form and only slightly interesting on lineup news, it may still be a pass. Combine evidence only when the signals point to the same match story.")
            ]
        ),
        GlobalCupKnowledgeTopic(
            title: "Goal Markets",
            summary: "Use tempo, shot quality and score incentives to evaluate totals, both-teams-to-score and correct-score ideas.",
            chapters: [
                GlobalCupKnowledgeChapter(title: "Total Goals", text: "Totals are shaped by finishing quality, shot locations, defensive structure and game incentives. A high-profile attacking team can still produce a low-total setup if the opponent slows possession and limits central space."),
                GlobalCupKnowledgeChapter(title: "Shot Quality Beats Shot Count", text: "A team taking many low-value shots from distance may look active without creating strong scoring positions. Prioritize central touches, cutbacks, set pieces and chances after defensive disruption."),
                GlobalCupKnowledgeChapter(title: "Both Teams to Score", text: "This market needs two separate arguments, not just an open match. Ask whether the weaker side has a realistic path to chances and whether the stronger side is vulnerable in transition or on set plays."),
                GlobalCupKnowledgeChapter(title: "Correct Score Use", text: "Correct-score prices are sensitive and high variance. Use them as a scenario exercise: if your main read is low tempo, 0-0, 1-0 and 1-1 should feel more natural than wide scorelines."),
                GlobalCupKnowledgeChapter(title: "Early Goal Risk", text: "An early goal can either open a match or kill it, depending on the favorite and underdog behavior. Before choosing a total, think about what each side does at 1-0, 0-1 and level after 70 minutes.")
            ]
        ),
        GlobalCupKnowledgeTopic(
            title: "Side Markets",
            summary: "Read corners, cards, fouls and player props through repeatable match mechanics.",
            chapters: [
                GlobalCupKnowledgeChapter(title: "Corner Profiles", text: "Corner volume often follows wide attacks, blocked crosses and sustained pressure. Teams that attack the box early can create corner value even when they are not heavy favorites."),
                GlobalCupKnowledgeChapter(title: "Cards and Matchups", text: "Card markets need referee tendency, rivalry intensity and individual duels. A fast winger against a slow fullback can matter more than broad team discipline numbers."),
                GlobalCupKnowledgeChapter(title: "Fouls From Pressure", text: "Pressing sides commit tactical fouls when the first pressure line is broken. Deep defensive teams can also foul often if they struggle to clear second balls around the box."),
                GlobalCupKnowledgeChapter(title: "Player Shots", text: "Player shot value comes from role, not reputation. Check set-piece duty, average touch zones, whether the player cuts inside, and whether the opponent allows attempts from that channel."),
                GlobalCupKnowledgeChapter(title: "Keeper Saves", text: "Save lines depend on shot volume and shot quality allowed. A team can face many shots but few saves if attempts are blocked early or come from poor angles.")
            ]
        ),
        GlobalCupKnowledgeTopic(
            title: "Live Reading",
            summary: "Update the pre-match plan using pressure, substitutions, field position and score effects.",
            chapters: [
                GlobalCupKnowledgeChapter(title: "Possession Is Not Pressure", text: "A team can hold the ball without creating danger. In live analysis, separate sterile possession from territory, box entries, set pieces and repeated actions near goal."),
                GlobalCupKnowledgeChapter(title: "Momentum Needs Evidence", text: "Momentum is useful only when visible in repeatable actions. Look for recoveries high up the pitch, quicker restarts, defensive panic, and whether the same channel is being attacked repeatedly."),
                GlobalCupKnowledgeChapter(title: "Substitution Impact", text: "A substitution can change more than player quality. It may alter formation, pressing triggers, set-piece delivery or whether a team accepts a draw."),
                GlobalCupKnowledgeChapter(title: "Late Match Totals", text: "After 70 minutes, fatigue and urgency can increase chaos, but only if at least one side is willing to take risk. A content favorite may slow the game instead of chasing another goal."),
                GlobalCupKnowledgeChapter(title: "Red Card Reset", text: "A red card does not automatically mean more goals. The losing side may still attack, but the leading side with an extra player often chooses control. Rebuild the market from the new tactical shape.")
            ]
        ),
        GlobalCupKnowledgeTopic(
            title: "Model Building",
            summary: "Turn opinions into a simple repeatable rating process before choosing simulated selections.",
            chapters: [
                GlobalCupKnowledgeChapter(title: "Three-Layer Rating", text: "Start with team strength, adjust for availability, then adjust for matchup style. Keeping the layers separate helps you see whether a pick is based on stable quality or temporary news."),
                GlobalCupKnowledgeChapter(title: "Use Ranges", text: "Avoid pretending a match has one exact probability. Build a low, middle and high estimate. If the price only works in the most optimistic case, the edge is probably fragile."),
                GlobalCupKnowledgeChapter(title: "Weight Recent Matches Carefully", text: "Recent form matters most when the performance change is tactical or personnel-based. A lucky finishing streak is weaker evidence than a new formation creating better chances."),
                GlobalCupKnowledgeChapter(title: "Separate Attack and Defense", text: "Do not rate a team as simply good or bad. Strong attack with weak defensive transitions points to different markets than a balanced side with low tempo."),
                GlobalCupKnowledgeChapter(title: "Track Assumptions", text: "Every model has assumptions. Write the two or three that matter most for a selection, then review whether they were true after the match.")
            ]
        ),
        GlobalCupKnowledgeTopic(
            title: "Stake Control",
            summary: "Keep decisions consistent with stake sizing, limits and review habits.",
            chapters: [
                GlobalCupKnowledgeChapter(title: "Unit Size", text: "Use a fixed unit so one opinion cannot damage the whole plan. Smaller, repeatable decisions are easier to review than emotional swings after a result."),
                GlobalCupKnowledgeChapter(title: "Avoid Chase Logic", text: "A previous loss does not make the next selection stronger. If the reasoning is not clear before the stake is entered, skip it and protect the balance."),
                GlobalCupKnowledgeChapter(title: "Review Notes", text: "Track why a selection was made, what information mattered and whether the final result matched the original read. Good reviews improve future decisions more than only checking wins and losses."),
                GlobalCupKnowledgeChapter(title: "Confidence Tiers", text: "Use tiers such as lean, standard and strong instead of emotional stake jumps. A strong opinion should have multiple independent reasons and a price that still looks fair after conservative adjustment."),
                GlobalCupKnowledgeChapter(title: "Session Limits", text: "Set a maximum number of simulations or selections per session. Decision quality usually drops when the goal becomes finding action instead of finding value.")
            ]
        ),
        GlobalCupKnowledgeTopic(
            title: "Pre-Match Checklist",
            summary: "A fast workflow for turning research into a clean final decision.",
            chapters: [
                GlobalCupKnowledgeChapter(title: "Confirm the Setup", text: "Write the expected match shape in one sentence: who controls territory, who creates transition danger, and which team benefits if tempo drops."),
                GlobalCupKnowledgeChapter(title: "Check Team News", text: "Review missing starters, role changes and likely rotation. Focus on players who change structure: holding midfielders, fullbacks, set-piece takers and pressing forwards."),
                GlobalCupKnowledgeChapter(title: "Compare Price to Probability", text: "Convert the available price to implied probability, remove a rough margin, then compare with your estimate. If the edge disappears after a small adjustment, move on."),
                GlobalCupKnowledgeChapter(title: "Choose the Cleanest Market", text: "The best opinion may express better in a side market than a match winner. A favorite with wide pressure may point to corners; a cagey favorite may point to low totals or narrow scorelines."),
                GlobalCupKnowledgeChapter(title: "Write the Exit Note", text: "Before confirming, write what would make the pick wrong. This makes post-match review honest and helps you avoid defending weak logic after the result.")
            ]
        )
    ]

    private static let GlobalCupFallbackTeams: [GlobalCupTeam] = [
        GlobalCupTeam(name: "Italy", players: [
            GlobalCupPlayer(name: "Chiesa", goalProbability: 0.52, faultProbability: 0.20),
            GlobalCupPlayer(name: "Barella", goalProbability: 0.38, faultProbability: 0.18),
            GlobalCupPlayer(name: "Donnarumma", goalProbability: 0.05, faultProbability: 0.30)
        ]),
        GlobalCupTeam(name: "Spain", players: [
            GlobalCupPlayer(name: "Pedri", goalProbability: 0.42, faultProbability: 0.12),
            GlobalCupPlayer(name: "Morata", goalProbability: 0.56, faultProbability: 0.22),
            GlobalCupPlayer(name: "Simon", goalProbability: 0.04, faultProbability: 0.31)
        ])
    ]
}
