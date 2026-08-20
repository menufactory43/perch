import SwiftUI

@main
struct PerchApp: App {
    @State private var controller = PerchController()

    var body: some Scene {
        MenuBarExtra("Perch", systemImage: "cylinder.split.1x2") {
            PopoverRoot()
                .environment(controller)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(controller)
        }
    }
}

#Preview("Popover") {
    PopoverRoot()
        .environment(PerchController.preview)
        .frame(width: PerchMetrics.popoverWidth, height: 480)
}
