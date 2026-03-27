import AppKit

enum IDE: String, CaseIterable, Identifiable {
    case intellij
    case vscode
    case xcode
    case cursor
    case zed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .intellij: "IntelliJ IDEA"
        case .vscode: "VS Code"
        case .xcode: "Xcode"
        case .cursor: "Cursor"
        case .zed: "Zed"
        }
    }

    var bundleIdentifier: String {
        switch self {
        case .intellij: "com.jetbrains.intellij"
        case .vscode: "com.microsoft.VSCode"
        case .xcode: "com.apple.dt.Xcode"
        case .cursor: "com.todesktop.230313mzl4w4u92"
        case .zed: "dev.zed.Zed"
        }
    }

    var iconName: String {
        switch self {
        case .intellij: "hammer"
        case .vscode: "chevron.left.forwardslash.chevron.right"
        case .xcode: "hammer.fill"
        case .cursor: "cursorarrow.rays"
        case .zed: "bolt.fill"
        }
    }

    func open(path: String) {
        let url = URL(fileURLWithPath: path)
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            return
        }
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: configuration)
    }
}
