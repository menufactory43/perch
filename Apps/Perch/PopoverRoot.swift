import SwiftUI

struct PopoverRoot: View {
    @Environment(PerchController.self) private var controller

    var body: some View {
        @Bindable var controller = controller
        VStack(spacing: 0) {
            HeaderBar()
            Divider()
            Group {
                if controller.hasFullDiskAccess {
                    StatusPane()
                } else {
                    PermissionPane()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            Divider()
            FooterBar()
        }
        .frame(width: PerchMetrics.popoverWidth)
        .frame(minHeight: 420, maxHeight: 560)
        .onAppear(perform: controller.scan)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            controller.refreshAccess()
        }
        .confirmationDialog(
            String(localized: "Share models across apps?"),
            isPresented: $controller.showReclaimConfirmation,
            titleVisibility: .visible
        ) {
            Button(controller.primaryActionTitle, action: controller.confirmReclaim)
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: {
            Text("Perch stores one copy, replaces duplicates with APFS clones, and copies missing models into apps that don’t have them yet. Watching stays on afterwards so this keeps happening.")
        }
    }
}
