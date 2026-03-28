import AppKit
import SwiftUI
import SwiftData

@main
struct ClaudeHubApp: App {
    @State private var appModel = AppModel()
    @State private var sessionManager = TerminalSessionManager()
    @State private var stateMonitor = TerminalStateMonitor()
    @State private var showQuitConfirmation = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
                .environment(sessionManager)
                .environment(stateMonitor)
                .modelContainer(for: [Project.self, TaskItem.self])
                .onGeometryChange(for: CGSize.self) { $0.size } action: {
                    appModel.windowSize = $0
                }
                .frame(minWidth: 900, minHeight: 600)
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                    stateMonitor.stop()
                    sessionManager.removeAll()
                }
                .alert("Quit ClaudeHub?", isPresented: $showQuitConfirmation) {
                    Button("Quit", role: .destructive) {
                        NSApplication.shared.terminate(nil)
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    let count = sessionManager.activeSessions.count
                    Text("\(count) terminal \(count == 1 ? "session is" : "sessions are") still running. Task states are saved, but live terminal sessions will be lost.")
                }
        }
        .commands {
            CommandGroup(replacing: .appTermination) {
                Button("Quit ClaudeHub") {
                    if sessionManager.hasRunningSessions {
                        showQuitConfirmation = true
                    } else {
                        NSApplication.shared.terminate(nil)
                    }
                }
                .keyboardShortcut("q")
            }
        }

        Settings {
            SettingsPage()
        }
    }
}
