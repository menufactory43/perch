# APFS clones, not symlinks or hard links

Perch has to rewrite other apps’ model folders without those apps knowing. Symlinks fail sandbox and “is this a regular file?” checks, and deleting the target breaks every app. Hard links share an inode, so a write or truncate from FluidAudio would corrupt Dictus. `clonefile` gives a real file, independent lifetime, shared blocks until copy-on-write. That is the only option that is both invisible and safe.
