import SwiftUI

struct PermissionPane: View {
    @Environment(PerchController.self) private var controller

    var body: some View {
        ContentUnavailableView {
            Label("Full Disk Access", systemImage: "internaldrive")
        } description: {
            Text("Perch needs Full Disk Access to find models inside other apps and replace extra copies with clones. Nothing is uploaded.")
        } actions: {
            Button("Open System Settings", action: controller.openFullDiskAccessSettings)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            Button("I’ve granted access", action: controller.scan)
        }
        .padding()
    }
}
