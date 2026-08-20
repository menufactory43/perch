import SwiftUI

struct PermissionPane: View {
    @Environment(PerchController.self) private var controller

    var body: some View {
        ContentUnavailableView {
            Label("Full Disk Access", systemImage: "internaldrive")
        } description: {
            Text("macOS will not show Perch in that list by itself. Click +, pick Perch (Finder will highlight the app), turn the switch on, then come back here. Nothing is uploaded.")
        } actions: {
            Button("Add Perch…", action: controller.openFullDiskAccessSettings)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            Button("I’ve granted access", action: controller.scan)
        }
        .padding()
    }
}
