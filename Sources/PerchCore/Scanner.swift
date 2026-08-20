import Foundation

public struct Scanner: @unchecked Sendable {
    public var catalog: Catalog
    public var expander: PathExpander
    public var fingerprinter: Fingerprinter
    public var paths: PerchPaths
    public var fileManager: FileManager
    public var store: PackageStore?

    public init(
        catalog: Catalog,
        expander: PathExpander = .default(),
        fingerprinter: Fingerprinter = Fingerprinter(),
        paths: PerchPaths = .resolve(),
        fileManager: FileManager = .default,
        store: PackageStore? = nil
    ) {
        self.catalog = catalog
        self.expander = expander
        self.fingerprinter = fingerprinter
        self.paths = paths
        self.fileManager = fileManager
        self.store = store
    }

    public func scan(progress: (@Sendable (WorkProgress) -> Void)? = nil) throws -> ScanReport {
        let roots = collectRoots()
        var discovered: [URL] = []
        var seen = Set<String>()
        for root in roots {
            for package in ModelPackage.discover(in: root, fileManager: fileManager) {
                let standardized = package.standardizedFileURL.path
                guard seen.insert(standardized).inserted else { continue }
                discovered.append(package)
            }
        }

        var cache = HashCache.load(from: paths.hashCache)
        var placements: [Placement] = []
        let total = discovered.count
        for (index, package) in discovered.enumerated() {
            progress?(
                WorkProgress(
                    completed: index,
                    total: max(total, 1),
                    detail: "Scanning \(package.lastPathComponent)"
                )
            )
            if let placement = try? place(package, cache: &cache), placement.logicalBytes >= ModelPackage.minimumFileBytes {
                placements.append(placement)
                store?.remember(name: placement.displayName, fingerprint: placement.fingerprint)
                store?.remember(name: package.lastPathComponent, fingerprint: placement.fingerprint)
            }
        }
        progress?(WorkProgress(completed: total, total: max(total, 1), detail: "Scan complete"))

        try? cache.save(to: paths.hashCache)
        return ScanReport(scannedRoots: roots, placements: placements)
    }

    private func collectRoots() -> [URL] {
        var roots: [URL] = []
        var seen = Set<String>()

        func add(_ url: URL) {
            let path = url.standardizedFileURL.path
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else { return }
            guard seen.insert(path).inserted else { return }
            roots.append(url)
        }

        for app in catalog.apps {
            for raw in app.roots {
                add(expander.expand(raw))
            }
            for relative in app.containerRoots {
                expander.expandContainerRoot(relative).forEach(add)
            }
            for glob in app.huggingfaceGlobs {
                huggingfaceMatches(glob).forEach(add)
            }
        }

        add(paths.packagesRoot)
        return roots
    }

    private func place(_ url: URL, cache: inout HashCache) throws -> Placement {
        let values = try url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey, .isDirectoryKey])
        let logical = try logicalSize(url)
        let mtime = values.contentModificationDate ?? .now

        let fingerprint: Fingerprint
        let bytes: Int64
        if let hit = cache.hit(path: url.path, modificationTime: mtime, logicalBytes: logical) {
            fingerprint = hit.fingerprint
            bytes = hit.logicalBytes
        } else {
            let hashed = try fingerprinter.fingerprint(at: url)
            fingerprint = hashed.0
            bytes = hashed.1
            cache.record(path: url.path, fingerprint: fingerprint, logicalBytes: bytes, modificationTime: mtime)
        }

        return Placement(
            url: url,
            fingerprint: fingerprint,
            logicalBytes: bytes,
            source: source(for: url),
            kind: ModelPackage.inferredKind(for: url),
            displayName: ModelPackage.displayName(for: url)
        )
    }

    private func huggingfaceMatches(_ glob: String) -> [URL] {
        let hubs = [
            expander.expand("~/.cache/huggingface/hub"),
            expander.expand("~/Library/Caches/huggingface/hub"),
        ]
        var matches: [URL] = []
        for hub in hubs {
            let children = (try? fileManager.contentsOfDirectory(at: hub, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])) ?? []
            for child in children where child.lastPathComponent.range(of: globToRegex(glob), options: .regularExpression) != nil {
                matches.append(child)
            }
        }
        return matches
    }

    private func globToRegex(_ glob: String) -> String {
        let escaped = NSRegularExpression.escapedPattern(for: glob)
            .replacing("\\*", with: ".*")
        return "^\(escaped)$"
    }

    private func source(for url: URL) -> PlacementSource {
        let path = url.path
        if path.hasPrefix(paths.packagesRoot.path) {
            return .store
        }
        if path.contains("huggingface") {
            return .huggingface
        }
        if path.contains("FluidAudio") {
            if let container = containerBundleName(from: path) {
                return .app(id: container, name: friendlyContainerName(container))
            }
            return .library(name: "FluidAudio")
        }
        for app in catalog.apps where app.kind == .app {
            if app.bundleIds.contains(where: { path.contains($0) }) {
                return .app(id: app.id, name: app.name)
            }
            if path.localizedStandardContains(app.name) {
                return .app(id: app.id, name: app.name)
            }
        }
        if path.contains("WhisperKit") || path.contains("whisperkit") {
            return .library(name: "WhisperKit")
        }
        if path.contains("Cotypist") || path.contains("cotypist") {
            return .app(id: "cotypist", name: "Cotypist")
        }
        if path.contains("Souffleuse") {
            return .app(id: "souffleuse", name: "Souffleuse")
        }
        if path.contains("KeyType") {
            return .app(id: "keytype", name: "KeyType")
        }
        if path.contains("Cotabby") {
            return .app(id: "cotabby", name: "Cotabby")
        }
        return .unknown
    }

    private func containerBundleName(from path: String) -> String? {
        let marker = "/Library/Containers/"
        guard let range = path.range(of: marker) else { return nil }
        let rest = path[range.upperBound...]
        return rest.split(separator: "/").first.map(String.init)
    }

    private func friendlyContainerName(_ bundle: String) -> String {
        if let app = catalog.apps.first(where: { $0.bundleIds.contains(bundle) }) {
            return app.name
        }
        return bundle.split(separator: ".").last.map { String($0) } ?? bundle
    }

    private func logicalSize(_ url: URL) throws -> Int64 {
        let values = try url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
        if values.isDirectory != true {
            return Int64(values.fileSize ?? 0)
        }
        var total: Int64 = 0
        if let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey, .isSymbolicLinkKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let file as URL in enumerator {
                let fileValues = try file.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .isDirectoryKey])
                if fileValues.isDirectory == true { continue }
                if fileValues.isRegularFile == true || fileValues.isSymbolicLink == true {
                    let resolved = file.resolvingSymlinksInPath()
                    total += Int64(try resolved.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0)
                }
            }
        }
        return total
    }
}
