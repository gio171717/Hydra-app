import SwiftUI

enum Theme {
    static let background = Color(hex: 0x04111F)
    static let surface = Color(hex: 0x071928)
    static let card = Color(hex: 0x0A2035)
    static let border = Color(hex: 0x0E3050)
    static let water = Color(hex: 0x1A9FE0)
    static let waterDeep = Color(hex: 0x0B5C99)
    static let waterLight = Color(hex: 0x4FC3F7)
    static let accent = Color(hex: 0x00E5FF)
    static let text = Color(hex: 0xE8F4FD)
    static let muted = Color(hex: 0x6F9BBA)
    static let danger = Color(hex: 0xFF5E7E)

    static let backgroundGradient = LinearGradient(
        colors: [Color(hex: 0x072238), background],
        startPoint: .top,
        endPoint: .center
    )
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// Titoletto di sezione in maiuscoletto, come nel prototipo web.
struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.semibold))
            .tracking(2)
            .foregroundStyle(Theme.muted)
    }
}

/// Pulsante che si rimpicciolisce leggermente quando premuto.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = 18) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Theme.border, lineWidth: 1)
                )
        )
    }
}
