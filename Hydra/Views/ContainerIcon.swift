import SwiftUI

/// Icona disegnata a mano per ogni contenitore, con un po' d'acqua dentro.
struct ContainerIcon: View {
    let kind: ContainerKind
    var size: CGFloat = 36

    var body: some View {
        let shape = VesselShape(kind: kind)
        ZStack {
            shape
                .fill(
                    LinearGradient(colors: [Theme.water, Theme.waterDeep], startPoint: .top, endPoint: .bottom)
                )
                .mask(alignment: .bottom) {
                    Rectangle().frame(height: size * 0.4)
                }
            shape
                .stroke(Theme.waterLight, style: StrokeStyle(lineWidth: max(1.3, size / 24), lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct VesselShape: Shape {
    let kind: ContainerKind

    func path(in rect: CGRect) -> Path {
        switch kind {
        case .plasticCup:
            return cup(in: rect, top: 0.34, topHalf: 0.27, bottomHalf: 0.17, rimLine: 0.43, baseLine: nil)
        case .glass:
            return cup(in: rect, top: 0.26, topHalf: 0.22, bottomHalf: 0.18, rimLine: nil, baseLine: 0.84)
        case .smallBottle:
            return bottle(in: rect, top: 0.30, halfWidth: 0.15)
        case .bottle:
            return bottle(in: rect, top: 0.14, halfWidth: 0.18)
        case .largeBottle:
            return bottle(in: rect, top: 0.03, halfWidth: 0.22)
        }
    }

    private func cup(in r: CGRect, top: CGFloat, topHalf: CGFloat, bottomHalf: CGFloat,
                     rimLine: CGFloat?, baseLine: CGFloat?) -> Path {
        let p = point(in: r)
        let bottom: CGFloat = 0.95
        var path = Path()
        path.move(to: p(0.5 - topHalf, top))
        path.addLine(to: p(0.5 - bottomHalf, bottom))
        path.addLine(to: p(0.5 + bottomHalf, bottom))
        path.addLine(to: p(0.5 + topHalf, top))
        path.closeSubpath()

        func halfWidth(at y: CGFloat) -> CGFloat {
            topHalf + (bottomHalf - topHalf) * (y - top) / (bottom - top)
        }
        for y in [rimLine, baseLine].compactMap({ $0 }) {
            let w = halfWidth(at: y)
            path.move(to: p(0.5 - w, y))
            path.addLine(to: p(0.5 + w, y))
        }
        return path
    }

    private func bottle(in r: CGRect, top: CGFloat, halfWidth: CGFloat) -> Path {
        let p = point(in: r)
        let bottom: CGFloat = 0.96
        let height = bottom - top
        let capBottom = top + height * 0.09
        let neckBottom = top + height * 0.20
        let shoulder = top + height * 0.36
        let capHalf: CGFloat = 0.075
        let neckHalf: CGFloat = 0.06
        let corner: CGFloat = 0.05
        let left = 0.5 - halfWidth, right = 0.5 + halfWidth

        var path = Path()
        // Tappo
        path.move(to: p(0.5 - capHalf, top))
        path.addLine(to: p(0.5 + capHalf, top))
        path.addLine(to: p(0.5 + capHalf, capBottom))
        path.addLine(to: p(0.5 - capHalf, capBottom))
        path.closeSubpath()
        // Corpo
        path.move(to: p(0.5 - neckHalf, capBottom))
        path.addLine(to: p(0.5 - neckHalf, neckBottom))
        path.addQuadCurve(to: p(left, shoulder), control: p(left, neckBottom))
        path.addLine(to: p(left, bottom - corner))
        path.addQuadCurve(to: p(left + corner, bottom), control: p(left, bottom))
        path.addLine(to: p(right - corner, bottom))
        path.addQuadCurve(to: p(right, bottom - corner), control: p(right, bottom))
        path.addLine(to: p(right, shoulder))
        path.addQuadCurve(to: p(0.5 + neckHalf, neckBottom), control: p(right, neckBottom))
        path.addLine(to: p(0.5 + neckHalf, capBottom))
        path.closeSubpath()
        // Etichetta
        let labelTop = shoulder + (bottom - shoulder) * 0.22
        let labelBottom = shoulder + (bottom - shoulder) * 0.45
        for y in [labelTop, labelBottom] {
            path.move(to: p(left, y))
            path.addLine(to: p(right, y))
        }
        return path
    }

    private func point(in r: CGRect) -> (CGFloat, CGFloat) -> CGPoint {
        { x, y in CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
    }
}

#Preview {
    HStack(spacing: 16) {
        ForEach(ContainerKind.allCases) { ContainerIcon(kind: $0, size: 48) }
    }
    .padding()
    .background(Theme.background)
}
