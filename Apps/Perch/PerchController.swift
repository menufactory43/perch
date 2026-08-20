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
    var pendingDelete: PackageGroup?
    var isDeleting = false
    var progressFraction: Double?

    var watchEnabled: Bool {
        didSet {
            UserDefaults.standard.set(watchEnabled, forKey: "watchEnabled")
            restartWatch()
        }
    }

    private var session: PerchSession?
    @ObservationIgnored private var watchTask: Task<Void, Never>?
    @ObservationIgnored private var folderWatch: FolderWatch?

    init() {
        watchEnabled = UserDefaults.standard.bool(forKey: "watchEnabled")
        session = try? PerchSession()
        folderWatch = FolderWatch { [weak self] in
            Task { @MainActor in
                self?.maintain()
            }
        }
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
            pushes: [
                PlannedPush(
                    fingerprint: fingerprint,
                    destination: URL(fileURLWithPath: "/tmp/NewApp/parakeet.mlmodelc"),
                    fileName: "parakeet.mlmodelc"
                ),
            ],
            reclaimableBytes: 1_200_000_000
        )
        return controller
    }

    var reclaimableBytes: Int64 { plan?.reclaimableBytes ?? 0 }
    var totalBytes: Int64 { report?.totalLogicalBytes ?? 0 }
    var uniqueCount: Int { report?.uniquePackageCount ?? 0 }
    var pushCount: Int { plan?.pushes.count ?? 0 }
    var canReclaim: Bool { (plan?.isEmpty == false) && !isReclaiming && !isScanning }

    var primaryActionTitle: String {
        let hasReclaim = reclaimableBytes > 0
        let hasPush = pushCount > 0
        if hasReclaim && hasPush { return String(localized: "Reclaim & Fill") }
        if hasPush { return String(localized: "Fill Apps") }
        return String(localized: "Reclaim Space")
    }

    func refreshAccess() {
        hasFullDiskAccess = FullDiskAccess.isGranted()
    }

    func openFullDiskAccessSettings() {
        revealAppInFinder()
        openFullDiskAccessPane()
        refreshAccess()
    }

    func revealAppInFinder() {
        let preferred = URL(fileURLWithPath: "/Applications/Perch.app")
        let url = FileManager.default.fileExists(atPath: preferred.path) ? preferred : Bundle.main.bundleURL
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private func openFullDiskAccessPane() {
        for url in FullDiskAccess.paneURLs {
            if NSWorkspace.shared.open(url) { return }
        }
    }

    func scan() {
        runScan(autoApply: false)
    }

    func maintain() {
        guard watchEnabled, hasFullDiskAccess else { return }
        runScan(autoApply: true)
    }

    func requestReclaim() {
        showReclaimConfirmation = true
    }

    func confirmReclaim() {
        showReclaimConfirmation = false
        guard let plan, !isReclaiming else { return }
        execute(plan)
    }

    func requestDelete(_ group: PackageGroup) {
        pendingDelete = group
        showReclaimConfirmation = false
    }

    func cancelDelete() {
        pendingDelete = nil
    }

    func confirmDelete() {
        guard let group = pendingDelete, let report, !isDeleting, !isReclaiming else { return }
        pendingDelete = nil
        isDeleting = true
        lastError = nil
        statusMessage = String(localized: "Deleting…")
        let fingerprint = group.fingerprint
        let snapshot = report
        var current = report
        current.placements.removeAll { $0.fingerprint == fingerprint }
        self.report = current
        if let session {
            plan = session.plan(from: current)
        }
        Task {
            do {
                let session = try currentSession()
                let removal = try await Task.detached(priority: .userInitiated) {
                    let plan = session.removalPlan(for: fingerprint, report: snapshot)
                    try session.remove(plan)
                    return plan
                }.value
                if removal.roots.isEmpty {
                    lastError = String(localized: "Nothing was deleted. The path is outside Perch’s allowed folders.")
                }
            } catch {
                lastError = error.localizedDescription
            }
            isDeleting = false
            statusMessage = nil
            runScan(autoApply: false)
        }
    }

    func openPerchSettings() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        let settings = Selector(("showSettingsWindow:"))
        let preferences = Selector(("showPreferencesWindow:"))
        if NSApp.responds(to: settings) {
            NSApp.sendAction(settings, to: nil, from: nil)
        } else {
            NSApp.sendAction(preferences, to: nil, from: nil)
        }
    }

    func resignToMenuBar() {
        NSApp.setActivationPolicy(.accessory)
    }

    func revealStore() {
        guard let session else { return }
        try? FileManager.default.createDirectory(at: session.paths.storeRoot, withIntermediateDirectories: true)
        NSWorkspace.shared.open(session.paths.storeRoot)
    }

    func quit() {
        watchTask?.cancel()
        folderWatch?.stop()
        NSApp.terminate(nil)
    }

    private func runScan(autoApply: Bool) {
        guard !isScanning, !isReclaiming, !isDeleting else { return }
        refreshAccess()
        isScanning = true
        lastError = nil
        statusMessage = String(localized: "Scanning…")

        Task {
            defer {
                isScanning = false
                statusMessage = nil
                progressFraction = nil
            }
            do {
                let session = try currentSession()
                let (stream, continuation) = AsyncStream<WorkProgress>.makeStream()
                let work = Task.detached(priority: .userInitiated) {
                    defer { continuation.finish() }
                    return try session.scan { continuation.yield($0) }
                }
                for await progress in stream {
                    statusMessage = progress.detail
                    progressFraction = progress.fraction
                }
                let report = try await work.value
                progressFraction = nil
                let plan = session.plan(from: report)
                self.report = report
                self.plan = plan
                updateFolderWatch()
                if autoApply, watchEnabled {
                    let reclaimOnly = ReclaimPlan(
                        ingests: plan.ingests,
                        replacements: plan.replacements,
                        pushes: [],
                        reclaimableBytes: plan.reclaimableBytes
                    )
                    if !reclaimOnly.isEmpty {
                        execute(reclaimOnly)
                    }
                }
            } catch {
                lastError = error.localizedDescription
            }
        }
    }

    private func execute(_ plan: ReclaimPlan) {
        guard !isReclaiming else { return }
        isReclaiming = true
        lastError = nil
        statusMessage = String(localized: "Updating copies…")

        Task {
            do {
                let session = try currentSession()
                let snapshot = plan
                let (stream, continuation) = AsyncStream<WorkProgress>.makeStream()
                let work = Task.detached(priority: .userInitiated) {
                    defer { continuation.finish() }
                    return try session.reclaim(snapshot) { continuation.yield($0) }
                }
                for await progress in stream {
                    statusMessage = progress.detail
                    progressFraction = progress.fraction
                }
                let result = try await work.value
                progressFraction = nil
                lastResult = result
                if let first = result.failed.first {
                    lastError = first
                }
            } catch {
                lastError = error.localizedDescription
            }
            isReclaiming = false
            statusMessage = nil
            runScan(autoApply: false)
        }
    }

    private func restartWatch() {
        watchTask?.cancel()
        if watchEnabled, hasFullDiskAccess {
            updateFolderWatch()
            watchTask = Task { [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(300))
                    self?.maintain()
                }
            }
        } else {
            folderWatch?.stop()
        }
    }

    private func updateFolderWatch() {
        guard watchEnabled, hasFullDiskAccess else {
            folderWatch?.stop()
            return
        }
        let paths = report?.scannedRoots.map(\.path) ?? []
        folderWatch?.start(paths: paths)
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
