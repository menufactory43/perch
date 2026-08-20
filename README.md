# Perch

Menu bar app for the Mac that stops local speech (and nearby LLM) models from eating the disk twice.

Dictus, FluidVoice, Cotypist, Souffleuse, Hugging Face, FluidAudio — they each keep their own copy of the same Parakeet, Whisper, Kokoro, or Gemma file. Perch finds those copies, keeps **one** tree in `~/Library/Application Support/Perch`, and replaces extras with **APFS clones**. Apps still see a normal file. The volume only pays once.

No other app has to integrate anything. You grant **Full Disk Access** once.

## Install

```bash
brew tap menufactory43/perch
brew install --cask perch
```

Or grab the signed, notarized **[DMG](https://github.com/menufactory43/perch/releases/latest)** (Apple Silicon + Intel) and drag Perch into Applications.

It lives in the **menu bar** (cylinder icon), not the Dock.

## What you get

| | |
|---|---|
| **Scan** | Parakeet / FluidAudio, Whisper & Kokoro on Hugging Face, VoxCPM, GGUF in Cotypist / Souffleuse / KeyType / Cotabby. Progress shows in the popover. |
| **Totals** | How heavy all models are, and how much duplicate data can still be reclaimed |
| **Reclaim** | Extra copies of the *same* bytes become APFS clones. Confirmation stays in the popover |
| **Fill** | If FluidVoice has an empty `FluidAudio/Models` folder and Dictus already has Parakeet, Perch clones it there. **Only FluidAudio** |
| **Delete** | Trash on a row removes the model from apps *and* the Perch store, then rescans |
| **Watch** | Optional. Re-clones true duplicates when folders change. Does not copy models into unrelated apps |

Perch does not transcribe, synthesize, or download from Hugging Face. It is not on the App Store (it has to write into other apps’ folders).

## First launch

1. Click **Add Perch…**
2. macOS will **not** list Perch by itself. Click **+** at the bottom of Full Disk Access, pick `/Applications/Perch.app` (Finder highlights it), turn the switch on
3. Back in Perch: **I’ve granted access**
4. Read the two numbers: total size vs reclaimable
5. **Reclaim Space** → **Confirm Reclaim** if there are real duplicates
6. Trash a row only if you want that model gone for good

Settings (gear in the footer): launch at login, watch, reveal the store, Full Disk Access again.

## For app authors

If Perch is installed, **do not download a model you can already open**.

```bash
perch resolve parakeet-tdt-0.6b-v3-coreml
```

```swift
import PerchCore

if let url = try PerchSession().resolve(name: "parakeet-tdt-0.6b-v3-coreml") {
    // load from url
}
```

Full contract (no Swift dependency required): [docs/ADOPT.md](docs/ADOPT.md).

## Clones, not symlinks

An APFS clone is a real file that shares physical blocks until someone writes. Sandbox, `stat`, and “is this a regular file?” all succeed. Deleting one copy does not delete the others.

The Finder often still shows the *logical* size of each folder. After a successful reclaim, Perch’s **can reclaim** figure should be zero even if Finder still looks fat.

This does not share RAM or speed up inference.

## CLI and `PerchCore`

```bash
swift build -c release --product perch
.build/release/perch status
.build/release/perch reclaim --dry-run
.build/release/perch reclaim
.build/release/perch delete <sha256> --yes
.build/release/perch resolve <name|sha256>
.build/release/perch path
```

```swift
let session = try PerchSession()
let report = try session.scan()
let plan = session.plan(from: report)
_ = try session.reclaim(plan)
```

`PERCH_HOME` overrides the store. Layout: [docs/PROTOCOL.md](docs/PROTOCOL.md).  
Add an app to the scanner: [Sources/PerchCore/Resources/catalog.json](Sources/PerchCore/Resources/catalog.json) — see [CONTRIBUTING.md](CONTRIBUTING.md).

## Build from source

Needs [Xcode](https://developer.apple.com/xcode/) 16+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
git clone https://github.com/menufactory43/perch.git
cd perch
swift test
xcodegen generate
xcodebuild -project Perch.xcodeproj -scheme Perch -configuration Debug \
  -destination 'platform=macOS,arch=arm64' build
```

Maintainers: `NOTARY_PROFILE=souffleuse ./scripts/make-dmg.sh` produces a notarized `dist/Perch-<version>.dmg`.

## Requirements

- macOS 14+
- APFS system volume
- Full Disk Access for the menu bar app

## License

MIT. See [LICENSE](LICENSE).
