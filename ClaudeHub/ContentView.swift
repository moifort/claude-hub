import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @Query private var projects: [Project]

    var body: some View {
        @Bindable var appModel = appModel

        NavigationSplitView {
            SidebarPage()
        } detail: {
            if let selectedID = appModel.selectedProjectID,
               let project = projects.first(where: { $0.persistentModelID == selectedID }) {
                TaskListPage(project: project)
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
