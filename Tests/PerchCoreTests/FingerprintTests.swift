import Foundation
import Testing
@testable import PerchCore

struct FingerprintTests {
    @Test func rejectsNonHex() {
        #expect(Fingerprint(rawValue: "nope") == nil)
        #expect(Fingerprint(rawValue: String(repeating: "g", count: 64)) == nil)
        #expect(Fingerprint(rawValue: String(repeating: "a", count: 63)) == nil)
    }

    @Test func acceptsSHA256Hex() {
        let hex = String(repeating: "ab", count: 32)
        let fingerprint = Fingerprint(rawValue: hex)
        #expect(fingerprint?.rawValue == hex)
    }

    @Test func fileHashIsStable() throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: "perch-hash-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let file = dir.appending(path: "weights.bin")
        try Data("parakeet-weights".utf8).write(to: file)

        let fingerprinter = Fingerprinter()
        let first = try fingerprinter.fingerprint(at: file)
        let second = try fingerprinter.fingerprint(at: file)
        #expect(first.0 == second.0)
        #expect(first.1 == 16)
    }

    @Test func directoryHashChangesWhenFileChanges() throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: "perch-tree-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let file = dir.appending(path: "model.safetensors")
        try Data("one".utf8).write(to: file)
        let fingerprinter = Fingerprinter()
        let before = try fingerprinter.fingerprint(at: dir)

        try Data("two".utf8).write(to: file)
        let after = try fingerprinter.fingerprint(at: dir)
        #expect(before.0 != after.0)
    }

    @Test func relativePathStripsOnlyTheLeadingRoot() {
        let root = URL(fileURLWithPath: "/tmp/Models")
        let nested = URL(fileURLWithPath: "/tmp/Models/enc/Models/weights.onnx")
        #expect(Fingerprinter.relativePath(of: nested, under: root) == "enc/Models/weights.onnx")
    }
}
