import Foundation

public enum FullDiskAccess {
    public static func isGranted(fileManager: FileManager = .default) -> Bool {
        let probes = [
            fileManager.homeDirectoryForCurrentUser.appending(path: "Library/Safari/CloudTabs.db"),
            fileManager.homeDirectoryForCurrentUser.appending(path: "Library/Application Support/com.apple.TCC/TCC.db"),
            URL(fileURLWithPath: "/Library/Application Support/com.apple.TCC/TCC.db"),
        ]
        return probes.contains { fileManager.isReadableFile(atPath: $0.path) }
    }

    public static var settingsURL: URL? {
        paneURLs.first
    }

    /// Deep links that have existed across Ventura → Tahoe. First one that the system accepts wins.
    public static var paneURLs: [URL] {
        [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles",
            "x-apple.systempreferences:com.apple.Settings.PrivacySecurity.PrivacyControls?Privacy_AllFiles",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles",
        ].compactMap(URL.init(string:))
    }
}
