import SwiftUI

struct GeneralSettingsSection: View {
    @Binding var skipPermissions: Bool
    @Binding var claudeBinaryPath: String
    @Binding var preferredIDE: String

    private var resolvedPath: String? {
        let path = claudeBinaryPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if !path.isEmpty {
            return FileManager.default.isExecutableFile(atPath: path) ? path : nil
        }
        return CLIService.claudePath()
    }

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
        VStack(alignment: .leading, spacing: 20) {
            ideSection
            Divider()
            permissionsSection
            Divider()
            binaryPathSection
        }
    }

    private var ideSection: some View {
        Picker(selection: selectedIDE) {
            ForEach(IDE.allCases) { ide in
                Label(ide.displayName, systemImage: ide.iconName)
                    .tag(ide)
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Preferred IDE")
                    .font(.headline)
                Text("The IDE opened when clicking the toolbar button.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .pickerStyle(.menu)
    }

    private var permissionsSection: some View {
        Toggle(isOn: $skipPermissions) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Skip Permissions")
                    .font(.headline)
                Text("Pass --allow-dangerously-skip-permissions to Claude CLI. Allows Claude to run without interactive permission prompts.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .toggleStyle(.switch)
    }

    private var binaryPathSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Claude Binary Path")
                        .font(.headline)
                    Text("Path to the Claude CLI executable. Leave empty to auto-detect.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Auto-detect") {
                    claudeBinaryPath = ""
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(claudeBinaryPath.isEmpty)
            }

            HStack(spacing: 8) {
                TextField("Auto-detect: \(detectedPath)", text: $claudeBinaryPath)
                    .font(.system(.body, design: .monospaced))
                    .textFieldStyle(.roundedBorder)

                pathStatusIcon
            }
        }
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

    GeneralSettingsSection(skipPermissions: $skipPermissions, claudeBinaryPath: $claudeBinaryPath, preferredIDE: $preferredIDE)
        .padding()
        .frame(width: 600)
}
