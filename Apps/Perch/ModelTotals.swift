import SwiftUI

struct ModelTotals: View {
    var totalBytes: Int64
    var uniqueCount: Int
    var reclaimableBytes: Int64

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 24) {
            VStack(alignment: .leading, spacing: 2) {
                Text(totalBytes, format: .byteCount(style: .file))
                    .font(.title)
                    .bold()
                    .monospacedDigit()
                Text(uniqueCount == 1 ? "1 model" : "\(uniqueCount) models")
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(totalBytes, format: .byteCount(style: .file)), \(uniqueCount) models")

            VStack(alignment: .leading, spacing: 2) {
                Text(reclaimableBytes, format: .byteCount(style: .file))
                    .font(.title)
                    .bold()
                    .monospacedDigit()
                Text("can reclaim")
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(reclaimableBytes, format: .byteCount(style: .file)) can be reclaimed")
        }
    }
}
