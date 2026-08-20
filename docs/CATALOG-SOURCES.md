# Where catalog rows come from

Perch does not run these engines. It only walks folders they leave on a Mac.

Mapped from `RESEARCH-STT-TTS.md` (20 Aug 2026) plus source/path checks:

| On disk | Why it is in the catalog | Not used for |
|---|---|---|
| FluidAudio `Application Support` + containers | Dictus, FluidVoice, VoiceInk, TypeWhisper all drop Parakeet/Core ML here | Inference |
| WhisperKit / `argmaxinc.whisperkit` | Apple Silicon Whisper (argmax-oss-swift). Pindrop and TypeWhisper sit on it | Streaming API |
| `models--ggerganov--whisper.cpp` | ggml `.bin` shared by MacWhisper, VoiceInk/TranscribeCpp, Buzz-class apps | Serving |
| `models--hexgrad--Kokoro*`, `*kokoro*` | Light commercial TTS (Apache-2.0) | Synthesis |
| `models--resemble-ai--chatterbox*` | MIT TTS, same weights often cached twice via HF | Synthesis |
| `models--*silero*` | VAD helper next to ASR | VAD runtime |
| VoiceInk `com.prakashjoshipax.VoiceInk` | Confirmed: FluidAudio + whisper.cpp xcframework | Their dictation UX |
| TypeWhisper plugin models path | Documented copy path for WhisperKit add-on | Their plugin host |

Left out on purpose (wrong product for Perch v1):

- RealtimeSTT, WhisperLive, speaches, faster-whisper, whisperX — Python/server caches, not Mac app folders we can clone into blindly
- pipecat / livekit — orchestration, no model store
- XTTS-v2, F5-TTS, Piper, fish-speech — licence traps; Perch still *finds* bytes if they sit in a scanned glob, but we do not advertise a `pull`
