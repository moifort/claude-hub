import SwiftUI

struct SettingsPage: View {
    @AppStorage("taskSystemPrompt") private var taskSystemPrompt = DefaultSystemPrompt.taskSystemPrompt

    var body: some View {
        TabView {
            Tab("Tasks", systemImage: "terminal") {
                TaskSettingsSection(systemPrompt: $taskSystemPrompt)
                    .padding(Constants.standardPadding)
            }
        }
        .frame(width: 600, minHeight: 500)
    }
}

#Preview {
    SettingsPage()
}
