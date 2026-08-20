import Foundation

public struct ScanReport: Sendable, Equatable {
    public var scannedRoots: [URL]
    public var placements: [Placement]
    public var generatedAt: Date

    public init(scannedRoots: [URL], placements: [Placement], generatedAt: Date = .now) {
        self.scannedRoots = scannedRoots
        self.placements = placements
        self.generatedAt = generatedAt
    }

    public var totalLogicalBytes: Int64 {
        placements.reduce(0) { $0 + $1.logicalBytes }
    }

    public var groups: [Fingerprint: [Placement]] {
        Dictionary(grouping: placements, by: \.fingerprint)
    }

    public var duplicateGroups: [Fingerprint: [Placement]] {
        groups.filter { $0.value.count > 1 }
    }

    public var uniquePackageCount: Int { groups.count }
}
