import Foundation

public struct WorkProgress: Sendable, Equatable {
    public var completed: Int
    public var total: Int
    public var detail: String

    public init(completed: Int, total: Int, detail: String) {
        self.completed = completed
        self.total = total
        self.detail = detail
    }

    public var fraction: Double {
        guard total > 0 else { return 0 }
        return min(1, Double(completed) / Double(total))
    }
}
