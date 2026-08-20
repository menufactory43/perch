import Foundation
import Testing
@testable import PerchCore

struct PackageStoreTests {
    @Test func resolveByAliasName() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "perch-alias-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let source = root.appending(path: "parakeet-tdt-0.6b-v3-coreml")
        try Data("weights".utf8).write(to: source)
        let fingerprint = Fingerprint(hex: String(repeating: "ab", count: 32))
        let store = PackageStore(paths: PerchPaths(home: root.appending(path: "perch")))
        _ = try store.ingest(from: source, fingerprint: fingerprint)

        #expect(store.resolve(name: "parakeet-tdt-0.6b-v3-coreml") == store.url(for: fingerprint))
        #expect(store.resolve(name: fingerprint.rawValue) == store.url(for: fingerprint))
    }
}
