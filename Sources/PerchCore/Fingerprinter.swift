import CryptoKit
import Foundation

public struct Fingerprinter: @unchecked Sendable {
    public var fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func fingerprint(at url: URL) throws -> (Fingerprint, Int64) {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            throw FingerprintError.missing(url)
        }

        if isDirectory.boolValue {
            return try fingerprintDirectory(url)
        }
        return try fingerprintFile(url)
    }

    private func fingerprintFile(_ url: URL) throws -> (Fingerprint, Int64) {
        let digest = try hashFile(url)
        let size = try fileSize(url)
        return (Fingerprint(hex: hex(digest)), size)
    }

    private func fingerprintDirectory(_ url: URL) throws -> (Fingerprint, Int64) {
        let files = try collectFiles(in: url)
        var hasher = SHA256()
        var total: Int64 = 0
        for file in files {
            let relative = file.path.replacing(url.path, with: "").trimmingPrefix("/")
            let digest = try hashFile(file)
            let size = try fileSize(file)
            total += size
            let line = "\(relative)\t\(size)\t\(hex(digest))\n"
            hasher.update(data: Data(line.utf8))
        }
        return (Fingerprint(hex: hex(hasher.finalize())), total)
    }

    private func collectFiles(in directory: URL) throws -> [URL] {
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var files: [URL] = []
        for case let file as URL in enumerator {
            let values = try file.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .isDirectoryKey])
            if values.isDirectory == true { continue }
            if values.isRegularFile == true || values.isSymbolicLink == true {
                files.append(file)
            }
        }
        return files.sorted { $0.path < $1.path }
    }

    private func hashFile(_ url: URL) throws -> SHA256.Digest {
        let handle = try FileHandle(forReadingFrom: url.resolvingSymlinksInPath())
        defer { try? handle.close() }
        var hasher = SHA256()
        while true {
            let chunk = try handle.read(upToCount: 1_048_576) ?? Data()
            if chunk.isEmpty { break }
            hasher.update(data: chunk)
        }
        return hasher.finalize()
    }

    private func fileSize(_ url: URL) throws -> Int64 {
        let values = try url.resolvingSymlinksInPath().resourceValues(forKeys: [.fileSizeKey])
        return Int64(values.fileSize ?? 0)
    }

    private func hex(_ digest: SHA256.Digest) -> String {
        digest.map { String(format: "%02x", $0) }.joined()
    }
}

public enum FingerprintError: Error, Sendable {
    case missing(URL)
}
