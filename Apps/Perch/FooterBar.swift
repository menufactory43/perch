import SwiftUI

struct FooterBar: View {
    @Environment(PerchController.self) private var controller

    var body: some View {
        HStack {
            SettingsLink {
                Label("Settings", systemImage: "gearshape")
            }
            .labelStyle(.titleAndIcon)
            Spacer()
            Button("Quit Perch", role: .destructive, action: controller.quit)
        }
        .controlSize(.small)
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}
