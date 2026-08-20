import Foundation

/// Recognition of a speech model package on disk (Core ML, GGUF, HF snapshot, …).
public enum ModelPackage {
    public static let minimumFileBytes: Int64 = 1_048_576

    public static func isPackage(at url: URL, fileManager: FileManager = .default) -> Bool {
        let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
        return isPackage(at: url, values: values, fileManager: fileManager)
    }

    public static func isPackage(at url: URL, values: URLResourceValues?, fileManager: FileManager) -> Bool {
        let ext = url.pathExtension.lowercased()
        if ["mlmodelc", "mlpackage", "mlmodel"].contains(ext) {
            return true
        }

        if ["gguf", "bin"].contains(ext) {
            let size = Int64(values?.fileSize ?? 0)
            return size >= minimumFileBytes && nameLooksLikeSpeechModel(url.lastPathComponent)
        }

        let isDirectory = values?.isDirectory ?? url.hasDirectoryPath
        guard isDirectory else { return false }

        if isContainerName(url.lastPathComponent) {
            return false
        }

        if nameLooksLikeSpeechModel(url.lastPathComponent) {
            return directoryContainsWeights(url, fileManager: fileManager)
        }

        return directoryContainsWeights(url, fileManager: fileManager) && looksLikeHuggingFaceSnapshot(url)
    }

    public static func discover(in root: URL, maxDepth: Int = 4, fileManager: FileManager = .default) -> [URL] {
        var found: [URL] = []
        walk(root: root, depth: 0, maxDepth: maxDepth, fileManager: fileManager, into: &found)
        return found
    }

    public static func inferredKind(for url: URL) -> ModelKind {
        let name = url.path.lowercased()
        if name.contains("kokoro") || name.contains("tts") || name.contains("piper") || name.contains("orpheus") {
            return .tts
        }
        if name.contains("silero") || name.contains("vad") {
            return .vad
        }
        if name.contains("diar") || name.contains("pyannote") || name.contains("sortformer") {
            return .diarization
        }
        if name.contains("parakeet") || name.contains("whisper") || name.contains("nemotron") || name.contains("asr") || name.contains("transcri") {
            return .stt
        }
        return .unknown
    }

    public static func displayName(for url: URL) -> String {
        let last = url.lastPathComponent
        if last == "snapshots" || last.count == 40 {
            return url.deletingLastPathComponent().lastPathComponent
                .replacing("models--", with: "")
                .replacing("--", with: "/")
        }
        return last
    }

    private static func walk(root: URL, depth: Int, maxDepth: Int, fileManager: FileManager, into found: inout [URL]) {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: root.path, isDirectory: &isDirectory) else { return }

        if !isDirectory.boolValue {
            if isPackage(at: root, fileManager: fileManager) {
                found.append(root)
            }
            return
        }

        if isPackage(at: root, fileManager: fileManager) {
            found.append(root)
            return
        }

        guard depth < maxDepth else { return }

        let children = (try? fileManager.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        for child in children {
            walk(root: child, depth: depth + 1, maxDepth: maxDepth, fileManager: fileManager, into: &found)
        }
    }

    private static func isContainerName(_ name: String) -> Bool {
        let skipped: Set<String> = [
            "Models", "models", "hub", "snapshots", "cache", "Caches",
            "Application Support", "huggingface", "mlx", "store", "packages",
        ]
        return skipped.contains(name)
    }

    private static func nameLooksLikeSpeechModel(_ name: String) -> Bool {
        let lowered = name.lowercased()
        let tokens = [
            "parakeet", "whisper", "kokoro", "nemotron", "silero",
            "pyannote", "sensevoice", "paraformer", "cohere",
            "piper", "ggml", "encoder", "decoder", "asr", "tts",
            "fluidaudio", "eou", "sortformer", "chatterbox",
            "sherpa", "moonshine", "vosk",
        ]
        return tokens.contains { lowered.contains($0) }
    }

    private static func directoryContainsWeights(_ url: URL, fileManager: FileManager) -> Bool {
        let children = (try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles])) ?? []
        let weightExts: Set<String> = ["mlmodelc", "mlpackage", "mlmodel", "safetensors", "onnx", "gguf", "bin", "pt", "npz", "weights"]
        return children.contains { child in
            if weightExts.contains(child.pathExtension.lowercased()) {
                return true
            }
            let name = child.lastPathComponent.lowercased()
            return name == "model.safetensors" || name.hasSuffix(".mlmodelc")
        }
    }

    private static func looksLikeHuggingFaceSnapshot(_ url: URL) -> Bool {
        url.path.contains("/snapshots/") || url.path.contains("huggingface")
    }
}
