import Foundation
import Testing
@testable import PerchCore

struct ClonerTests {
    @Test func cloneSharesThenIndependentDelete() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "perch-clone-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let source = root.appending(path: "source.bin")
        let payload = Data(repeating: 7, count: 256_000)
        try payload.write(to: source)

        let dest = root.appending(path: "dest.bin")
        let kind = try Cloner().clone(from: source, to: dest)
        #expect(kind == .apfsClone)
        #expect(try Data(contentsOf: dest) == payload)

        try FileManager.default.removeItem(at: dest)
        #expect(try Data(contentsOf: source) == payload)
    }

    @Test func replaceLeavesSiblingIntact() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "perch-replace-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let storeCopy = root.appending(path: "store.bin")
        let appCopy = root.appending(path: "app.bin")
        try Data("canonical".utf8).write(to: storeCopy)
        try Data("duplicate".utf8).write(to: appCopy)

        _ = try Cloner().replace(appCopy, withCloneOf: storeCopy)
        #expect(try String(contentsOf: appCopy, encoding: .utf8) == "canonical")
        #expect(try String(contentsOf: storeCopy, encoding: .utf8) == "canonical")
    }
}
