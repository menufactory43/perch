import Foundation
import Testing
@testable import PerchCore

struct ReclaimerPushTests {
    @Test func pushClonesIntoEmptyBin() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "perch-reclaimer-\(UUID().uuidString)")
        let sourceDir = root.appending(path: "source", directoryHint: .isDirectory)
        let destParent = root.appending(path: "dest", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: sourceDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destParent, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try Data("canonical-weights".utf8).write(to: sourceDir.appending(path: "weights.bin"))
        let fingerprint = Fingerprint(hex: String(repeating: "77", count: 32))
        let paths = PerchPaths(home: root.appending(path: "perch"))
        let store = PackageStore(paths: paths)
        try store.ingest(from: sourceDir, fingerprint: fingerprint)

        let dest = destParent.appending(path: "parakeet")
        let plan = ReclaimPlan(
            ingests: [],
            replacements: [],
            pushes: [PlannedPush(fingerprint: fingerprint, destination: dest, fileName: "parakeet")],
            reclaimableBytes: 0
        )
        let result = try Reclaimer(store: store).execute(plan)
        #expect(result.pushed == 1)
        #expect(try String(contentsOf: dest.appending(path: "weights.bin"), encoding: .utf8) == "canonical-weights")
    }
}
