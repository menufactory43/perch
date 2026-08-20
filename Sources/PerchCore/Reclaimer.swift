import Foundation

public struct Reclaimer: @unchecked Sendable {
    public var store: PackageStore
    public var cloner: Cloner
    public var fileManager: FileManager

    public init(store: PackageStore, cloner: Cloner = Cloner(), fileManager: FileManager = .default) {
        self.store = store
        self.cloner = cloner
        self.fileManager = fileManager
    }

    public func execute(_ plan: ReclaimPlan, progress: (@Sendable (String) -> Void)? = nil) throws -> ReclaimResult {
        var cloned = 0
        var copied = 0
        var failed: [String] = []
        var reclaimed: Int64 = 0

        for ingest in plan.ingests {
            progress?("Storing \(ingest.source.lastPathComponent)")
            do {
                let kind = try store.ingest(from: ingest.source, fingerprint: ingest.fingerprint)
                tally(kind, cloned: &cloned, copied: &copied)
            } catch {
                failed.append(ingest.source.path + ": \(error.localizedDescription)")
            }
        }

        var pushed = 0

        for push in plan.pushes {
            progress?("Filling \(push.destination.path)")
            let source = store.url(for: push.fingerprint)
            guard store.contains(push.fingerprint) else {
                failed.append(push.destination.path + ": missing package in store")
                continue
            }
            if fileManager.fileExists(atPath: push.destination.path) {
                continue
            }
            do {
                try fileManager.createDirectory(
                    at: push.destination.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                let kind = try cloner.clone(from: source, to: push.destination)
                tally(kind, cloned: &cloned, copied: &copied)
                pushed += 1
            } catch {
                failed.append(push.destination.path + ": \(error.localizedDescription)")
            }
        }

        for replacement in plan.replacements {
            progress?("Linking \(replacement.destination.lastPathComponent)")
            let source = store.url(for: replacement.fingerprint)
            guard store.contains(replacement.fingerprint) else {
                failed.append(replacement.destination.path + ": missing package in store")
                continue
            }
            do {
                let kind = try cloner.replace(replacement.destination, withCloneOf: source)
                tally(kind, cloned: &cloned, copied: &copied)
                if kind == .apfsClone {
                    reclaimed += replacement.logicalBytes
                }
            } catch {
                failed.append(replacement.destination.path + ": \(error.localizedDescription)")
            }
        }

        return ReclaimResult(cloned: cloned, copied: copied, pushed: pushed, failed: failed, reclaimedBytes: reclaimed)
    }

    private func tally(_ kind: CloneKind, cloned: inout Int, copied: inout Int) {
        switch kind {
        case .apfsClone: cloned += 1
        case .fullCopy: copied += 1
        }
    }
}
