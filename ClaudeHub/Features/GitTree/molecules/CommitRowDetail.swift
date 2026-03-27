import SwiftUI

struct CommitRowDetail: View, Equatable {
    let subject: String
    let date: Date
    let isLocalHead: Bool
    let isRemoteHead: Bool

    var body: some View {
        HStack(spacing: 6) {
            Text(subject)
                .font(.callout)
                .fontWeight(.bold)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(.primary)

            if isLocalHead {
                SyncBadge(position: .local)
            }

            if isRemoteHead {
                SyncBadge(position: .remote)
            }

            Spacer(minLength: 4)

            Text(roundedTimeAgo(from: date))
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .fixedSize()
        }
    }

    private func roundedTimeAgo(from date: Date) -> String {
        let seconds = Date.now.timeIntervalSince(date)
        let minutes = seconds / 60
        let hours = minutes / 60
        let days = hours / 24

        if minutes < 10 {
            return "now"
        } else if minutes < 60 {
            let rounded = Int(minutes / 10) * 10
            return "\(rounded) min"
        } else if hours < 24 {
            return "\(Int(hours))h"
        } else if days < 7 {
            return "\(Int(days))d"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM"
            return formatter.string(from: date)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        CommitRowDetail(
            subject: "feat(git-tree): add commit graph visualization panel",
            date: .now.addingTimeInterval(-120),
            isLocalHead: true,
            isRemoteHead: true
        )
        CommitRowDetail(
            subject: "fix: resolve sidebar crash on empty project",
            date: .now.addingTimeInterval(-3600),
            isLocalHead: false,
            isRemoteHead: false
        )
        CommitRowDetail(
            subject: "refactor(state): unify selection model",
            date: .now.addingTimeInterval(-90000),
            isLocalHead: false,
            isRemoteHead: false
        )
    }
    .padding()
    .frame(width: 400)
}
