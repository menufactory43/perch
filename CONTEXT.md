# Perch

Shared local store for speech model packages on a Mac. Apps keep their engines; Perch keeps one copy of each package on disk.

## Language

**Package**:
A model tree on disk (Core ML bundle, GGUF file, Hugging Face snapshot) treated as one fingerprintable unit.
_Avoid_: model file, artifact, blob (unless meaning a single hashed file)

**Fingerprint**:
SHA-256 of a package’s bytes (file) or of its sorted path/size/hash listing (directory).
_Avoid_: hash (too vague), revision, Hugging Face commit

**Placement**:
One package at a concrete path, owned by an app, a library, a cache, or the store.
_Avoid_: copy (use this only for “extra placement of the same fingerprint”), install

**Store**:
Canonical packages under `PERCH_HOME/store/packages/<fingerprint>/`.
_Avoid_: cache, registry, repo

**Clone**:
An APFS copy-on-write file that looks like a regular file and shares physical blocks until written.
_Avoid_: symlink, alias, hard link, shortcut

**Catalog**:
The list of known apps and folders Perch walks.
_Avoid_: index, database

**Reclaim**:
Replace extra placements of a fingerprint with clones of the store package so the volume can free the duplicate blocks.
_Avoid_: delete, compress, dedupe (informal OK in UI as “reclaim space”)
