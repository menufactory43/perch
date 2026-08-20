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
        remember(name: source.lastPathComponent, fingerprint: fingerprint)
        if contains(fingerprint) {
            return .apfsClone
        }
        return try cloner.clone(from: source, to: dest)
    }

    public func remember(name: String, fingerprint: Fingerprint) {
        let key = Self.aliasKey(name)
        guard !key.isEmpty else { return }
        try? fileManager.createDirectory(at: paths.aliasesRoot, withIntermediateDirectories: true)
        try? Data(fingerprint.rawValue.utf8).write(to: paths.aliasesRoot.appending(path: key), options: .atomic)
    }

    public func resolve(name: String) -> URL? {
        if let fingerprint = Fingerprint(rawValue: name), contains(fingerprint) {
            return url(for: fingerprint)
        }
        let key = Self.aliasKey(name)
        guard !key.isEmpty else { return nil }
        let alias = paths.aliasesRoot.appending(path: key)
        guard let hex = try? String(contentsOf: alias, encoding: .utf8) else { return nil }
        let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let fingerprint = Fingerprint(rawValue: trimmed), contains(fingerprint) else { return nil }
        return url(for: fingerprint)
    }

    public static func aliasKey(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        return trimmed
            .replacing("/", with: "--")
            .replacing(" ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "." || $0 == "-" || $0 == "_" }
    }
}
