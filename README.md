# Perch

Menu bar app for the Mac that stops local speech (and nearby LLM) models from eating the disk twice.

Dictus, FluidVoice, Cotypist, Souffleuse, Hugging Face, FluidAudio — they each keep their own copy of the same Parakeet, Whisper, Kokoro, or Gemma file. Perch finds those copies, keeps **one** tree in `~/Library/Application Support/Perch`, and replaces extras with **APFS clones**. Apps still see a normal file. The volume only pays once.

No other app has to integrate anything. You grant **Full Disk Access** once.

## What you get

| | |
|---|---|
| **Scan** | Parakeet / FluidAudio, Whisper & Kokoro on Hugging Face, VoxCPM, GGUF in Cotypist / Souffleuse / KeyType / Cotabby |
| **Totals** | How heavy all models are, and how much duplicate data can still be reclaimed |
| **Reclaim** | Extra copies of the *same* bytes become APFS clones. Confirmation stays in the popover |
| **Fill** | If FluidVoice has an empty `FluidAudio/Models` folder and Dictus already has Parakeet, Perch clones it there. **Only FluidAudio** — not every folder named `Models` |
| **Delete** | Trash on a row removes the model from apps *and* the Perch store (otherwise clones would not free space) |
| **Watch** | Optional. Re-clones true duplicates when folders change. Does not scatter models into unrelated apps |

Perch does not transcribe, synthesize, or download from Hugging Face. It is not on the App Store (it has to write into other apps’ folders).

## Install

**[Download Perch-1.0.0.dmg](https://github.com/menufactory43/perch/releases/latest)** (signed & notarized, Intel + Apple Silicon).

Open the disk image, drag **Perch** onto **Applications**, launch it from there. It lives in the menu bar (cylinder icon), not the Dock.

To build from source you need [Xcode](https://developer.apple.com/xcode/) 16+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
git clone https://github.com/menufactory43/perch.git
cd perch
swift test
xcodegen generate
xcodebuild -project Perch.xcodeproj -scheme Perch -configuration Debug \
  -destination 'platform=macOS,arch=arm64' build
```

Maintainers: `NOTARY_PROFILE=souffleuse ./scripts/make-dmg.sh` produces a notarized `dist/Perch-<version>.dmg`.

## First launch

Perch lives in the **menu bar** (cylinder icon), not the Dock.

1. Click **Add Perch…**
2. macOS will **not** list Perch by itself. Click **+** at the bottom of Full Disk Access, pick `/Applications/Perch.app` (Finder highlights it), turn the switch on
3. Back in Perch: **I’ve granted access**
4. Read the two numbers: total size vs reclaimable
5. **Reclaim Space** → **Confirm Reclaim** if there are real duplicates
6. Trash a row only if you want that model gone for good

Settings (gear in the footer): launch at login, watch, reveal the store, Full Disk Access again.

## Clones, not symlinks

An APFS clone is a real file that shares physical blocks until someone writes. Sandbox, `stat`, and “is this a regular file?” all succeed. Deleting one copy does not delete the others.

The Finder often still shows the *logical* size of each folder. After a successful reclaim, Perch’s **can reclaim** figure should be zero even if Finder still looks fat.

This does not share RAM or speed up inference.

## Developers

Swift package `PerchCore` + CLI `perch`:

```swift
import PerchCore

let session = try PerchSession()
let report = try session.scan()
let plan = session.plan(from: report)
_ = try session.reclaim(plan)

let url = session.store.url(for: fingerprint)
```

```bash
swift build -c release --product perch
.build/release/perch status
.build/release/perch reclaim --dry-run
.build/release/perch reclaim
.build/release/perch delete <sha256> --yes
.build/release/perch resolve <sha256>
.build/release/perch path
```

`PERCH_HOME` overrides the store (tests, extra volumes).

On-disk layout: [docs/PROTOCOL.md](docs/PROTOCOL.md).  
Add an app: edit [Sources/PerchCore/Resources/catalog.json](Sources/PerchCore/Resources/catalog.json) and open a PR — see [CONTRIBUTING.md](CONTRIBUTING.md).

## Requirements

- macOS 14+
- APFS system volume
- Full Disk Access for the menu bar app

## License

MIT. See [LICENSE](LICENSE).
