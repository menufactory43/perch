import Foundation
import Testing
@testable import PerchCore

struct ModelPackageTests {
    @Test func coreMLExtensionIsAPackage() {
        let url = URL(fileURLWithPath: "/tmp/parakeet-tdt-0.6b-v3-coreml.mlmodelc")
        #expect(ModelPackage.isPackage(at: url, values: nil, fileManager: .default))
        #expect(ModelPackage.inferredKind(for: url) == .stt)
    }

    @Test func kokoroIsTTS() {
        let url = URL(fileURLWithPath: "/tmp/kokoro-82m-coreml.mlpackage")
        #expect(ModelPackage.inferredKind(for: url) == .tts)
    }

    @Test func discoversMlmodelcInTree() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "perch-discover-\(UUID().uuidString)")
        let package = root.appending(path: "parakeet-tdt-0.6b-v3-coreml.mlmodelc")
        try FileManager.default.createDirectory(at: package, withIntermediateDirectories: true)
        try Data("coreml".utf8).write(to: package.appending(path: "coremldata.bin"))
        defer { try? FileManager.default.removeItem(at: root) }

        let found = ModelPackage.discover(in: root)
        #expect(found.map(\.lastPathComponent) == ["parakeet-tdt-0.6b-v3-coreml.mlmodelc"])
    }

    @Test func snapshotsFolderIsNotAPackage() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "snapshots", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: url) }
        #expect(ModelPackage.isPackage(at: url) == false)
    }
}
