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

    /// A tree counts as shared only when every file in it shares blocks.
    ///
    /// Probing just the largest file reported "already shared" for a tree whose
    /// big weights were cloned but whose smaller siblings were not, so the rest
    /// never got reclaimed. The check is stat + fcntl per file, which is noise
    /// next to the SHA-256 the scan already paid for.
    private static func shareDirectory(_ a: URL, _ b: URL, fileManager: FileManager) -> Bool {
        let children = (try? fileManager.contentsOfDirectory(at: a, includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey], options: [.skipsHiddenFiles])) ?? []
        var sawFile = false

        for child in children {
            let isDirectory = (try? child.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            let counterpart = b.appending(path: child.lastPathComponent)
            if isDirectory {
                guard shareDirectory(child, counterpart, fileManager: fileManager) else { return false }
                sawFile = true
                continue
            }
            guard shareFile(child, counterpart) else { return false }
            sawFile = true
        }

        return sawFile
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

private extension URL {
    var fileSize: Int {
        (try? resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
    }
}
