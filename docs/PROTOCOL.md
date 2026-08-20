# Perch protocol

Perch is a **store**, not an inference daemon. Apps keep their own engines (FluidAudio, WhisperKit, MLX, …). They either ignore Perch entirely (the menu bar app rewrites their folders) or they read a package out of the store.

## Home

```
$PERCH_HOME                          default: ~/Library/Application Support/Perch
  store/packages/<sha256>/           canonical package tree
  hash-cache.json                    path + mtime → fingerprint
  ledger.json                        reserved
```

`<sha256>` is the hex digest of the package fingerprint, not a Hugging Face revision.

## Fingerprint

A file: SHA-256 of its bytes.

A directory: SHA-256 of the UTF-8 lines

```
<relative path>\t<size>\t<file sha256>\n
```

sorted by relative path, hidden files skipped.

Two packages with the same fingerprint are byte-identical trees. Perch then clones.

## Clone rules

1. `clonefile(2)` on the same APFS volume.
2. If that fails (`ENOTSUP`, `EXDEV`, `EINVAL`), fall back to a full copy and report no savings.
3. Never symlink. Never hard-link. Hard-links share an inode: a write from one app corrupts every copy.
4. Replace via a staging name, then `replaceItemAt`, so a crash does not leave a half-written tree.

## Catalog

`catalog.json` lists apps, libraries, and caches. Each entry has:

- `roots` — paths with `~` expanded
- `containerRoots` — relative paths inside every `~/Library/Containers/*/Data/`
- optional `bundleIds` — used only to name a placement in the UI

Unknown apps that drop models into `Application Support/FluidAudio/Models` (the usual FluidAudio location, including inside a container) are picked up without a catalog row.

## Push

If fingerprint F lives in one app folder and another **existing** catalog folder does not contain F, Perch clones `store/packages/<F>` to `<folder>/<original file name>`. It never overwrites a path that already exists (a different version of the same name stays). Hugging Face caches and the Perch store are not push destinations.

## Watch

After the first reclaim, the menu bar app keeps sharing automatically: FSEvents on scanned roots, plus a 5-minute poll. Each tick scans, then applies reclaim + push without another confirmation.

## What Perch will not do (v1)

- Run STT or TTS
- Download from Hugging Face (apps already do)
- Require a daemon or a localhost HTTP API
- Work from the Mac App Store
