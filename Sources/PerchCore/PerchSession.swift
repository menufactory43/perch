import Foundation

/// The thing an app or CLI talks to. Scan, plan, reclaim.
public struct PerchSession: @unchecked Sendable {
    public var paths: PerchPaths
    public var catalog: Catalog
    public var scanner: Scanner
    public var store: PackageStore
    public var planner: ReclaimPlanner
    public var reclaimer: Reclaimer
    public var remover: ModelRemover

    public init(paths: PerchPaths = .resolve(), catalog: Catalog? = nil) throws {
        let loaded = try catalog ?? CatalogLoader.bundled()
        let store = PackageStore(paths: paths)
        self.paths = paths
        self.catalog = loaded
        self.scanner = Scanner(catalog: loaded, paths: paths, store: store)
        self.store = store
        self.planner = ReclaimPlanner(store: store, catalog: loaded, expander: PathExpander.default())
        self.reclaimer = Reclaimer(store: store)
        self.remover = ModelRemover(store: store)
    }

    public func scan(progress: (@Sendable (WorkProgress) -> Void)? = nil) throws -> ScanReport {
        try scanner.scan(progress: progress)
    }

    public func resolve(name: String) -> URL? {
        store.resolve(name: name)
    }

    public func plan(from report: ScanReport) -> ReclaimPlan {
        planner.plan(from: report)
    }

    public func reclaim(_ plan: ReclaimPlan, progress: (@Sendable (WorkProgress) -> Void)? = nil) throws -> ReclaimResult {
        try reclaimer.execute(plan, progress: progress)
    }

    public func removalPlan(for fingerprint: Fingerprint, report: ScanReport) -> RemovalPlan {
        remover.plan(fingerprint: fingerprint, placements: report.placements)
    }

    public func remove(_ plan: RemovalPlan) throws {
        try remover.execute(plan)
    }
}
