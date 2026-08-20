import Foundation
import Testing
@testable import PerchCore

struct ModelPackageTests {
    @Test func coreMLExtensionIsAPackage() {
        let url = URL(fileURLWithPath: "/tmp/parakeet-tdt-0.6b-v3-coreml.mlmodelc")
        #expect(ModelPackage.isPackage(at: url, values: nil, fileManager: .default))
        #expect(ModelPackage.inferredKind(for: url) == .stt)
    }

    @Test func huggingFaceSnapshotDisplayName() {
        let url = URL(
            fileURLWithPath: "/Users/x/.cache/huggingface/hub/models--mlx-community--whisper-base-mlx/snapshots/1e3e249fb8d01c655324bd6841b1deadffd6d04c",
            isDirectory: true
        )
        #expect(ModelPackage.displayName(for: url) == "mlx-community/whisper-base-mlx")
    }

    @Test func kokoroIsTTS() {
        let url = URL(fileURLWithPath: "/tmp/kokoro-82m-coreml.mlpackage")
        #expect(ModelPackage.inferredKind(for: url) == .tts)
    }

    @Test func gemmaGgufIsLLM() {
        let url = URL(fileURLWithPath: "/tmp/gemma-3-1b.i1-Q5_K_M.gguf")
        #expect(ModelPackage.inferredKind(for: url) == .llm)
    }

    @Test func largeGgufFileIsAPackage() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "gemma-\(UUID().uuidString).gguf")
        try Data(repeating: 3, count: 2_000_000).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        #expect(ModelPackage.isPackage(at: url))
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
