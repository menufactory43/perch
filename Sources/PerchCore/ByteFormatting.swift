import Foundation

public enum ByteFormatting {
    public static func string(_ bytes: Int64) -> String {
        ByteCountFormatStyle(style: .file, allowedUnits: .all, spellsOutZero: true, includesActualByteCount: false)
            .format(bytes)
    }
}
