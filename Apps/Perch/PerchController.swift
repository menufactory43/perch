import Foundation
import Observation
import PerchCore
import SwiftUI

@MainActor
@Observable
final class PerchController {
    var hasFullDiskAccess = FullDiskAccess.isGranted()
    var isScanning = false
    var isReclaiming = false
    var statusMessage: String?
    var lastError: String?
    var report: ScanReport?
    var plan: ReclaimPlan?
    var lastResult: ReclaimResult?
    var showReclaimConfirmation = false

    var watchEnabled: Bool {
        didSet {
            UserDefaults.standard.set(watchEnabled, forKey: "watchEnabled")
            restartWatch()
        }
    }

    private var session: PerchSession?
    @ObservationIgnored private var watchTask: Task<Void, Never>?

    init() {
        watchEnabled = UserDefaults.standard.bool(forKey: "watchEnabled")
        session = try? PerchSession()
        restartWatch()
    }

    static var preview: PerchController {
        let controller = PerchController()
        controller.hasFullDiskAccess = true
        let fingerprint = Fingerprint(hex: String(repeating: "aa", count: 32))
        controller.report = ScanReport(
            scannedRoots: [],
            placements: [
                Placement(
                    url: URL(fileURLWithPath: "/tmp/Dictus/parakeet.mlmodelc"),
                    fingerprint: fingerprint,
                    logicalBytes: 1_200_000_000,
                    source: .app(id: "dictus", name: "Dictus"),
                    kind: .stt,
                    displayName: "parakeet-tdt-0.6b-v3"
                ),
                Placement(
                    url: URL(fileURLWithPath: "/tmp/FluidVoice/parakeet.mlmodelc"),
                    fingerprint: fingerprint,
                    logicalBytes: 1_200_000_000,
                    source: .app(id: "fluidvoice", name: "FluidVoice"),
                    kind: .stt,
                    displayName: "parakeet-tdt-0.6b-v3"
                ),
            ]
        )
        controller.plan = ReclaimPlan(
            ingests: [],
            replacements: [
                PlannedReplacement(
                    fingerprint: fingerprint,
                    destination: URL(fileURLWithPath: "/tmp/FluidVoice/parakeet.mlmodelc"),
                    logicalBytes: 1_200_000_000
                ),
            ],
            reclaimableBytes: 1_200_000_000
        )
        return controller
    }

    var reclaimableBytes: Int64 { plan?.reclaimableBytes ?? 0 }
    var canReclaim: Bool { (plan?.replacements.isEmpty == false) && !isReclaiming && !isScanning }

    func refreshAccess() {
        hasFullDiskAccess = FullDiskAccess.isGranted()
    }

    func openFullDiskAccessSettings() {
        if let url = FullDiskAccess.settingsURL {
            NSWorkspace.shared.open(url)
        }
        refreshAccess()
    }

    func scan() {
        guard !isScanning else { return }
        refreshAccess()
        isScanning = true
        lastError = nil
        statusMessage = String(localized: "Scanning…")

        Task {
            defer {
                isScanning = false
                statusMessage = nil
            }
            do {
                let session = try currentSession()
                let report = try await Task.detached(priority: .userInitiated) {
                    try session.scan()
                }.value
                self.report = report
                self.plan = session.plan(from: report)
            } catch {
                lastError = error.localizedDescription
            }
        }
    }

    func requestReclaim() {
        showReclaimConfirmation = true
    }

    func confirmReclaim() {
        showReclaimConfirmation = false
        guard let plan, !isReclaiming else { return }
        isReclaiming = true
        lastError = nil
        statusMessage = String(localized: "Reclaiming space…")

        Task {
            defer {
                isReclaiming = false
                statusMessage = nil
            }
            do {
                let session = try currentSession()
                let snapshot = plan
                let result = try await Task.detached(priority: .userInitiated) {
                    try session.reclaim(snapshot)
                }.value
                lastResult = result
                if let first = result.failed.first {
                    lastError = first
                }
                scan()
            } catch {
                lastError = error.localizedDescription
            }
        }
    }

    func revealStore() {
        guard let session else { return }
        try? FileManager.default.createDirectory(at: session.paths.storeRoot, withIntermediateDirectories: true)
        NSWorkspace.shared.open(session.paths.storeRoot)
    }

    func quit() {
        watchTask?.cancel()
        NSApp.terminate(nil)
    }

    private func restartWatch() {
        watchTask?.cancel()
        guard watchEnabled else { return }
        watchTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(900))
                self?.scan()
            }
        }
    }

    private func currentSession() throws -> PerchSession {
        if let session {
            return session
        }
        let created = try PerchSession()
        session = created
        return created
    }
}
