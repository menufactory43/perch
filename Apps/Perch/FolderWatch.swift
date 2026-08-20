import CoreServices
import Foundation

/// Debounced FSEvents on catalog roots. Misses are covered by a slow poll in the controller.
final class FolderWatch: @unchecked Sendable {
    private var stream: FSEventStreamRef?
    private let onChange: @Sendable () -> Void
    private var debounce: Task<Void, Never>?

    init(onChange: @escaping @Sendable () -> Void) {
        self.onChange = onChange
    }

    func start(paths: [String]) {
        stop()
        let existing = paths.filter { FileManager.default.fileExists(atPath: $0) }
        guard !existing.isEmpty else { return }

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        let callback: FSEventStreamCallback = { _, info, _, _, _, _ in
            guard let info else { return }
            Unmanaged<FolderWatch>.fromOpaque(info).takeUnretainedValue().scheduleFire()
        }
        guard let created = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            existing as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1.0,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagNoDefer)
        ) else {
            return
        }
        stream = created
        FSEventStreamSetDispatchQueue(created, DispatchQueue.global(qos: .utility))
        FSEventStreamStart(created)
    }

    func stop() {
        debounce?.cancel()
        debounce = nil
        if let stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            self.stream = nil
        }
    }

    private func scheduleFire() {
        debounce?.cancel()
        debounce = Task { [onChange] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            onChange()
        }
    }

    deinit {
        stop()
    }
}
