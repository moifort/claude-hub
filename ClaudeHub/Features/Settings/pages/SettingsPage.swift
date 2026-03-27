import SwiftUI

struct SettingsPage: View {
    @AppStorage("skipPermissions") private var skipPermissions = true
    @AppStorage("claudeBinaryPath") private var claudeBinaryPath = ""
    @AppStorage("preferredIDE") private var preferredIDE = IDE.intellij.rawValue
    @AppStorage("gitPanelOpenByDefault") private var gitPanelOpenByDefault = true
    @AppStorage("archiveDelayMinutes") private var archiveDelayMinutes = 5.0
    @AppStorage("taskSystemPrompt") private var taskSystemPrompt = DefaultSystemPrompt.taskSystemPrompt
    @AppStorage("markersWorking") private var markersWorking = "◆ working"
    @AppStorage("markersWaiting") private var markersWaiting = "◆ waiting"
    @AppStorage("markersPlanReady") private var markersPlanReady = "Ready to code?,bypass permissions,manually approve edits"
    @AppStorage("markersDone") private var markersDone = "◆ done"

    var body: some View {
        TabView {
            Tab("General", systemImage: "gear") {
                GeneralSettingsSection(skipPermissions: $skipPermissions, claudeBinaryPath: $claudeBinaryPath, preferredIDE: $preferredIDE, gitPanelOpenByDefault: $gitPanelOpenByDefault, archiveDelayMinutes: $archiveDelayMinutes)
            }

            Tab("Tasks", systemImage: "terminal") {
                TaskSettingsSection(systemPrompt: $taskSystemPrompt)
            }

            Tab("Status", systemImage: "circle.badge.checkmark") {
                StatusMarkersSection(markersWorking: $markersWorking, markersWaiting: $markersWaiting, markersPlanReady: $markersPlanReady, markersDone: $markersDone)
            }
        }
        .frame(width: 600, height: 500)
    }
}

#Preview {
    SettingsPage()
}
