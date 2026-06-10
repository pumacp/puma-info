# Known technical debt · puma-info

Active entries. Add new debt with monotonic ID `D-NNN`.

## D-001 · Docker services historically ran as root in bind mounts

File-writing stacks ran as the image-default root user, so files created in
bind-mounted host directories (`output/`, `public/`, `documents/`,
`manim_scenes/`) were owned by root and could not be modified by the host user.
This blocked host-side operations such as scaffolding a named public project.

- **Mitigation (applied):** the file-writing services (Documents F, Video D
  `manim`, Publish E `uploader`) now run as the host UID/GID via
  `user: "${PUMA_UID:-1000}:${PUMA_GID:-1000}"` with `HOME=/tmp`, so newly
  created bind-mount files are host-owned. Proven by real execution.
- **Residual:** services whose models/caches live in root-owned named volumes
  (Video D `hyperframes` npm cache, Voice C `piper`/`xtts`, Publish E
  `whisperx`) are **not yet** mapped — doing so requires relocating those
  caches/models to a user-writable path and re-verifying GPU/model loading.
- **Out-of-band step:** pre-existing root-owned files or directories created
  before this fix must be re-owned by the host user once; a non-root container
  cannot overwrite them.
