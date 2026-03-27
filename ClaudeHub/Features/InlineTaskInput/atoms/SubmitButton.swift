import SwiftUI

struct SubmitButton: View {
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
            }
            .frame(width: Constants.toolbarItemSize, height: Constants.toolbarItemSize)
        }
        .buttonStyle(.glass)
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled && !isLoading ? 1 : 0.4)
        .animation(.smooth, value: isEnabled)
        .animation(.smooth, value: isLoading)
    }
}

#Preview {
    HStack(spacing: 20) {
        SubmitButton(isEnabled: true, isLoading: false, action: {})
        SubmitButton(isEnabled: false, isLoading: false, action: {})
        SubmitButton(isEnabled: false, isLoading: true, action: {})
    }
    .padding()
}
