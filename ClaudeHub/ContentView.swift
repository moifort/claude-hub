import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        @Bindable var appModel = appModel

        NavigationSplitView {
            Text("Sidebar")
                .navigationTitle("ClaudeHub")
        } detail: {
            if appModel.selectedProjectID != nil {
                Text("Task List")
            } else {
                ContentUnavailableView(
                    "No Project Selected",
                    systemImage: "folder",
                    description: Text("Select a project from the sidebar to view its tasks.")
                )
            }
        }
        .inspector(isPresented: $appModel.showInspector) {
            if appModel.selectedTaskID != nil {
                Text("Terminal")
            } else {
                ContentUnavailableView(
                    "No Task Selected",
                    systemImage: "terminal",
                    description: Text("Select a task to view its terminal.")
                )
            }
        }
    }
}

#Preview {
    @Previewable @State var appModel = AppModel()

    ContentView()
        .environment(appModel)
        .modelContainer(for: [Project.self, TaskItem.self], inMemory: true)
        .frame(width: 1000, height: 700)
}
