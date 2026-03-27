import SwiftUI

struct GraphRowSegment: View {
    let isFirst: Bool
    let isLast: Bool
    let color: Color

    static let rowHeight: CGFloat = 32
    static let laneWidth: CGFloat = 20

    var body: some View {
        Canvas { context, size in
            let cx = size.width / 2
            let cy = size.height / 2

            if !isFirst {
                var topLine = Path()
                topLine.move(to: CGPoint(x: cx, y: 0))
                topLine.addLine(to: CGPoint(x: cx, y: cy))
                context.stroke(topLine, with: .color(color), lineWidth: 2)
            }

            if !isLast {
                var bottomLine = Path()
                bottomLine.move(to: CGPoint(x: cx, y: cy))
                bottomLine.addLine(to: CGPoint(x: cx, y: size.height))
                context.stroke(bottomLine, with: .color(color), lineWidth: 2)
            }

            let radius: CGFloat = 4
            let nodeRect = CGRect(
                x: cx - radius, y: cy - radius,
                width: radius * 2, height: radius * 2
            )
            context.fill(Circle().path(in: nodeRect), with: .color(color))
        }
        .frame(width: Self.laneWidth, height: Self.rowHeight)
    }
}

#Preview {
    VStack(spacing: 0) {
        GraphRowSegment(isFirst: true, isLast: false, color: .blue)
        GraphRowSegment(isFirst: false, isLast: false, color: .blue)
        GraphRowSegment(isFirst: false, isLast: false, color: .blue)
        GraphRowSegment(isFirst: false, isLast: true, color: .blue)
    }
    .padding()
}
