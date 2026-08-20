import SwiftUI

struct HeaderBar: View {
    @Environment(PerchController.self) private var controller

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Perch")
                    .font(.headline)
                Text("Shared speech models")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if controller.isScanning || controller.isReclaiming {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel(controller.statusMessage ?? String(localized: "Working"))
            }
        }
        .padding()
    }
}
