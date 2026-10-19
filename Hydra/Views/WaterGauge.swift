import SwiftUI

/// Cerchio che si riempie d'acqua (con onde animate) man mano che bevi.
struct WaterGauge: View {
    var total: Int
    var goal: Int
    var size: CGFloat = 248

    private var progress: Double { goal > 0 ? Double(total) / Double(goal) : 0 }
    private var level: Double { min(max(progress, 0), 1) }

    var body: some View {
        ZStack {
            Circle().fill(Theme.card)

            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                ZStack {
                    WaveShape(level: level, phase: t * 1.4 + 1.2, amplitude: 7, frequency: 1.1)
                        .fill(Theme.accent.opacity(0.22))
                    WaveShape(level: level, phase: t * 2.0, amplitude: 5, frequency: 1.4)
                        .fill(LinearGradient(colors: [Theme.water, Theme.waterDeep], startPoint: .top, endPoint: .bottom))
                }
            }
            .clipShape(Circle())

            Circle().strokeBorder(Theme.border, lineWidth: 1)

            // Anello di avanzamento esterno
            Circle()
                .trim(from: 0, to: level)
                .stroke(
                    AngularGradient(colors: [Theme.water, Theme.accent, Theme.water], center: .center),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(-12)
                .shadow(color: Theme.accent.opacity(0.5), radius: 8)

            VStack(spacing: 2) {
                Text(Fmt.number(total))
                    .font(.system(size: 56, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(total)))
                Text("ml di \(Fmt.liters(goal))")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Theme.text.opacity(0.75))
                Text("\(Int((progress * 100).rounded()))%")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.accent)
                    .padding(.top, 4)
            }
            .foregroundStyle(Theme.text)
            .shadow(color: .black.opacity(0.35), radius: 6)
        }
        .frame(width: size, height: size)
        .animation(.spring(response: 0.7, dampingFraction: 0.75), value: total)
        .animation(.spring(response: 0.7, dampingFraction: 0.75), value: goal)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Bevuti \(total) millilitri su \(goal), \(Int((progress * 100).rounded())) per cento")
    }
}

struct WaveShape: Shape {
    var level: Double
    var phase: Double
    var amplitude: Double
    var frequency: Double

    var animatableData: Double {
        get { level }
        set { level = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard level > 0 else { return path }
        // Onde più calme quando il cerchio è quasi vuoto o pieno.
        let damp = min(1, level * 6, (1 - level) * 6 + 0.25)
        let amp = amplitude * damp
        let baseY = rect.maxY - rect.height * CGFloat(level)
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        var x = rect.minX
        while x <= rect.maxX {
            let rel = Double((x - rect.minX) / rect.width)
            let y = baseY + CGFloat(sin(rel * 2 * Double.pi * frequency + phase) * amp)
            path.addLine(to: CGPoint(x: x, y: y))
            x += 2
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    WaterGauge(total: 1250, goal: 2000)
        .padding(40)
        .background(Theme.background)
}
