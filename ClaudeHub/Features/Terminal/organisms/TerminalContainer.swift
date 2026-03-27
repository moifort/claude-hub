import SwiftUI

struct TerminalContainer: View {
    let taskSlug: String

    var body: some View {
        TerminalRepresentable(taskSlug: taskSlug)
    }
}
