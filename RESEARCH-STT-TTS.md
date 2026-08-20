# Repos STT / TTS qui cartonnent sur GitHub (relevé 2026-08-20, API GitHub)

## STT — moteurs & modèles
| Repo | ★ | Licence | Dernier push | Note |
|---|---|---|---|---|
| openai/whisper | 107.7k | MIT | 2026-07-28 | La référence, 99 langues. Plus le plus précis en EN mais l'écosystème gagne |
| ggml-org/whisper.cpp | 53.1k | MIT | 2026-08-20 | C/C++, binaire 5 Mo, Core ML/Metal, mode streaming ~1s de chunk |
| SYSTRAN/faster-whisper | 25.0k | MIT | 2025-11-19 | CTranslate2, ~4x plus rapide, base de la plupart des serveurs |
| m-bain/whisperX | 23.7k | BSD-2 | 2026-07-13 | Timestamps mot-à-mot + diarisation |
| alphacep/vosk-api | 15.1k | Apache-2.0 | 2026-08-09 | Offline embarqué (Android/iOS/RPi), très léger |
| k2-fsa/sherpa-onnx | 14.3k | Apache-2.0 | 2026-08-18 | STT+TTS+diarisation ONNX, bindings partout (Swift, Kotlin, Rust, C) |
| Vaibhavs10/insanely-fast-whisper | 13.0k | Apache-2.0 | 2025-10-25 | Batch GPU ultra-rapide |
| kyutai-labs/moshi | 10.9k | Apache-2.0 | 2026-05-16 | Full-duplex parole↔parole, latence conversationnelle |
| moonshine-ai/moonshine | 10.9k | — | 2026-08-20 | Très basse latence, pensé pour l'embarqué/temps réel |
| KoljaB/RealtimeSTT | 10.1k | MIT | 2026-06-12 | Lib Python temps réel : VAD + wake word + transcription incrémentale |
| snakers4/silero-vad | 10.0k | MIT | 2026-08-18 | Le VAD standard, brique obligatoire pour du streaming |
| argmaxinc/argmax-oss-swift (ex-WhisperKit) | 6.3k | — | actif | On-device Apple Silicon, Swift natif |
| MahmoudAshraf97/whisper-diarization | 5.6k | BSD-2 | 2026-08-15 | Qui parle quand |
| collabora/WhisperLive | 4.2k | MIT | 2026-08-04 | Serveur WebSocket temps réel sur faster-whisper |
| ufal/whisper_streaming | 3.7k | MIT | 2025-11-12 | LocalAgreement, l'algo de référence pour le streaming Whisper |
| speaches-ai/speaches | 3.6k | MIT | 2026-08-18 | Serveur API OpenAI-compatible (STT+TTS), drop-in |
| kyutai-labs/delayed-streams-modeling | 3.0k | Apache-2.0 | 2026-01-26 | STT/TTS streaming par nature |
| QwenLM/Qwen3-ASR-Toolkit | 1.0k | MIT | 2026-02-05 | Qwen3-ASR, meilleur WER EN que Whisper |

## STT — apps grand public (à copier pour l'UX)
| Repo | ★ | Note |
|---|---|---|
| chidiwilliams/buzz | 21.0k | Desktop offline, la wrapper Whisper la plus installée |
| Beingpax/VoiceInk | 6.0k | macOS, alternative open source à Superwhisper / Wispr Flow |
| EpicenterHQ/epicenter (ex-Whispering) | 4.8k | Local-first, dictée système |
| homelab-00/TranscriptionSuite | 0.7k | Multi-backend, 100% local |
| watzon/pindrop | 0.6k | Menubar macOS sur WhisperKit — la plus proche d'un MVP dictée |

## TTS
| Repo | ★ | Licence | Note |
|---|---|---|---|
| coqui-ai/TTS | 45.9k | MPL-2.0 | Archivé (2024), mais XTTS-v2 reste la meilleure clone 6s / 17 langues — licence CPML non commerciale |
| suno-ai/bark | 39.2k | MIT | Archivé, encore utilisé pour l'expressivité |
| myshell-ai/OpenVoice | 37.2k | MIT | Clonage instantané, contrôle du style |
| fishaudio/fish-speech | 32.3k | non-std | SOTA, vérifier la licence avant usage commercial |
| resemble-ai/chatterbox | 26.1k | MIT | SOTA + MIT : le meilleur rapport qualité/licence, contrôle d'émotion, ~200 ms |
| index-tts/index-tts | 23.2k | non-std | Zero-shot contrôlable, industriel |
| QwenAudio/CosyVoice | 22.8k | Apache-2.0 | Multilingue, streaming |
| nari-labs/dia | 19.4k | Apache-2.0 | Dialogue ultra-réaliste en une passe |
| SWivid/F5-TTS | 15.1k | code MIT / poids CC-BY-NC | Excellent mais **non commercial** |
| hexgrad/kokoro | 8.5k | Apache-2.0 | 82M params, tourne sur CPU, 2-3 Go VRAM — le meilleur choix "léger + commercial" |
| canopyai/Orpheus-TTS | 6.3k | Apache-2.0 | 3B, très humain |
| OHF-Voice/piper1-gpl | 5.2k | GPL-3.0 | Roi du CPU/Raspberry Pi — attention GPL |

## Orchestration voix temps réel (si l'app est conversationnelle)
- pipecat-ai/pipecat — 14.4k, BSD-2, framework agents vocaux (Daily)
- livekit/agents — 13.1k, Apache-2.0, pipeline STT→LLM→TTS avec barge-in

## Pièges licence à retenir
- Sûrs commercialement : Whisper, whisper.cpp, faster-whisper, Chatterbox, Kokoro, CosyVoice, Orpheus, sherpa-onnx, Silero VAD.
- À éviter/vérifier : XTTS-v2 (CPML), F5-TTS (CC-BY-NC), Piper (GPL-3), fish-speech & index-tts (licences maison).
