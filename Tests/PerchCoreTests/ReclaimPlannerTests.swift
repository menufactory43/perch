import Foundation
import Testing
@testable import PerchCore

struct ReclaimPlannerTests {
    @Test func threeCopiesYieldTwoReplacements() throws {
        let home = FileManager.default.temporaryDirectory.appending(path: "perch-plan-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: home) }

        let paths = PerchPaths(home: home)
        let store = PackageStore(paths: paths)
        let planner = ReclaimPlanner(store: store)
        let fingerprint = Fingerprint(hex: String(repeating: "11", count: 32))

        let a = URL(fileURLWithPath: "/tmp/Dictus/parakeet.mlmodelc")
        let b = URL(fileURLWithPath: "/tmp/FluidVoice/parakeet.mlmodelc")
        let c = URL(fileURLWithPath: "/tmp/MacParakeet/parakeet.mlmodelc")

        let placements = [a, b, c].map { url in
            Placement(
                url: url,
                fingerprint: fingerprint,
                logicalBytes: 1_200_000_000,
                source: .app(id: url.path, name: url.deletingLastPathComponent().lastPathComponent),
                kind: .stt,
                displayName: "parakeet.mlmodelc"
            )
        }

        let report = ScanReport(scannedRoots: [], placements: placements)
        let plan = planner.plan(from: report)

        #expect(plan.ingests.count == 1)
        #expect(plan.replacements.count == 2)
        #expect(plan.reclaimableBytes == 2_400_000_000)
    }

    @Test func uniquePackageIsIngestedWithNoReclaim() throws {
        let home = FileManager.default.temporaryDirectory.appending(path: "perch-plan-one-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: home) }

        let store = PackageStore(paths: PerchPaths(home: home))
        let planner = ReclaimPlanner(store: store)
        let fingerprint = Fingerprint(hex: String(repeating: "22", count: 32))
        let placement = Placement(
            url: URL(fileURLWithPath: "/tmp/only/parakeet.mlmodelc"),
            fingerprint: fingerprint,
            logicalBytes: 100,
            source: .library(name: "FluidAudio"),
            kind: .stt,
            displayName: "parakeet.mlmodelc"
        )
        let plan = planner.plan(from: ScanReport(scannedRoots: [], placements: [placement]))
        #expect(plan.ingests.count == 1)
        #expect(plan.replacements.isEmpty)
        #expect(plan.reclaimableBytes == 0)
    }

    @Test func storeCopiesAreNotReplaced() throws {
        let home = FileManager.default.temporaryDirectory.appending(path: "perch-plan-store-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: home) }

        let paths = PerchPaths(home: home)
        let store = PackageStore(paths: paths)
        let fingerprint = Fingerprint(hex: String(repeating: "33", count: 32))
        try FileManager.default.createDirectory(at: store.url(for: fingerprint), withIntermediateDirectories: true)

        let planner = ReclaimPlanner(store: store)
        let placements = [
            Placement(
                url: store.url(for: fingerprint),
                fingerprint: fingerprint,
                logicalBytes: 50,
                source: .store,
                kind: .stt,
                displayName: "parakeet"
            ),
            Placement(
                url: URL(fileURLWithPath: "/tmp/app/parakeet"),
                fingerprint: fingerprint,
                logicalBytes: 50,
                source: .app(id: "x", name: "App"),
                kind: .stt,
                displayName: "parakeet"
            ),
        ]
        let plan = planner.plan(from: ScanReport(scannedRoots: [], placements: placements))
        #expect(plan.ingests.isEmpty)
        #expect(plan.replacements.isEmpty)
        #expect(plan.reclaimableBytes == 0)
    }
}
