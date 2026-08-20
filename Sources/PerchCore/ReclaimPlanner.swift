import Foundation

public struct ReclaimPlanner: @unchecked Sendable {
    public var store: PackageStore

    public init(store: PackageStore) {
        self.store = store
    }

    public func plan(from report: ScanReport) -> ReclaimPlan {
        var ingests: [PlannedIngest] = []
        var replacements: [PlannedReplacement] = []
        var reclaimable: Int64 = 0

        for (fingerprint, group) in report.groups {
            let nonStore = group.filter { $0.source != .store }
            guard let canonical = nonStore.max(by: { $0.logicalBytes < $1.logicalBytes }) ?? group.first else {
                continue
            }

            if !store.contains(fingerprint) {
                ingests.append(PlannedIngest(fingerprint: fingerprint, source: canonical.url))
            }

            let duplicates = nonStore.filter { $0.url.standardizedFileURL.path != canonical.url.standardizedFileURL.path }
            // Also replace extra copies of the canonical when more than one exists.
            for placement in duplicates {
                replacements.append(
                    PlannedReplacement(
                        fingerprint: fingerprint,
                        destination: placement.url,
                        logicalBytes: placement.logicalBytes
                    )
                )
                reclaimable += placement.logicalBytes
            }
        }

        ingests.sort { $0.fingerprint.rawValue < $1.fingerprint.rawValue }
        replacements.sort { $0.destination.path < $1.destination.path }
        return ReclaimPlan(ingests: ingests, replacements: replacements, reclaimableBytes: reclaimable)
    }
}
