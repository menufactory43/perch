import Foundation

public struct ReclaimPlan: Sendable, Equatable {
    public var ingests: [PlannedIngest]
    public var replacements: [PlannedReplacement]
    public var reclaimableBytes: Int64

    public init(ingests: [PlannedIngest], replacements: [PlannedReplacement], reclaimableBytes: Int64) {
        self.ingests = ingests
        self.replacements = replacements
        self.reclaimableBytes = reclaimableBytes
    }

    public var isEmpty: Bool {
        replacements.isEmpty && ingests.isEmpty
    }
}

public struct PlannedIngest: Sendable, Equatable {
    public var fingerprint: Fingerprint
    public var source: URL

    public init(fingerprint: Fingerprint, source: URL) {
        self.fingerprint = fingerprint
        self.source = source
    }
}

public struct PlannedReplacement: Sendable, Equatable {
    public var fingerprint: Fingerprint
    public var destination: URL
    public var logicalBytes: Int64

    public init(fingerprint: Fingerprint, destination: URL, logicalBytes: Int64) {
        self.fingerprint = fingerprint
        self.destination = destination
        self.logicalBytes = logicalBytes
    }
}

public struct ReclaimResult: Sendable, Equatable {
    public var cloned: Int
    public var copied: Int
    public var failed: [String]
    public var reclaimedBytes: Int64

    public init(cloned: Int, copied: Int, failed: [String], reclaimedBytes: Int64) {
        self.cloned = cloned
        self.copied = copied
        self.failed = failed
        self.reclaimedBytes = reclaimedBytes
    }
}
