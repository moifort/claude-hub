import SwiftUI

struct UncommittedRowDetail: View {
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            Text("\(count) uncommitted file\(count > 1 ? "s" : "")")
                .font(.callout)
                .fontWeight(.medium)
                .italic()
                .lineLimit(1)
                .foregroundStyle(.secondary)

            Spacer(minLength: 4)
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
