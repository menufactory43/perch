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
            if controller.isScanning || controller.isReclaiming || controller.isDeleting {
                VStack(alignment: .trailing, spacing: 4) {
                    if let fraction = controller.progressFraction {
                        ProgressView(value: fraction)
                            .progressViewStyle(.linear)
                            .frame(width: 96)
                            .accessibilityValue("\(Int(fraction * 100)) percent")
                    } else {
                        ProgressView()
                            .controlSize(.small)
                    }
                    if let message = controller.statusMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: 180, alignment: .trailing)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(controller.statusMessage ?? String(localized: "Working"))
            }
        }
        .padding()
    }
}
