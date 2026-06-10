# sources/ — project source-of-truth

`sources/` is the **single human-facing entry point** for this project's
source-of-truth: the documents, notes and originals you author and maintain by
hand.

It does **not** replace the per-tool input directories (`compositions/`,
`documents/`, `manim_scenes/`, `scripts/`, `specs/`). Those keep working exactly
as before. You keep your source-of-truth here, in `sources/`, and from it you
organize or derive the per-tool inputs that the pipeline consumes.

This is the **light, organizational form** of the convention: **no target reads
from `sources/` automatically** — that wiring is intentionally deferred to a
later increment. For now `sources/` is a place to gather and navigate a
project's real source material; populating the per-tool input dirs from it is a
manual step.

See `docs/design/research-project-workspace.md` §4 (source-of-truth: current
state vs target) and §8 (deferred & gated work) for the design of record.
