import SwiftUI
import SwiftData

@main
struct ClaudeHubApp: App {
    @State private var appModel = AppModel()
    @State private var sessionManager = TerminalSessionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
                .environment(sessionManager)
                .modelContainer(for: [Project.self, TaskItem.self])
                .onGeometryChange(for: CGSize.self) { $0.size } action: {
                    appModel.windowSize = $0
                }
                .frame(minWidth: 900, minHeight: 600)
        }

        Settings {
            SettingsPage()
        }
    }
}
