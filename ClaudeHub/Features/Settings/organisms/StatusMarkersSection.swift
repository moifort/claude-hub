import SwiftUI

struct StatusMarkersSection: View {
    @Binding var markersWorking: String
    @Binding var markersWaiting: String
    @Binding var markersPlanReady: String
    @Binding var markersDone: String

    var body: some View {
        Form {
            Section {
                markerField("Working", text: $markersWorking, defaultValue: "◆ working")
                markerField("Waiting", text: $markersWaiting, defaultValue: "◆ waiting")
                markerField("Plan Ready", text: $markersPlanReady, defaultValue: "Ready to code?,bypass permissions,manually approve edits")
                markerField("Done", text: $markersDone, defaultValue: "◆ done")
            } header: {
                Text("Detection Keywords")
            } footer: {
                Text("Comma-separated keywords detected in the terminal buffer. When a keyword is found, the task status updates accordingly. Cursor stability is also used as a fallback for waiting detection.")
            }
        }
        .formStyle(.grouped)
    }

    private func markerField(_ label: String, text: Binding<String>, defaultValue: String) -> some View {
        LabeledContent(label) {
            TextField(defaultValue, text: text)
                .font(.system(.body, design: .monospaced))
                .textFieldStyle(.roundedBorder)
        }
    }
}

#Preview {
    @Previewable @State var working = "◆ working"
    @Previewable @State var waiting = "◆ waiting"
    @Previewable @State var planReady = "Ready to code?,bypass permissions,manually approve edits"
    @Previewable @State var done = "◆ done"

    StatusMarkersSection(
        markersWorking: $working,
        markersWaiting: $waiting,
        markersPlanReady: $planReady,
        markersDone: $done
    )
    .frame(width: 600, height: 400)
}
