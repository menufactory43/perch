import SwiftUI

struct PackageRow: View {
    var group: PackageGroup

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 16)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(group.logicalBytes, format: .byteCount(style: .file))
                .font(.callout)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .padding(.vertical, 4)
    }

    private var icon: String {
        switch group.kind {
        case .stt: "waveform"
        case .tts: "speaker.wave.2"
        case .vad: "ellipsis.viewfinder"
        case .diarization: "person.2"
        case .unknown: "doc"
        }
    }

    private var subtitle: String {
        let uniqueApps = Array(Set(group.apps)).sorted()
        let names = uniqueApps.joined(separator: ", ")
        let copies = String(localized: "\(group.copies) copies")
        return "\(copies) · \(names)"
    }
}
