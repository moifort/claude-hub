import SwiftUI

struct GeneralSettingsSection: View {
    @Binding var skipPermissions: Bool
    @Binding var claudeBinaryPath: String
    @Binding var preferredIDE: String
    @Binding var gitPanelOpenByDefault: Bool

    private var detectedPath: String {
        CLIService.claudePath() ?? "Not found"
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
                        TextField("Auto-detect: \(detectedPath)", text: $claudeBinaryPath)
                            .font(.system(.body, design: .monospaced))

                        pathStatusIcon

                        Button("Auto-detect") {
                            claudeBinaryPath = ""
                        }
                        .disabled(claudeBinaryPath.isEmpty)
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
        let path = claudeBinaryPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if path.isEmpty {
            if CLIService.claudePath() != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .help("Auto-detected: \(detectedPath)")
            } else {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .help("Claude CLI not found")
            }
        } else if FileManager.default.isExecutableFile(atPath: path) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .help("Binary found")
        } else {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
                .help("Binary not found at this path")
        }
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
