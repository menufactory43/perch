import Darwin
import Foundation

public enum CloneKind: String, Sendable, Codable {
    case apfsClone
    case fullCopy
}

public struct Cloner: @unchecked Sendable {
    public var fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// Clone `source` onto `destination`. Existing destination is replaced.
    @discardableResult
    public func replace(_ destination: URL, withCloneOf source: URL) throws -> CloneKind {
        let src = source.standardizedFileURL
        let dest = destination.standardizedFileURL
        guard src.path != dest.path else { return .apfsClone }

        try fileManager.createDirectory(
            at: dest.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let staging = dest.deletingLastPathComponent()
            .appending(path: ".\(dest.lastPathComponent).perch-staging-\(UUID().uuidString)")

        let kind = try clone(from: src, to: staging)
        if fileManager.fileExists(atPath: dest.path) {
            _ = try fileManager.replaceItemAt(dest, withItemAt: staging)
        } else {
            try fileManager.moveItem(at: staging, to: dest)
        }
        return kind
    }

    public func clone(from source: URL, to destination: URL) throws -> CloneKind {
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let result = clonefile(source.path, destination.path, UInt32(CLONE_NOFOLLOW))
        if result == 0 {
            return .apfsClone
        }

        let code = errno
        if code == ENOTSUP || code == EXDEV || code == EINVAL {
            try fileManager.copyItem(at: source, to: destination)
            return .fullCopy
        }

        throw CloneError.failed(source: source, destination: destination, posix: code)
    }
}

public enum CloneError: Error, Sendable {
    case failed(source: URL, destination: URL, posix: Int32)
}

extension CloneError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .failed(let source, let destination, let posix):
            let message = String(cString: strerror(posix))
            return "Could not clone \(source.path) → \(destination.path): \(message)"
        }
    }
}
