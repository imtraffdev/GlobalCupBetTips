import SwiftUI

extension Color {
    init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value = UInt64()
        Scanner(string: cleanHex).scanHexInt64(&value)
        let red: UInt64
        let green: UInt64
        let blue: UInt64
        let alpha: UInt64
        switch cleanHex.count {
        case 8:
            alpha = value >> 24
            red = value >> 16 & 0xFF
            green = value >> 8 & 0xFF
            blue = value & 0xFF
        case 6:
            alpha = 255
            red = value >> 16
            green = value >> 8 & 0xFF
            blue = value & 0xFF
        default:
            alpha = 255
            red = 0
            green = 0
            blue = 0
        }

        self.init(.sRGB, red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255, opacity: Double(alpha) / 255)
    }
}

enum GlobalCupTheme {
    static let GlobalCupInk = Color(red: 0.015, green: 0.020, blue: 0.035)
    static let GlobalCupBlack = Color.black
    static let GlobalCupBlue = Color(red: 0.080, green: 0.240, blue: 0.820)
    static let GlobalCupRoyal = Color(red: 0.180, green: 0.270, blue: 0.960)
    static let GlobalCupNavy = Color(red: 0.030, green: 0.100, blue: 0.260)
    static let GlobalCupPanel = Color(red: 0.045, green: 0.075, blue: 0.140)
    static let GlobalCupPanelRaised = Color(red: 0.070, green: 0.125, blue: 0.230)
    static let GlobalCupGreen = Color(red: 0.260, green: 0.760, blue: 0.330)
    static let GlobalCupWhite = Color.white
    static let GlobalCupMuted = Color.white.opacity(0.66)
    static let GlobalCupLine = Color.white.opacity(0.12)
    static let GlobalCupWarning = Color(red: 1.000, green: 0.560, blue: 0.240)
}

struct GlobalCupBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [GlobalCupTheme.GlobalCupInk, GlobalCupTheme.GlobalCupNavy, GlobalCupTheme.GlobalCupBlack],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            GeometryReader { proxy in
                Path { path in
                    let step: CGFloat = 44
                    stride(from: CGFloat(0), through: proxy.size.width, by: step).forEach { x in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: proxy.size.height))
                    }
                    stride(from: CGFloat(0), through: proxy.size.height, by: step).forEach { y in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                    }
                }
                .stroke(GlobalCupTheme.GlobalCupWhite.opacity(0.045), lineWidth: 0.7)
            }
            VStack(spacing: 26) {
                ForEach(0..<8, id: \.self) { index in
                    Capsule()
                        .fill(index.isMultiple(of: 2) ? GlobalCupTheme.GlobalCupRoyal.opacity(0.16) : GlobalCupTheme.GlobalCupGreen.opacity(0.10))
                        .frame(width: 220 + CGFloat(index % 3) * 48, height: 2)
                        .frame(maxWidth: .infinity, alignment: index.isMultiple(of: 2) ? .leading : .trailing)
                        .padding(.horizontal, CGFloat(20 + index * 6))
                }
            }
            .rotationEffect(.degrees(-12))
        }
        .ignoresSafeArea()
    }
}

struct GlobalCupPanelModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(colors: [GlobalCupTheme.GlobalCupPanel, GlobalCupTheme.GlobalCupPanelRaised.opacity(0.88)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 18)
            )
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(GlobalCupTheme.GlobalCupLine, lineWidth: 0.8))
    }
}

extension View {
    func GlobalCupPanel() -> some View {
        modifier(GlobalCupPanelModifier())
    }
}

struct GlobalCupPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .black))
            .foregroundStyle(GlobalCupTheme.GlobalCupWhite)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(colors: [GlobalCupTheme.GlobalCupRoyal, GlobalCupTheme.GlobalCupBlue], startPoint: .topLeading, endPoint: .bottomTrailing).opacity(configuration.isPressed ? 0.75 : 1),
                in: RoundedRectangle(cornerRadius: 14)
            )
    }
}
