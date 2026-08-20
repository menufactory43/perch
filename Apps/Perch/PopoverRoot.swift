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
            String(localized: "Replace extra copies with APFS clones?"),
            isPresented: $controller.showReclaimConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Reclaim Space"), action: controller.confirmReclaim)
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: {
            Text("Apps keep their files. Perch stores one copy and clones the rest. This cannot be automatically undone, but any app can re-download its model.")
        }
    }
}
