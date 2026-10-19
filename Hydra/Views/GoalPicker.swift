import SwiftUI

/// Selettore dell'obiettivo giornaliero in litri (passi da 0,1 L).
struct GoalPicker: View {
    @Binding var liters: Double

    private let range = AppSettings.goalRange
    private let suggestions: [Double] = [1.5, 2.0, 2.5, 3.0]

    var body: some View {
        VStack(spacing: 16) {
            Text(Fmt.liters(Int((liters * 1000).rounded())))
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(value: liters))
                .foregroundStyle(Theme.text)
                .frame(maxWidth: .infinity)
                .animation(.snappy, value: liters)

            HStack(spacing: 12) {
                stepButton(systemImage: "minus", delta: -0.1)
                Slider(value: Binding(get: { liters }, set: { set($0) }), in: range, step: 0.1)
                stepButton(systemImage: "plus", delta: 0.1)
            }

            HStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { value in
                    let selected = abs(value - liters) < 0.01
                    Button { set(value) } label: {
                        Text(Fmt.liters(Int(value * 1000)))
                            .font(.footnote.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(selected ? Theme.accent.opacity(0.15) : Theme.surface)
                            )
                            .overlay(Capsule().strokeBorder(selected ? Theme.accent.opacity(0.5) : Theme.border))
                    }
                    .buttonStyle(PressableStyle())
                    .foregroundStyle(selected ? Theme.accent : Theme.text)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: liters)
    }

    private func set(_ value: Double) {
        let rounded = (value * 10).rounded() / 10
        liters = min(max(rounded, range.lowerBound), range.upperBound)
    }

    private func stepButton(systemImage: String, delta: Double) -> some View {
        Button { set(liters + delta) } label: {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .frame(width: 36, height: 36)
                .background(Circle().fill(Theme.surface))
                .overlay(Circle().strokeBorder(Theme.border))
        }
        .buttonStyle(PressableStyle())
        .foregroundStyle(Theme.accent)
    }
}
