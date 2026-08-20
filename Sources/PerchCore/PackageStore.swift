import Foundation

public struct PackageStore: @unchecked Sendable {
    public var paths: PerchPaths
    public var cloner: Cloner
    public var fileManager: FileManager

    public init(paths: PerchPaths = .resolve(), cloner: Cloner = Cloner(), fileManager: FileManager = .default) {
        self.paths = paths
        self.cloner = cloner
        self.fileManager = fileManager
    }

    public func url(for fingerprint: Fingerprint) -> URL {
        paths.packageURL(for: fingerprint)
    }

    public func contains(_ fingerprint: Fingerprint) -> Bool {
        fileManager.fileExists(atPath: url(for: fingerprint).path)
    }

    @discardableResult
    public func ingest(from source: URL, fingerprint: Fingerprint) throws -> CloneKind {
        try fileManager.createDirectory(at: paths.packagesRoot, withIntermediateDirectories: true)
        let dest = url(for: fingerprint)
        if contains(fingerprint) {
            return .apfsClone
        }
        return try cloner.clone(from: source, to: dest)
    }
}
