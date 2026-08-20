import Foundation

/// Skips re-hashing a package whose path, size, and mtime have not changed.
public struct HashCache: Sendable, Codable {
    public struct Entry: Sendable, Codable, Equatable {
        public var fingerprint: Fingerprint
        public var logicalBytes: Int64
        public var modificationTime: Date
        public var logicalSizeAtHash: Int64
    }

    public var entries: [String: Entry]

    public init(entries: [String: Entry] = [:]) {
        self.entries = entries
    }

    public static func load(from url: URL) -> HashCache {
        guard let data = try? Data(contentsOf: url) else {
            return HashCache()
        }
        return (try? JSONDecoder().decode(HashCache.self, from: data)) ?? HashCache()
    }

    public func save(to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(self)
        try data.write(to: url, options: [.atomic])
    }

    public func hit(path: String, modificationTime: Date, logicalBytes: Int64) -> Entry? {
        guard let entry = entries[path] else { return nil }
        let delta = abs(entry.modificationTime.timeIntervalSince(modificationTime))
        if delta < 1, entry.logicalSizeAtHash == logicalBytes {
            return entry
        }
        return nil
    }

    public mutating func record(path: String, fingerprint: Fingerprint, logicalBytes: Int64, modificationTime: Date) {
        entries[path] = Entry(
            fingerprint: fingerprint,
            logicalBytes: logicalBytes,
            modificationTime: modificationTime,
            logicalSizeAtHash: logicalBytes
        )
    }
}
