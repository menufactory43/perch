# Contributing

## Add an app to the catalog

Edit `Sources/PerchCore/Resources/catalog.json`.

- `roots` — unsandboxed locations (`~/Library/Application Support/…`)
- `containerRoots` — paths inside `~/Library/Containers/<bundle>/Data/`
- `bundleIds` — optional, only used to label the placement

If the app uses FluidAudio’s default folder, it may already be found. Add a row anyway so the menu bar shows the human name.

Then:

```
swift test
```

## Code

- `PerchCore` is the store. Keep FileManager and clonefile behind it.
- One type per Swift file.
- Tests go through `PerchSession` / planner / cloner, not through the menu bar.

Do not add an inference server without an ADR.

Do not widen **push** beyond FluidAudio folders without an ADR. Reclaim of identical GGUF copies across apps is fine; copying a model into an app that never asked for it is not.
