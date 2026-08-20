import Foundation

public struct RemovalPlan: Sendable, Equatable {
    public var fingerprint: Fingerprint
    public var roots: [URL]
    public var logicalBytes: Int64

    public init(fingerprint: Fingerprint, roots: [URL], logicalBytes: Int64) {
        self.fingerprint = fingerprint
        self.roots = roots
        self.logicalBytes = logicalBytes
    }
}

public struct ModelRemover: @unchecked Sendable {
    public var store: PackageStore
    public var fileManager: FileManager

    public init(store: PackageStore, fileManager: FileManager = .default) {
        self.store = store
        self.fileManager = fileManager
    }

    public func plan(fingerprint: Fingerprint, placements: [Placement]) -> RemovalPlan {
        var roots: [URL] = []
        var seen = Set<String>()
        var bytes: Int64 = 0

        func add(_ url: URL, size: Int64) {
            let root = Self.deletionRoot(for: url)
            let path = root.standardizedFileURL.path
            guard seen.insert(path).inserted else { return }
            guard isSafeToDelete(root) else { return }
            roots.append(root)
            bytes += size
        }

        for placement in placements where placement.fingerprint == fingerprint {
            add(placement.url, size: placement.logicalBytes)
        }
        let stored = store.url(for: fingerprint)
        if store.contains(fingerprint) {
            add(stored, size: 0)
        }
        roots.sort { $0.path < $1.path }
        return RemovalPlan(fingerprint: fingerprint, roots: roots, logicalBytes: bytes)
    }

    public func execute(_ plan: RemovalPlan) throws {
        var firstError: Error?
        for root in plan.roots {
            guard isSafeToDelete(root) else { continue }
            do {
                if fileManager.fileExists(atPath: root.path) {
                    try fileManager.removeItem(at: root)
                }
            } catch {
                if firstError == nil { firstError = error }
            }
        }
        if let firstError {
            throw firstError
        }
    }

    public static func deletionRoot(for url: URL) -> URL {
        var current = url.standardizedFileURL
        while current.path.contains("huggingface") {
            if current.lastPathComponent.hasPrefix("models--") {
                return current
            }
            let parent = current.deletingLastPathComponent()
            if parent.path == current.path { break }
            current = parent
        }
        return url.standardizedFileURL
    }

    private func isSafeToDelete(_ url: URL) -> Bool {
        let path = url.standardizedFileURL.path
        guard !path.isEmpty, path != "/" else { return false }
        let home = fileManager.homeDirectoryForCurrentUser.path
        let allowedPrefixes = [
            home + "/Library/Application Support",
            home + "/Library/Caches",
            home + "/Library/Containers",
            home + "/.cache",
            store.paths.home.path,
            fileManager.temporaryDirectory.path,
        ]
        return allowedPrefixes.contains { path.hasPrefix($0) }
    }
}
