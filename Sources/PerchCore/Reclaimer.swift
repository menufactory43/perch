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

    public func execute(_ plan: ReclaimPlan, progress: (@Sendable (WorkProgress) -> Void)? = nil) throws -> ReclaimResult {
        var cloned = 0
        var copied = 0
        var failed: [String] = []
        var reclaimed: Int64 = 0
        let total = plan.ingests.count + plan.pushes.count + plan.replacements.count
        var step = 0

        func tick(_ detail: String) {
            progress?(WorkProgress(completed: step, total: max(total, 1), detail: detail))
            step += 1
        }

        for ingest in plan.ingests {
            tick("Storing \(ingest.source.lastPathComponent)")
            do {
                let kind = try store.ingest(from: ingest.source, fingerprint: ingest.fingerprint)
                tally(kind, cloned: &cloned, copied: &copied)
            } catch {
                failed.append(ingest.source.path + ": \(error.localizedDescription)")
            }
        }

        var pushed = 0

        for push in plan.pushes {
            tick("Filling \(push.fileName)")
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
            tick("Linking \(replacement.destination.lastPathComponent)")
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
