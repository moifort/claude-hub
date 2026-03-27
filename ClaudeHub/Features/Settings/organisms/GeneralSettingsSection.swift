import SwiftUI

struct GeneralSettingsSection: View {
    @Binding var skipPermissions: Bool
    @Binding var claudeBinaryPath: String
    @Binding var preferredIDE: String
    @Binding var gitPanelOpenByDefault: Bool

    private var resolvedPath: String {
        let custom = claudeBinaryPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if !custom.isEmpty { return custom }
        return CLIService.claudePath() ?? "Not found"
    }

    private var resolvedPathExists: Bool {
        let custom = claudeBinaryPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if !custom.isEmpty {
            return FileManager.default.isExecutableFile(atPath: custom)
        }
        return CLIService.claudePath() != nil
    }

    private var selectedIDE: Binding<IDE> {
        Binding(
            get: { IDE(rawValue: preferredIDE) ?? .intellij },
            set: { preferredIDE = $0.rawValue }
        )
    }

    var body: some View {
        Form {
            Picker("Preferred IDE", selection: selectedIDE) {
                ForEach(IDE.allCases) { ide in
                    Label(ide.displayName, systemImage: ide.iconName)
                        .tag(ide)
                }
            }

            Toggle("Git Panel Open by Default", isOn: $gitPanelOpenByDefault)

            Section {
                Toggle("Skip Permissions", isOn: $skipPermissions)
                    .help("Pass --allow-dangerously-skip-permissions to Claude CLI.")

                LabeledContent("Binary Path") {
                    HStack(spacing: 8) {
                        Text(resolvedPath)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(resolvedPathExists ? .primary : .red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)

                        pathStatusIcon

                        Button("Edit") {
                            pickBinary()
                        }

                        if !claudeBinaryPath.isEmpty {
                            Button("Reset") {
                                claudeBinaryPath = ""
                            }
                        }
                    }
                }
            } header: {
                Text("Claude CLI")
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private var pathStatusIcon: some View {
        if resolvedPathExists {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        } else {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
                .help("Claude CLI not found")
        }
    }

    private func pickBinary() {
        let panel = NSOpenPanel()
        panel.title = "Select Claude CLI Binary"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.treatsFilePackagesAsDirectories = true

        let custom = claudeBinaryPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if !custom.isEmpty {
            panel.directoryURL = URL(fileURLWithPath: custom).deletingLastPathComponent()
        } else if let detected = CLIService.claudePath() {
            panel.directoryURL = URL(fileURLWithPath: detected).deletingLastPathComponent()
        }

        guard panel.runModal() == .OK, let url = panel.url else { return }
        claudeBinaryPath = url.path(percentEncoded: false)
    }
}

#Preview {
    @Previewable @State var skipPermissions = true
    @Previewable @State var claudeBinaryPath = ""
    @Previewable @State var preferredIDE = IDE.intellij.rawValue
    @Previewable @State var gitPanelOpenByDefault = true

    GeneralSettingsSection(skipPermissions: $skipPermissions, claudeBinaryPath: $claudeBinaryPath, preferredIDE: $preferredIDE, gitPanelOpenByDefault: $gitPanelOpenByDefault)
        .frame(width: 500, height: 300)
}
