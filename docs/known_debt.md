# Known technical debt · puma-info

Active entries. Add new debt with monotonic ID `D-NNN`.

## D-001 · Docker services historically ran as root in bind mounts — RESOLVED

File-writing stacks ran as the image-default root user, so files created in
bind-mounted host directories (`output/`, `public/`, `documents/`,
`manim_scenes/`) were owned by root and could not be modified by the host user.
This blocked host-side operations such as scaffolding a named public project.

- **Resolution (applied):** **every** file-writing service now runs as the host
  UID/GID via `user: "${PUMA_UID:-1000}:${PUMA_GID:-1000}"` with `HOME=/tmp`, so
  newly created bind-mount files are host-owned. Covers Documents F, Video D
  (`manim`, `hyperframes`), Voice C (`piper`, `xtts`), Publish E (`uploader`,
  `whisperx`). All proven by **real execution**, including real Piper synthesis,
  a real HyperFrames render, a real XTTS GPU voice-clone, and a real WhisperX GPU
  transcription — each producing host-owned output.
- **GPU model services (`xtts`, `whisperx`):** their models were baked under
  `/root` (mode 700, unreadable as non-root). The fix bakes each model at a
  non-root, world-readable cache path resolved by the framework's own env vars —
  `XDG_DATA_HOME=/opt/share` for Coqui XTTS, `XDG_CACHE_HOME=/opt/cache` +
  `HF_HOME=/opt/cache/huggingface` for WhisperX (with `chmod a+rwX` so the
  runtime can still write alignment/VAD models). The old `/root`-mounted named
  volumes were dropped; the model stays baked in the image (no re-download at
  run time). Image IDs updated in `versions.lock`.
- **Out-of-band step:** pre-existing root-owned files or directories created
  before this fix must be re-owned by the host user once; a non-root container
  cannot overwrite them.
