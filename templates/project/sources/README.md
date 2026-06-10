# sources/ — project source-of-truth

`sources/` is the **single human-facing entry point** for this project's
source-of-truth: the documents, notes and originals you author and maintain by
hand.

It does **not** replace the per-tool input directories (`compositions/`,
`documents/`, `manim_scenes/`, `scripts/`, `specs/`). Those keep working exactly
as before. You keep your source-of-truth here, in `sources/`, and from it you
organize or derive the per-tool inputs that the pipeline consumes.

The conversion and ingest targets accept a file under `sources/` directly: point
a target at `public/<id>/sources/<file>` (or `_private/<id>/sources/<file>`) and
its output is routed into this project's own tree (`<id>/output/` or
`<id>/documents/`), like any other per-project input. There is **no
auto-conversion and no auto-chaining** — you invoke each target explicitly on the
file you want; `sources/` simply holds the source-of-truth those targets read
from.

Source-of-truth has two roles (see each folder's `SKILL.md`):

- **`sources/primary/`** — MUTABLE canonical documents you author and correct;
  the basis for derived material.
- **`sources/secondary/`** — IMMUTABLE accumulated research/context that feeds and
  corrects the primary and serves as context for generation; never modified
  (optional phase subfolders live here).

Drafts/intermediate go in `working/`; produced material goes in `output/` (the
derived role). Each role folder carries a `SKILL.md` describing what it is and how
agents should use it.

See `docs/design/project-workspace-taxonomy.md` (primary / secondary / derived
model + SKILL descriptors) for the design of record.
