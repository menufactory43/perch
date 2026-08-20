import SwiftUI

struct StatusHero: View {
    @Environment(PerchController.self) private var controller

    var body: some View {
        @Bindable var controller = controller
        VStack(alignment: .leading, spacing: 8) {
            if (controller.report?.placements.isEmpty ?? true) && !controller.isScanning {
                Text("No speech models yet")
                    .font(.title2)
                    .bold()
                Text("When Dictus, FluidVoice, or another app downloads a model, Perch will see it here.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ModelTotals(
                    totalBytes: controller.totalBytes,
                    uniqueCount: controller.uniqueCount,
                    reclaimableBytes: controller.reclaimableBytes
                )
                if controller.pushCount > 0 {
                    Text("\(controller.pushCount) apps can use a model you already have.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else if controller.reclaimableBytes == 0,
                          (controller.report?.placements.count ?? 0) > controller.uniqueCount
                {
                    Text("Every extra copy is already a clone.")
                        .foregroundStyle(.secondary)
                }
            }

            if controller.showReclaimConfirmation {
                Text("Replace extra copies with APFS clones? Apps keep working. About \(controller.reclaimableBytes, format: .byteCount(style: .file)) of duplicate files.")
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Button("Cancel") {
                        controller.showReclaimConfirmation = false
                    }
                    Button("Confirm Reclaim", action: controller.confirmReclaim)
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                }
            } else {
                HStack {
                    Button(controller.primaryActionTitle, action: controller.requestReclaim)
                        .buttonStyle(.borderedProminent)
                        .disabled(!controller.canReclaim || controller.isReclaiming)
                        .keyboardShortcut(.defaultAction)
                    Button("Scan Again", action: controller.scan)
                        .disabled(controller.isScanning || controller.isReclaiming)
                }
            }
            if controller.watchEnabled {
                Label("Watching — new downloads and empty apps are filled automatically.", systemImage: "eye")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
