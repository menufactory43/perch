import Foundation

/// Known speech apps and the folders they drop models into.
public struct Catalog: Sendable, Equatable, Codable {
    public var version: Int
    public var apps: [CatalogApp]

    public init(version: Int, apps: [CatalogApp]) {
        self.version = version
        self.apps = apps
    }
}

public struct CatalogApp: Sendable, Equatable, Codable, Identifiable {
    public var id: String
    public var name: String
    public var kind: CatalogKind
    public var bundleIds: [String]
    public var roots: [String]
    public var containerRoots: [String]
    public var huggingfaceGlobs: [String]

    public init(
        id: String,
        name: String,
        kind: CatalogKind,
        bundleIds: [String] = [],
        roots: [String] = [],
        containerRoots: [String] = [],
        huggingfaceGlobs: [String] = []
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.bundleIds = bundleIds
        self.roots = roots
        self.containerRoots = containerRoots
        self.huggingfaceGlobs = huggingfaceGlobs
    }
}

public enum CatalogKind: String, Sendable, Codable, Equatable {
    case app
    case library
    case cache
}
