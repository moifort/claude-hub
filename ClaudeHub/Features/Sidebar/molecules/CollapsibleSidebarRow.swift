import SwiftUI

struct CollapsibleSidebarRow<Label: View, Content: View>: View {
    @Binding var isExpanded: Bool
    var onTap: (() -> Void)?
    @ViewBuilder let label: () -> Label
    @ViewBuilder let content: () -> Content

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 4) {
            Button {
                onTap?()
                if !isExpanded {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded = true
                    }
                }
            } label: {
                label()
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .opacity(isHovering ? 1 : 0)
                    .animation(.easeInOut(duration: 0.15), value: isExpanded)
                    .animation(.easeInOut(duration: 0.15), value: isHovering)
            }
            .buttonStyle(.plain)
        }
        .onHover { hovering in
            isHovering = hovering
        }

        if isExpanded {
            content()
        }
    }
}

#Preview {
    @Previewable @State var isExpanded = true

    List {
        CollapsibleSidebarRow(isExpanded: $isExpanded) {
            Text("My Project")
        } content: {
            Text("Task 1")
            Text("Task 2")
        }
    }
    .frame(width: 260, height: 300)
}
