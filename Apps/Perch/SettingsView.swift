import SwiftUI

struct SettingsView: View {
    @Environment(PerchController.self) private var controller
    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var launchError: String?

    var body: some View {
        @Bindable var controller = controller
        Form {
            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        setLaunchAtLogin(enabled)
                    }
                Toggle("Keep sharing automatically", isOn: $controller.watchEnabled)
                Text("When an app re-downloads a model you already have, or a new app is missing one, Perch clones it. The first Reclaim turns this on.")
                    .foregroundStyle(.secondary)
            }

            Section("Store") {
                LabeledContent("Location") {
                    Text("~/Library/Application Support/Perch")
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                Button("Reveal in Finder", action: controller.revealStore)
            }

            Section("Privacy") {
                LabeledContent("Full Disk Access") {
                    Text(controller.hasFullDiskAccess ? "On" : "Off")
                }
                Button("Open System Settings", action: controller.openFullDiskAccessSettings)
                Text("Perch never uploads models or audio. It only reads and clones files already on this Mac.")
                    .foregroundStyle(.secondary)
            }

            if let launchError {
                Section {
                    Text(launchError)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 380)
        .navigationTitle("Perch Settings")
        .onAppear {
            launchAtLogin = LaunchAtLogin.isEnabled
            controller.refreshAccess()
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try LaunchAtLogin.setEnabled(enabled)
            launchError = nil
        } catch {
            launchError = error.localizedDescription
            launchAtLogin = LaunchAtLogin.isEnabled
        }
    }
}
