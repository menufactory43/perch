import Foundation

/// Canonical locations on disk. Override with `PERCH_HOME`.
public struct PerchPaths: Sendable, Equatable {
    public let home: URL

    public init(home: URL) {
        self.home = home
    }

    public static func resolve(fileManager: FileManager = .default, environment: [String: String] = ProcessInfo.processInfo.environment) -> PerchPaths {
        if let override = environment["PERCH_HOME"], !override.isEmpty {
            return PerchPaths(home: URL(fileURLWithPath: override, isDirectory: true))
        }
        let support = fileManager.homeDirectoryForCurrentUser
            .appending(path: "Library/Application Support/Perch", directoryHint: .isDirectory)
        return PerchPaths(home: support)
    }

    public var storeRoot: URL {
        home.appending(path: "store", directoryHint: .isDirectory)
    }

    public var packagesRoot: URL {
        storeRoot.appending(path: "packages", directoryHint: .isDirectory)
    }

    public var hashCache: URL {
        home.appending(path: "hash-cache.json")
    }

    public var ledger: URL {
        home.appending(path: "ledger.json")
    }

    public func packageURL(for fingerprint: Fingerprint) -> URL {
        packagesRoot.appending(path: fingerprint.rawValue, directoryHint: .isDirectory)
    }
}
