# Perch

One store for local speech models on the Mac.

Dictus, FluidVoice, WhisperKit, Hugging Face, MLX — they all download the same Parakeet, Whisper, or Kokoro package into their own folder. Perch finds those copies, keeps **one** canonical tree, and replaces the rest with **APFS clones**. Apps see a normal file. The disk sees one.

No other app has to adopt anything. You grant Full Disk Access once.

Developers who *do* want to cooperate can depend on `PerchCore` and resolve a model from the store instead of downloading it again.

## For people who just want the space back

1. Open `Perch.xcodeproj` (generate it with [XcodeGen](https://github.com/yonaskolb/XcodeGen): `xcodegen generate`) and run **Perch**.
2. Click the cylinder in the menu bar.
3. Grant **Full Disk Access** when asked (System Settings → Privacy & Security).
4. Click **Reclaim Space**.

Perch does not upload audio or models. It is not sandboxed, and it is not on the App Store — it has to write into other apps’ folders.

## For developers

```swift
import PerchCore

let session = try PerchSession()
let report = try session.scan()
let plan = session.plan(from: report)
let result = try session.reclaim(plan)

let url = session.store.url(for: fingerprint) // canonical package
```

CLI (after `swift build -c release`):

```
.build/release/perch status
.build/release/perch reclaim --dry-run
.build/release/perch reclaim
.build/release/perch resolve <sha256>
.build/release/perch path
```

Set `PERCH_HOME` to move the store (tests, extra volumes).

The on-disk layout is documented in [docs/PROTOCOL.md](docs/PROTOCOL.md). Add an app to the scanner by editing [Sources/PerchCore/Resources/catalog.json](Sources/PerchCore/Resources/catalog.json) and opening a PR.

## How clones work

An APFS clone is a real file that shares physical blocks with another file until one of them is written. It is not a symlink. Sandboxed apps, path checks, and “is this a regular file?” all succeed. Deleting one copy does not delete the other.

Finder may still show the *logical* size of each folder. Perch shows what you actually get back.

This does not share RAM or speed up inference. It only stops the same 1.2 GB model from occupying the disk three times.

## Requirements

- macOS 14 or later
- Apple Silicon or Intel, APFS system volume
- Full Disk Access for the menu bar app

## Build

```
swift test
xcodegen generate
xcodebuild -project Perch.xcodeproj -scheme Perch -configuration Debug
```

## License

MIT. See [LICENSE](LICENSE).
