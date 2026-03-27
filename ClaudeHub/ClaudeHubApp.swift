import SwiftUI
import SwiftData

@main
struct ClaudeHubApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
                .modelContainer(for: [Project.self, TaskItem.self])
                .onGeometryChange(for: CGSize.self) { $0.size } action: {
                    appModel.windowSize = $0
                }
                .frame(minWidth: 900, minHeight: 600)
        }
    }
}
