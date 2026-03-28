import SwiftUI

struct UncommittedRowDetail: View {
    let count: Int
    var onCommitAll: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 6) {
            Text("\(count) uncommitted file\(count > 1 ? "s" : "")")
                .font(.callout)
                .fontWeight(.medium)
                .italic()
                .lineLimit(1)
                .foregroundStyle(.secondary)

            Spacer(minLength: 4)

            if let onCommitAll {
                Button(action: onCommitAll) {
                    Image(systemName: "arrow.up.doc")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.12), in: .capsule)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        UncommittedRowDetail(count: 1)
        UncommittedRowDetail(count: 5)
        UncommittedRowDetail(count: 12)
    }
    .padding()
    .frame(width: 400)
}
