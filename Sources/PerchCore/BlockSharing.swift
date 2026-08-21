import Darwin
import Foundation

/// Whether two paths already share physical blocks (hard link or APFS clone).
public enum BlockSharing {
    public static func sharesStorage(_ a: URL, _ b: URL, fileManager: FileManager = .default) -> Bool {
        let left = a.resolvingSymlinksInPath()
        let right = b.resolvingSymlinksInPath()
        if left.path == right.path { return true }

        var leftDir: ObjCBool = false
        var rightDir: ObjCBool = false
        guard fileManager.fileExists(atPath: left.path, isDirectory: &leftDir),
              fileManager.fileExists(atPath: right.path, isDirectory: &rightDir),
              leftDir.boolValue == rightDir.boolValue
        else {
            return false
        }

        if leftDir.boolValue {
            return shareDirectory(left, right, fileManager: fileManager)
        }
        return shareFile(left, right)
    }

    /// Every visible file must share; empty subdirs (or `.DS_Store`-only) do not count.
    private static func shareDirectory(_ a: URL, _ b: URL, fileManager: FileManager) -> Bool {
        let (sawFile, shared) = compareTree(a, b, fileManager: fileManager)
        return sawFile && shared
    }

    private static func compareTree(_ a: URL, _ b: URL, fileManager: FileManager) -> (sawFile: Bool, shared: Bool) {
        let children = (try? fileManager.contentsOfDirectory(at: a, includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey], options: [.skipsHiddenFiles])) ?? []
        var sawFile = false

        for child in children {
            let isDirectory = (try? child.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            let counterpart = b.appending(path: child.lastPathComponent)
            if isDirectory {
                let nested = compareTree(child, counterpart, fileManager: fileManager)
                if !nested.shared { return (true, false) }
                sawFile = sawFile || nested.sawFile
                continue
            }
            sawFile = true
            if !shareFile(child, counterpart) { return (true, false) }
        }

        return (sawFile, true)
    }

    private static func shareFile(_ a: URL, _ b: URL) -> Bool {
        var aStat = stat()
        var bStat = stat()
        guard stat(a.path, &aStat) == 0, stat(b.path, &bStat) == 0 else { return false }
        if aStat.st_dev == bStat.st_dev, aStat.st_ino == bStat.st_ino {
            return true
        }
        guard aStat.st_size > 0, aStat.st_size == bStat.st_size else { return false }
        guard let aPhys = physicalOffset(a), let bPhys = physicalOffset(b) else { return false }
        return aPhys == bPhys
    }

    private static func physicalOffset(_ url: URL) -> off_t? {
        let fd = open(url.path, O_RDONLY)
        guard fd >= 0 else { return nil }
        defer { close(fd) }
        var info = log2phys()
        let status = fcntl(fd, F_LOG2PHYS, &info)
        guard status == 0 else { return nil }
        return info.l2p_devoffset
    }
}
