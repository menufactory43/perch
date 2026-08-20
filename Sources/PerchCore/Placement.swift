import Foundation

/// A model package found on disk, owned by an app, a library, or a cache.
public struct Placement: Sendable, Hashable, Identifiable {
    public var id: URL { url }
    public var url: URL
    public var fingerprint: Fingerprint
    public var logicalBytes: Int64
    public var source: PlacementSource
    public var kind: ModelKind
    public var displayName: String

    public init(
        url: URL,
        fingerprint: Fingerprint,
        logicalBytes: Int64,
        source: PlacementSource,
        kind: ModelKind,
        displayName: String
    ) {
        self.url = url
        self.fingerprint = fingerprint
        self.logicalBytes = logicalBytes
        self.source = source
        self.kind = kind
        self.displayName = displayName
    }
}

public enum PlacementSource: Sendable, Hashable, Codable {
    case app(id: String, name: String)
    case library(name: String)
    case huggingface
    case store
    case unknown

    public var displayName: String {
        switch self {
        case .app(_, let name): name
        case .library(let name): name
        case .huggingface: "Hugging Face cache"
        case .store: "Perch store"
        case .unknown: "Unknown"
        }
    }
}
