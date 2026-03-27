import SwiftUI

struct SettingsPage: View {
    @AppStorage("skipPermissions") private var skipPermissions = true
    @AppStorage("claudeBinaryPath") private var claudeBinaryPath = ""
    @AppStorage("preferredIDE") private var preferredIDE = IDE.intellij.rawValue
    @AppStorage("taskSystemPrompt") private var taskSystemPrompt = DefaultSystemPrompt.taskSystemPrompt

    var body: some View {
        TabView {
            Tab("General", systemImage: "gear") {
                GeneralSettingsSection(skipPermissions: $skipPermissions, claudeBinaryPath: $claudeBinaryPath, preferredIDE: $preferredIDE)
                    .padding(Constants.standardPadding)
            }

            Tab("Tasks", systemImage: "terminal") {
                TaskSettingsSection(systemPrompt: $taskSystemPrompt)
                    .padding(Constants.standardPadding)
            }
        }
        .frame(width: 600, height: 500)
    }
}

#Preview {
    SettingsPage()
}
