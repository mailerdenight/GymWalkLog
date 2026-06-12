import SwiftUI

struct ThemePlantIllustration: View {
    let theme: AppTheme
    var size: CGFloat = 72

    var body: some View {
        ZStack(alignment: .bottom) {
            Capsule()
                .fill(theme.secondaryColor.opacity(0.18))
                .frame(width: size * 0.92, height: size * 0.22)
                .offset(y: size * 0.02)

            plantStem(height: size * 0.68)
                .stroke(theme.primaryColor.opacity(0.55), style: StrokeStyle(lineWidth: max(size * 0.035, 2), lineCap: .round))
                .frame(width: size * 0.56, height: size * 0.68)
                .offset(y: -size * 0.12)

            leaf(x: -size * 0.17, y: -size * 0.38, rotation: -32, scale: 0.92)
            leaf(x: size * 0.16, y: -size * 0.49, rotation: 34, scale: 1.0)
            leaf(x: -size * 0.09, y: -size * 0.58, rotation: -22, scale: 0.72)

            if theme == .sunshine {
                Circle()
                    .fill(theme.secondaryColor.opacity(0.55))
                    .frame(width: size * 0.16, height: size * 0.16)
                    .offset(x: size * 0.19, y: -size * 0.63)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func leaf(x: CGFloat, y: CGFloat, rotation: Double, scale: CGFloat) -> some View {
        Ellipse()
            .fill(theme.secondaryColor.opacity(0.36))
            .frame(width: size * 0.22 * scale, height: size * 0.34 * scale)
            .rotationEffect(.degrees(rotation))
            .offset(x: x, y: y)
    }

    private func plantStem(height: CGFloat) -> Path {
        Path { path in
            path.move(to: CGPoint(x: size * 0.28, y: height))
            path.addQuadCurve(
                to: CGPoint(x: size * 0.30, y: height * 0.12),
                control: CGPoint(x: size * 0.18, y: height * 0.48)
            )
            path.move(to: CGPoint(x: size * 0.29, y: height * 0.52))
            path.addQuadCurve(
                to: CGPoint(x: size * 0.14, y: height * 0.36),
                control: CGPoint(x: size * 0.20, y: height * 0.46)
            )
            path.move(to: CGPoint(x: size * 0.30, y: height * 0.38))
            path.addQuadCurve(
                to: CGPoint(x: size * 0.45, y: height * 0.20),
                control: CGPoint(x: size * 0.40, y: height * 0.34)
            )
        }
    }
}
