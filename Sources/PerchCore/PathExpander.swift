import Foundation

public struct PathExpander: @unchecked Sendable {
    public var home: URL
    public var containersRoot: URL
    public var fileManager: FileManager

    public init(home: URL, containersRoot: URL, fileManager: FileManager = .default) {
        self.home = home
        self.containersRoot = containersRoot
        self.fileManager = fileManager
    }

    public static func `default`(fileManager: FileManager = .default) -> PathExpander {
        let home = fileManager.homeDirectoryForCurrentUser
        return PathExpander(
            home: home,
            containersRoot: home.appending(path: "Library/Containers", directoryHint: .isDirectory),
            fileManager: fileManager
        )
    }

    public func expand(_ raw: String) -> URL {
        if raw.hasPrefix("~/") {
            let rest = String(raw.dropFirst(2))
            return home.appending(path: rest)
        }
        if raw.hasPrefix("~") {
            return home
        }
        return URL(fileURLWithPath: raw)
    }

    /// Every existing `Containers/<id>/Data/<relative>` folder.
    public func expandContainerRoot(_ relative: String) -> [URL] {
        guard let ids = try? fileManager.contentsOfDirectory(
            at: containersRoot,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return ids.compactMap { container in
            let url = container
                .appending(path: "Data", directoryHint: .isDirectory)
                .appending(path: relative)
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                return nil
            }
            return url
        }
    }
}
