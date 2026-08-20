import SwiftUI

struct PopoverRoot: View {
    @Environment(PerchController.self) private var controller

    var body: some View {
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
    }
}
