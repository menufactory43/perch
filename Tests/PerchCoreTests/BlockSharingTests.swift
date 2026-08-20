import Foundation
import Testing
@testable import PerchCore

struct BlockSharingTests {
    @Test func cloneSharesPhysicalBlocks() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "perch-share-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let source = root.appending(path: "a.bin")
        try Data(repeating: 9, count: 128_000).write(to: source)
        let dest = root.appending(path: "b.bin")
        _ = try Cloner().clone(from: source, to: dest)

        #expect(BlockSharing.sharesStorage(source, dest))
    }

    @Test func independentCopyDoesNotShare() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "perch-noshare-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let source = root.appending(path: "a.bin")
        let dest = root.appending(path: "b.bin")
        let payload = Data(repeating: 9, count: 128_000)
        try payload.write(to: source)
        try payload.write(to: dest)

        #expect(BlockSharing.sharesStorage(source, dest) == false)
    }
}
