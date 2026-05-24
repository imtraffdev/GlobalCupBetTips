import SwiftUI

struct GlobalCupRootPresenter: View {
    @State private var GlobalCupLaunchDestinationState: GlobalCupLaunchDestination?
    @State private var GlobalCupLaunchProgress = 0.0
    @State private var GlobalCupLaunchStage = 0
    @State private var GlobalCupDidStart = false

    var body: some View {
        ZStack {
            if let destination = GlobalCupLaunchDestinationState {
                switch destination {
                case .native:
                    MainScreen()
                        .transition(.opacity)
                case .web(let url):
                    GlobalCupGateWebContainer(GlobalCupURL: url) {
                        withAnimation {
                            GlobalCupLaunchDestinationState = .native
                        }
                    }
                    .transition(.opacity)
                case .offline:
                    GlobalCupSplashView(progress: GlobalCupLaunchProgress, stage: GlobalCupLaunchStage, isOffline: true)
                }
            } else {
                GlobalCupSplashView(progress: GlobalCupLaunchProgress, stage: GlobalCupLaunchStage)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: GlobalCupLaunchDestinationState)
        .task { await GlobalCupRunLaunch() }
    }

    private func GlobalCupRunLaunch() async {
        guard !GlobalCupDidStart else { return }
        GlobalCupDidStart = true
        async let splash: Void = GlobalCupRunSplashSequence()
        async let gate = GlobalCupRemoteGate.GlobalCupResolveDestination()
        let destination = await gate
        _ = await splash
        withAnimation {
            GlobalCupLaunchDestinationState = destination
        }
    }

    private func GlobalCupRunSplashSequence() async {
        for step in 0...24 {
            await MainActor.run {
                GlobalCupLaunchProgress = Double(step) / 24.0
                GlobalCupLaunchStage = min(2, step / 8)
            }
            try? await Task.sleep(nanoseconds: 54_000_000)
        }
        try? await Task.sleep(nanoseconds: 240_000_000)
    }
}

struct GlobalCupSplashView: View {
    var progress: Double
    var stage: Int
    var isOffline = false

    private let GlobalCupSteps = ["Loading team models", "Preparing market lab", "Building knowledge base"]

    var body: some View {
        ZStack {
            GlobalCupBackground()
            VStack(spacing: 26) {
                Spacer()
                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .stroke(GlobalCupTheme.GlobalCupLine, lineWidth: 10)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(GlobalCupTheme.GlobalCupRoyal, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Image(systemName: "soccerball")
                            .font(.system(size: 52, weight: .bold))
                            .foregroundStyle(GlobalCupTheme.GlobalCupWhite)
                    }
                    .frame(width: 156, height: 156)

                    VStack(spacing: 8) {
                        Text("Global Cup")
                            .font(.system(size: 36, weight: .black))
                        Text("BET TIPS")
                            .font(.system(size: 13, weight: .heavy))
                            .tracking(2)
                            .foregroundStyle(GlobalCupTheme.GlobalCupGreen)
                        Text(isOffline ? "Offline simulator is ready." : GlobalCupSteps[min(stage, GlobalCupSteps.count - 1)])
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(GlobalCupTheme.GlobalCupMuted)
                    }
                }

                HStack(spacing: 8) {
                    ForEach(0..<18, id: \.self) { index in
                        Capsule()
                            .fill(Double(index) / 18.0 <= progress ? GlobalCupTheme.GlobalCupGreen : Color.white.opacity(0.12))
                            .frame(height: index.isMultiple(of: 3) ? 20 : 12)
                    }
                }
                .frame(maxWidth: 240)
                Spacer()
            }
            .padding(24)
        }
        .foregroundStyle(GlobalCupTheme.GlobalCupWhite)
    }
}
