# Using Perch from another app

If the user has Perch installed, **do not download a model you can already open**.

## Without a Swift dependency

Default store:

```
~/Library/Application Support/Perch/store/
  packages/<sha256>/          canonical tree or file
  aliases/<name>              text file whose contents are that sha256
```

Override with `PERCH_HOME`.

Before `URLSession` / Hugging Face:

1. Read `aliases/<name>` (use the folder or file name you would have created, e.g. `parakeet-tdt-0.6b-v3-coreml`).
2. If it exists, use `packages/<sha256>` as the model URL.
3. Otherwise download as you do today. Perch will pick it up on the next scan and write the alias.

Slash in a Hugging Face id becomes `--` (`mlx-community/whisper-base-mlx`).

## With PerchCore

```swift
import PerchCore

if let url = try PerchSession().resolve(name: "parakeet-tdt-0.6b-v3-coreml") {
    // load from url — already on disk, possibly an APFS clone
} else {
    // download into Application Support/FluidAudio/Models as usual
}
```

CLI: `perch resolve parakeet-tdt-0.6b-v3-coreml`

## FluidAudio / Dictus / FluidVoice

You already share `~/Library/Application Support/FluidAudio/Models` when you are not sandboxed. For a **container**, call `resolve` and, if you get a path, `clonefile` (or copy) into your sandbox folder — or let Perch’s **Fill** do that for FluidAudio paths only.

Do not download a second Parakeet because Perch’s store path looks unfamiliar. Load the file. It is a normal package.
