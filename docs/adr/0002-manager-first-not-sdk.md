# Manager first, not an inference daemon or required SDK

Perch cannot assume Dictus or FluidVoice will integrate a library. The v1 product is a menu bar app that scans known folders and clones in place, plus an optional `PerchCore` / `perch` CLI for developers who opt in. Serving audio through a local daemon would be faster in RAM, and also a different product: permissions, latency, and every app abandoning its own pipeline. Wyoming already occupies that niche. The store does not.
