/// What a package is for — speech in, speech out, or a helper around either.
public enum ModelKind: String, Sendable, Codable, Hashable, CaseIterable {
    case stt
    case tts
    case vad
    case diarization
    case unknown
}
