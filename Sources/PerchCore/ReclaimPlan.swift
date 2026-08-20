import Foundation

public struct ReclaimPlan: Sendable, Equatable {
    public var ingests: [PlannedIngest]
    public var replacements: [PlannedReplacement]
    public var pushes: [PlannedPush]
    public var reclaimableBytes: Int64

    public init(
        ingests: [PlannedIngest],
        replacements: [PlannedReplacement],
        pushes: [PlannedPush] = [],
        reclaimableBytes: Int64
    ) {
        self.ingests = ingests
        self.replacements = replacements
        self.pushes = pushes
        self.reclaimableBytes = reclaimableBytes
    }

    public var isEmpty: Bool {
        replacements.isEmpty && pushes.isEmpty
    }
}

public struct PlannedPush: Sendable, Equatable {
    public var fingerprint: Fingerprint
    public var destination: URL
    public var fileName: String

    public init(fingerprint: Fingerprint, destination: URL, fileName: String) {
        self.fingerprint = fingerprint
        self.destination = destination
        self.fileName = fileName
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
    public var pushed: Int
    public var failed: [String]
    public var reclaimedBytes: Int64

    public init(cloned: Int, copied: Int, pushed: Int = 0, failed: [String], reclaimedBytes: Int64) {
        self.cloned = cloned
        self.copied = copied
        self.pushed = pushed
        self.failed = failed
        self.reclaimedBytes = reclaimedBytes
    }
}
