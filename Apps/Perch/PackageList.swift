import PerchCore
import SwiftUI

struct PackageList: View {
    @Environment(PerchController.self) private var controller

    var body: some View {
        let groups = grouped
        if groups.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Models")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ForEach(groups) { group in
                    PackageRow(group: group)
                }
            }
        }
    }

    private var grouped: [PackageGroup] {
        guard let report = controller.report else { return [] }
        return report.groups
            .map { fingerprint, placements in
                PackageGroup(
                    id: fingerprint.rawValue,
                    name: placements[0].displayName,
                    kind: placements[0].kind,
                    logicalBytes: placements[0].logicalBytes,
                    copies: placements.count,
                    apps: placements.map(\.source.displayName)
                )
            }
            .sorted { $0.logicalBytes > $1.logicalBytes }
    }
}
