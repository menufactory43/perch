import PerchCore

struct PackageGroup: Identifiable {
    var id: String
    var fingerprint: Fingerprint
    var name: String
    var kind: ModelKind
    var logicalBytes: Int64
    var copies: Int
    var apps: [String]
}
