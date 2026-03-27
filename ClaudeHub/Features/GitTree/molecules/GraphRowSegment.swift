import SwiftUI

struct GraphRowSegment: View {
    let isMerge: Bool
    let isHead: Bool
    let isFirst: Bool
    let isLast: Bool
    let color: Color

    static let rowHeight: CGFloat = 32
    static let laneWidth: CGFloat = 20

    var body: some View {
        Canvas { context, size in
            let cx = size.width / 2
            let cy = size.height / 2

            // Vertical line — top half
            if !isFirst {
                var topLine = Path()
                topLine.move(to: CGPoint(x: cx, y: 0))
                topLine.addLine(to: CGPoint(x: cx, y: cy))
                context.stroke(topLine, with: .color(color), lineWidth: 2)
            }

            // Vertical line — bottom half
            if !isLast {
                var bottomLine = Path()
                bottomLine.move(to: CGPoint(x: cx, y: cy))
                bottomLine.addLine(to: CGPoint(x: cx, y: size.height))
                context.stroke(bottomLine, with: .color(color), lineWidth: 2)
            }

            // Merge indicator — small diagonal line
            if isMerge {
                var mergeLine = Path()
                mergeLine.move(to: CGPoint(x: cx + 8, y: cy - 6))
                mergeLine.addLine(to: CGPoint(x: cx, y: cy))
                context.stroke(
                    mergeLine,
                    with: .color(color.opacity(0.6)),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                )
            }

            // Commit node
            let radius: CGFloat = isMerge ? 5 : 4
            let nodeRect = CGRect(
                x: cx - radius, y: cy - radius,
                width: radius * 2, height: radius * 2
            )
            context.fill(Circle().path(in: nodeRect), with: .color(color))
            context.stroke(
                Circle().path(in: nodeRect),
                with: .color(.white.opacity(0.8)),
                lineWidth: 1.5
            )

            // HEAD glow
            if isHead {
                let glowRect = nodeRect.insetBy(dx: -3, dy: -3)
                context.fill(
                    Circle().path(in: glowRect),
                    with: .color(color.opacity(0.2))
                )
            }
        }
        .frame(width: Self.laneWidth, height: Self.rowHeight)
    }
}

#Preview {
    VStack(spacing: 0) {
        GraphRowSegment(isMerge: false, isHead: true, isFirst: true, isLast: false, color: .blue)
        GraphRowSegment(isMerge: true, isHead: false, isFirst: false, isLast: false, color: .blue)
        GraphRowSegment(isMerge: false, isHead: false, isFirst: false, isLast: false, color: .blue)
        GraphRowSegment(isMerge: false, isHead: false, isFirst: false, isLast: true, color: .blue)
    }
    .padding()
}
