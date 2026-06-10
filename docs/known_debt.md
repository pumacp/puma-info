# Known technical debt · puma-info

Active entries. Add new debt with monotonic ID `D-NNN`.

## D-001 · Docker services historically ran as root in bind mounts

File-writing stacks ran as the image-default root user, so files created in
bind-mounted host directories (`output/`, `public/`, `documents/`,
`manim_scenes/`) were owned by root and could not be modified by the host user.
This blocked host-side operations such as scaffolding a named public project.

- **Mitigation (applied):** the file-writing services now run as the host
  UID/GID via `user: "${PUMA_UID:-1000}:${PUMA_GID:-1000}"` with `HOME=/tmp`, so
  newly created bind-mount files are host-owned. Covers Documents F, Video D
  (`manim`, `hyperframes`), Voice C (`piper`), Publish E (`uploader`). All
  proven by real execution (including a real Piper synthesis and a real
  HyperFrames render producing host-owned output). `HOME=/tmp` redirects the
  npm/Chromium caches off the root-owned `/root`.
- **Residual (deferred):** the two GPU model services — Voice C `xtts` and
  Publish E `whisperx` — are **not** mapped. Their models/caches are baked under
  `/root` (mode 700), so a non-root user gets "permission denied" reading them
  (verified), and the runtime also needs a writable model cache. Mapping them
  requires a Dockerfile change to relocate the model/cache out of `/root` to a
  user-readable, writable, persistent path, plus an image rebuild and GPU
  re-verification. Tracked as the remaining follow-up.
- **Out-of-band step:** pre-existing root-owned files or directories created
  before this fix must be re-owned by the host user once; a non-root container
  cannot overwrite them.
