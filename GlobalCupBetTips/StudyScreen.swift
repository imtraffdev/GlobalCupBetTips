import SwiftUI

struct StudyScreen: View {
    @State private var GlobalCupSelectedTopic = GlobalCupDataModule.GlobalCupKnowledge.first!
    @State private var GlobalCupSelectedChapter: GlobalCupKnowledgeChapter?
    @State private var GlobalCupSearchText = ""

    private var GlobalCupVisibleChapters: [GlobalCupKnowledgeChapter] {
        let GlobalCupQuery = GlobalCupSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !GlobalCupQuery.isEmpty else { return GlobalCupSelectedTopic.chapters }

        return GlobalCupSelectedTopic.chapters.filter {
            $0.title.localizedCaseInsensitiveContains(GlobalCupQuery) ||
            $0.text.localizedCaseInsensitiveContains(GlobalCupQuery)
        }
    }

    private var GlobalCupActiveChapter: GlobalCupKnowledgeChapter? {
        if let GlobalCupSelectedChapter, GlobalCupVisibleChapters.contains(GlobalCupSelectedChapter) {
            return GlobalCupSelectedChapter
        }
        return GlobalCupVisibleChapters.first
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GlobalCupKnowledgeHeader
                GlobalCupTopicGrid
                GlobalCupChapterRail
                GlobalCupChapterDetail
            }
            .padding(18)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            GlobalCupSelectedChapter = GlobalCupSelectedTopic.chapters.first
        }
    }

    private var GlobalCupKnowledgeHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Knowledge Base")
                .font(.system(size: 30, weight: .black))
            Text("A structured betting education hub with market guides, live-reading notes, model habits and pre-match checklists.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GlobalCupTheme.GlobalCupMuted)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(GlobalCupTheme.GlobalCupMuted)
                TextField("Search chapters", text: $GlobalCupSearchText)
                    .font(.system(size: 14, weight: .semibold))
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
            }
            .padding(12)
            .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .GlobalCupPanel()
    }

    private var GlobalCupTopicGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sections")
                    .font(.system(size: 18, weight: .black))
                Spacer()
                Text("\(GlobalCupDataModule.GlobalCupKnowledge.count)")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(GlobalCupTheme.GlobalCupGreen)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(GlobalCupDataModule.GlobalCupKnowledge) { GlobalCupTopic in
                    Button {
                        GlobalCupSelectedTopic = GlobalCupTopic
                        GlobalCupSelectedChapter = GlobalCupTopic.chapters.first
                        GlobalCupSearchText = ""
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(GlobalCupTopic.title)
                                .font(.system(size: 14, weight: .black))
                                .lineLimit(2)
                            Text("\(GlobalCupTopic.chapters.count) chapters")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(GlobalCupSelectedTopic.id == GlobalCupTopic.id ? GlobalCupTheme.GlobalCupWhite.opacity(0.75) : GlobalCupTheme.GlobalCupMuted)
                        }
                        .frame(maxWidth: .infinity, minHeight: 66, alignment: .leading)
                        .padding(12)
                        .background(GlobalCupSelectedTopic.id == GlobalCupTopic.id ? GlobalCupTheme.GlobalCupRoyal : Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(GlobalCupSelectedTopic.id == GlobalCupTopic.id ? GlobalCupTheme.GlobalCupGreen.opacity(0.85) : GlobalCupTheme.GlobalCupLine, lineWidth: 1)
                        )
                    }
                    .foregroundStyle(GlobalCupTheme.GlobalCupWhite)
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .GlobalCupPanel()
    }

    private var GlobalCupChapterRail: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(GlobalCupSelectedTopic.title)
                .font(.system(size: 24, weight: .black))
            Text(GlobalCupSelectedTopic.summary)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GlobalCupTheme.GlobalCupMuted)

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(GlobalCupVisibleChapters) { GlobalCupChapter in
                        Button {
                            GlobalCupSelectedChapter = GlobalCupChapter
                        } label: {
                            Text(GlobalCupChapter.title)
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(GlobalCupActiveChapter?.id == GlobalCupChapter.id ? GlobalCupTheme.GlobalCupWhite : GlobalCupTheme.GlobalCupMuted)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(GlobalCupActiveChapter?.id == GlobalCupChapter.id ? GlobalCupTheme.GlobalCupRoyal : Color.white.opacity(0.07), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
            .scrollIndicators(.hidden)
        }
        .padding(16)
        .GlobalCupPanel()
    }

    @ViewBuilder
    private var GlobalCupChapterDetail: some View {
        if let GlobalCupChapter = GlobalCupActiveChapter {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text(GlobalCupChapter.title)
                        .font(.system(size: 23, weight: .black))
                    Spacer()
                    Text("Guide")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(GlobalCupTheme.GlobalCupGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(GlobalCupTheme.GlobalCupGreen.opacity(0.12), in: Capsule())
                }

                Text(GlobalCupChapter.text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(GlobalCupTheme.GlobalCupWhite.opacity(0.88))
                    .lineSpacing(5)

                Divider()
                    .overlay(GlobalCupTheme.GlobalCupLine)

                Text("Use this note when comparing the simulator price with your own probability estimate. The aim is to understand the decision path before running a practice scenario.")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(GlobalCupTheme.GlobalCupMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .GlobalCupPanel()
        } else {
            Text("No chapters match the current search.")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(GlobalCupTheme.GlobalCupMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .GlobalCupPanel()
        }
    }
}
