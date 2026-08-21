import Foundation

public struct ReclaimPlanner: @unchecked Sendable {
    public var store: PackageStore
    public var catalog: Catalog
    public var expander: PathExpander
    public var fileManager: FileManager

    public init(
        store: PackageStore,
        catalog: Catalog = Catalog(version: 0, apps: []),
        expander: PathExpander = .default(),
        fileManager: FileManager = .default
    ) {
        self.store = store
        self.catalog = catalog
        self.expander = expander
        self.fileManager = fileManager
    }

    public func plan(from report: ScanReport) -> ReclaimPlan {
        var ingests: [PlannedIngest] = []
        var replacements: [PlannedReplacement] = []
        var reclaimable: Int64 = 0

        for (fingerprint, group) in report.groups {
            let nonStore = group.filter { $0.source != .store }
            guard let canonical = nonStore.max(by: { $0.logicalBytes < $1.logicalBytes }) ?? group.first else {
                continue
            }

            if !store.contains(fingerprint) {
                ingests.append(PlannedIngest(fingerprint: fingerprint, source: canonical.url))
            }

            let duplicates = nonStore.filter { $0.url.standardizedFileURL.path != canonical.url.standardizedFileURL.path }
            let reference = store.contains(fingerprint) ? store.url(for: fingerprint) : canonical.url
            for placement in duplicates {
                if BlockSharing.sharesStorage(reference, placement.url, fileManager: fileManager) {
                    continue
                }
                replacements.append(
                    PlannedReplacement(
                        fingerprint: fingerprint,
                        destination: placement.url,
                        logicalBytes: placement.logicalBytes
                    )
                )
                reclaimable += placement.logicalBytes
            }
        }

        let pushes = plannedPushes(from: report)

        ingests.sort { $0.fingerprint.rawValue < $1.fingerprint.rawValue }
        replacements.sort { $0.destination.path < $1.destination.path }
        return ReclaimPlan(
            ingests: ingests,
            replacements: replacements,
            pushes: pushes,
            reclaimableBytes: reclaimable
        )
    }

    private func plannedPushes(from report: ScanReport) -> [PlannedPush] {
        let bins = pushableBins(from: report)
        guard !bins.isEmpty else { return [] }

        var fingerprintsInBin: [String: Set<String>] = [:]
        var kindsInBin: [String: Set<ModelKind>] = [:]
        for placement in report.placements where placement.source != .store {
            let parent = placement.url.deletingLastPathComponent().standardizedFileURL.path
            fingerprintsInBin[parent, default: []].insert(placement.fingerprint.rawValue)
            kindsInBin[parent, default: []].insert(placement.kind)
        }

        var pushes: [PlannedPush] = []
        var seenDest = Set<String>()

        for (fingerprint, group) in report.groups {
            let nonStore = group.filter { $0.source != .store && $0.source != .huggingface }
            guard let canonical = nonStore.max(by: { $0.logicalBytes < $1.logicalBytes }) else { continue }
            let fileName = canonical.url.lastPathComponent
            guard !fileName.isEmpty, fileName != "/" else { continue }

            for bin in bins {
                let binPath = bin.standardizedFileURL.path
                if fingerprintsInBin[binPath, default: []].contains(fingerprint.rawValue) {
                    continue
                }
                let kinds = kindsInBin[binPath, default: []]
                if kinds.isEmpty {
                    // Empty FluidAudio bins only accept speech kinds — "Models" is too loose.
                    guard Self.speechKinds.contains(canonical.kind) else { continue }
                    let sourceFolder = canonical.url.deletingLastPathComponent().lastPathComponent
                    guard bin.lastPathComponent == sourceFolder else { continue }
                } else if !kinds.contains(canonical.kind) {
                    continue
                }
                let destination = bin.appending(path: fileName)
                let destPath = destination.standardizedFileURL.path
                if fileManager.fileExists(atPath: destPath) { continue }
                guard seenDest.insert(destPath).inserted else { continue }
                pushes.append(
                    PlannedPush(fingerprint: fingerprint, destination: destination, fileName: fileName)
                )
            }
        }

        pushes.sort { $0.destination.path < $1.destination.path }
        return pushes
    }

    private func pushableBins(from report: ScanReport) -> [URL] {
        var bins = Set<String>()

        func consider(_ url: URL) {
            let standardized = url.standardizedFileURL
            guard isPushableBin(standardized) else { return }
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: standardized.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                return
            }
            bins.insert(standardized.path)
        }

        for placement in report.placements where placement.source != .store && placement.source != .huggingface {
            consider(placement.url.deletingLastPathComponent())
        }

        for app in catalog.apps where app.kind != .cache {
            for raw in app.roots {
                consider(expander.expand(raw))
            }
            for relative in app.containerRoots {
                expander.expandContainerRoot(relative).forEach(consider)
            }
        }

        return bins.map { URL(fileURLWithPath: $0, isDirectory: true) }
    }

    /// FluidAudio bins: stt/tts/vad/diarization, never .llm.
    static let speechKinds: Set<ModelKind> = [.stt, .tts, .vad, .diarization]

    private func isPushableBin(_ url: URL) -> Bool {
        let path = url.path
        if path.hasPrefix(store.paths.packagesRoot.path) { return false }
        if path.contains("huggingface") { return false }
        // Cross-app GGUF copies (Cotypist → Souffleuse → KeyType) look like
        // "fill" and explode logical size. Only FluidAudio folders are safe:
        // Dictus / FluidVoice already expect the same Parakeet tree.
        return path.contains("FluidAudio")
    }
}
