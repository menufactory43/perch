import SwiftUI

struct StatusHero: View {
    @Environment(PerchController.self) private var controller

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if controller.reclaimableBytes > 0 {
                Text(controller.reclaimableBytes, format: .byteCount(style: .file))
                    .font(.largeTitle)
                    .bold()
                    .monospacedDigit()
                    .accessibilityLabel(
                        Text(controller.reclaimableBytes, format: .byteCount(style: .file))
                        + Text(", can be reclaimed")
                    )
                Text("can be reclaimed")
                    .foregroundStyle(.secondary)
                if controller.pushCount > 0 {
                    Text("\(controller.pushCount) apps can use a model you already have.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else if controller.pushCount > 0 {
                Text("\(controller.pushCount) apps to fill")
                    .font(.title2)
                    .bold()
                Text("These apps don’t have a model that is already on this Mac. Perch will clone it into their folder so they don’t download it again.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if (controller.report?.placements.isEmpty ?? true) && !controller.isScanning {
                Text("No speech models yet")
                    .font(.title2)
                    .bold()
                Text("When Dictus, FluidVoice, or another app downloads a model, Perch will see it here.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("All shared")
                    .font(.title2)
                    .bold()
                Text("Each unique model is stored once. Other copies are already clones, or there is only one copy.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Button(controller.primaryActionTitle, action: controller.requestReclaim)
                    .buttonStyle(.borderedProminent)
                    .disabled(!controller.canReclaim)
                    .keyboardShortcut(.defaultAction)
                Button("Scan Again", action: controller.scan)
                    .disabled(controller.isScanning)
            }
            if controller.watchEnabled {
                Label("Watching — new downloads and empty apps are filled automatically.", systemImage: "eye")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
