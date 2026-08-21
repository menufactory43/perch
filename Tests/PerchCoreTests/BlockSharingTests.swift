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

    @Test func clonedTreeWithEmptySubdirStillShares() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "perch-share-tree-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let source = root.appending(path: "src")
        try FileManager.default.createDirectory(at: source.appending(path: "weights"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: source.appending(path: "empty"), withIntermediateDirectories: true)
        try Data(repeating: 3, count: 64_000).write(to: source.appending(path: "weights/a.bin"))
        let junk = source.appending(path: "junk")
        try FileManager.default.createDirectory(at: junk, withIntermediateDirectories: true)
        try Data("ds".utf8).write(to: junk.appending(path: ".DS_Store"))

        let dest = root.appending(path: "dst")
        _ = try Cloner().clone(from: source, to: dest)
        #expect(BlockSharing.sharesStorage(source, dest))
    }

    @Test func unsharedSiblingPreventsDirectoryShare() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "perch-share-sib-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let source = root.appending(path: "src")
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try Data(repeating: 3, count: 64_000).write(to: source.appending(path: "big.bin"))
        try Data(repeating: 4, count: 8_000).write(to: source.appending(path: "small.bin"))

        let dest = root.appending(path: "dst")
        _ = try Cloner().clone(from: source, to: dest)
        try Data(repeating: 4, count: 8_000).write(to: dest.appending(path: "small.bin"))
        #expect(BlockSharing.sharesStorage(source, dest) == false)
    }
}
