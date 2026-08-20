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
        #expect(plan.pushes.isEmpty)
        #expect(plan.reclaimableBytes == 0)
    }

    @Test func missingBinGetsAPush() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "perch-push-\(UUID().uuidString)")
        let dictus = root.appending(path: "Dictus/Models", directoryHint: .isDirectory)
        let fluid = root.appending(path: "FluidVoice/Models", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: dictus, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: fluid, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let package = dictus.appending(path: "parakeet-tdt-0.6b-v3-coreml")
        try FileManager.default.createDirectory(at: package, withIntermediateDirectories: true)
        try Data(repeating: 1, count: 32).write(to: package.appending(path: "weights.bin"))

        let fingerprint = Fingerprint(hex: String(repeating: "44", count: 32))
        let catalog = Catalog(
            version: 0,
            apps: [
                CatalogApp(
                    id: "fluidvoice",
                    name: "FluidVoice",
                    kind: .app,
                    roots: [fluid.path]
                ),
            ]
        )
        let planner = ReclaimPlanner(
            store: PackageStore(paths: PerchPaths(home: root.appending(path: "perch"))),
            catalog: catalog,
            expander: PathExpander(
                home: root,
                containersRoot: root.appending(path: "Containers")
            )
        )
        let placement = Placement(
            url: package,
            fingerprint: fingerprint,
            logicalBytes: 32,
            source: .app(id: "dictus", name: "Dictus"),
            kind: .stt,
            displayName: "parakeet-tdt-0.6b-v3-coreml"
        )
        let plan = planner.plan(from: ScanReport(scannedRoots: [dictus], placements: [placement]))
        #expect(plan.pushes.count == 1)
        #expect(plan.pushes[0].destination.lastPathComponent == "parakeet-tdt-0.6b-v3-coreml")
        #expect(plan.pushes[0].destination.deletingLastPathComponent().path == fluid.path)
    }

    @Test func existingDestinationIsNotPushed() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "perch-push-skip-\(UUID().uuidString)")
        let dictus = root.appending(path: "Dictus/Models", directoryHint: .isDirectory)
        let fluid = root.appending(path: "FluidVoice/Models", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: dictus, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: fluid, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let name = "parakeet-tdt-0.6b-v3-coreml"
        try FileManager.default.createDirectory(at: dictus.appending(path: name), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: fluid.appending(path: name), withIntermediateDirectories: true)

        let fingerprint = Fingerprint(hex: String(repeating: "55", count: 32))
        let other = Fingerprint(hex: String(repeating: "66", count: 32))
        let planner = ReclaimPlanner(
            store: PackageStore(paths: PerchPaths(home: root.appending(path: "perch"))),
            catalog: Catalog(
                version: 0,
                apps: [CatalogApp(id: "fluidvoice", name: "FluidVoice", kind: .app, roots: [fluid.path])]
            ),
            expander: PathExpander(home: root, containersRoot: root.appending(path: "Containers"))
        )
        let placements = [
            Placement(
                url: dictus.appending(path: name),
                fingerprint: fingerprint,
                logicalBytes: 10,
                source: .app(id: "dictus", name: "Dictus"),
                kind: .stt,
                displayName: name
            ),
            Placement(
                url: fluid.appending(path: name),
                fingerprint: other,
                logicalBytes: 10,
                source: .app(id: "fluidvoice", name: "FluidVoice"),
                kind: .stt,
                displayName: name
            ),
        ]
        let plan = planner.plan(from: ScanReport(scannedRoots: [], placements: placements))
        #expect(plan.pushes.isEmpty)
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
