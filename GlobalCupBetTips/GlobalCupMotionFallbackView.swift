import SwiftUI

struct GlobalCupMotionFallbackView: View {
    var GlobalCupFilename: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(GlobalCupTheme.GlobalCupLine, lineWidth: 8)
            Image(systemName: "soccerball")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(GlobalCupTheme.GlobalCupWhite)
        }
    }
}
