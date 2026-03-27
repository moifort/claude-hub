import SwiftUI

struct TerminalCursor: View {
    @State private var isVisible = true

    var body: some View {
        Rectangle()
            .fill(.green)
            .frame(width: 2, height: 16)
            .opacity(isVisible ? 1 : 0)
            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isVisible)
            .onAppear { isVisible = false }
    }
}

#Preview {
    TerminalCursor()
        .padding()
        .background(.black)
}
