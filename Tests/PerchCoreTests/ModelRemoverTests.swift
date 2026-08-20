import Foundation
import Testing
@testable import PerchCore

struct ModelRemoverTests {
    @Test func deletesEveryCopyAndStore() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "perch-rm-\(UUID().uuidString)")
        let a = root.appending(path: "A")
        let b = root.appending(path: "B")
        try FileManager.default.createDirectory(at: a, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: b, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let fileA = a.appending(path: "gemma.gguf")
        let fileB = b.appending(path: "gemma.gguf")
        try Data("weights".utf8).write(to: fileA)
        try Data("weights".utf8).write(to: fileB)

        let fingerprint = Fingerprint(hex: String(repeating: "99", count: 32))
        let paths = PerchPaths(home: root.appending(path: "perch"))
        let store = PackageStore(paths: paths)
        try store.ingest(from: fileA, fingerprint: fingerprint)

        let placements = [
            Placement(
                url: fileA,
                fingerprint: fingerprint,
                logicalBytes: 7,
                source: .app(id: "a", name: "A"),
                kind: .llm,
                displayName: "gemma.gguf"
            ),
            Placement(
                url: fileB,
                fingerprint: fingerprint,
                logicalBytes: 7,
                source: .app(id: "b", name: "B"),
                kind: .llm,
                displayName: "gemma.gguf"
            ),
        ]
        let remover = ModelRemover(store: store)
        let plan = remover.plan(fingerprint: fingerprint, placements: placements)
        try remover.execute(plan)

        #expect(FileManager.default.fileExists(atPath: fileA.path) == false)
        #expect(FileManager.default.fileExists(atPath: fileB.path) == false)
        #expect(store.contains(fingerprint) == false)
    }

    @Test func huggingFaceRootIsTheRepoFolder() {
        let snapshot = URL(
            fileURLWithPath: "/Users/x/.cache/huggingface/hub/models--hexgrad--Kokoro-82M/snapshots/abc",
            isDirectory: true
        )
        #expect(
            ModelRemover.deletionRoot(for: snapshot).lastPathComponent == "models--hexgrad--Kokoro-82M"
        )
    }
}
