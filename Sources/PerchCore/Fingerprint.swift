import Foundation

/// SHA-256 of a model package tree (sorted relative paths + per-file hashes).
public struct Fingerprint: Hashable, Sendable, Codable, RawRepresentable, CustomStringConvertible {
    public let rawValue: String

    public init?(rawValue: String) {
        let hex = rawValue.lowercased()
        guard hex.count == 64, hex.allSatisfy(\.isHexDigit) else { return nil }
        self.rawValue = hex
    }

    public init(hex: String) {
        self.rawValue = hex.lowercased()
    }

    public var description: String { rawValue }
}
