import SwiftUI

struct DeleteConfirm: View {
    @Environment(PerchController.self) private var controller
    var group: PackageGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Delete \(group.name)?")
                .font(.headline)
            Text("Removes it from \(appList) and from Perch. Apps may download it again. This cannot be undone.")
                .fixedSize(horizontal: false, vertical: true)
            Text(group.logicalBytes, format: .byteCount(style: .file))
                .foregroundStyle(.secondary)
                .monospacedDigit()
            HStack {
                Button("Cancel", action: controller.cancelDelete)
                Button("Delete Model", role: .destructive, action: controller.confirmDelete)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }

    private var appList: String {
        Array(Set(group.apps)).sorted().joined(separator: ", ")
    }
}
