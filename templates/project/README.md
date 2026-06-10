# &lt;project&gt; — puma-info project

A self-contained production project. Material here drives the puma-info pipeline
(documents, slides, diagrams, video, narration, subtitles); produced artifacts go
under this project's own `output/`. The project's `SKILL.md` is its **path
contract** (see below).

## Layout (roles)
- `primary/` — MUTABLE canonical source-of-truth (`primary/SKILL.md`). Organize by
  type: `docs/`, `media/`, `data/`, `code/` (use what you need).
- `context/` — IMMUTABLE research/reference, read-only context (`context/SKILL.md`);
  optional phase subfolders.
- `output/` — DERIVED artifacts by type: `docs/`, `video/`, `audio/`, `images/`,
  `slides/`, `subs/` (auto-created; git-ignored for public projects).
- `work/` — OPTIONAL work-in-progress staging (`work/SKILL.md`).
- `SKILL.md` (root) — the project's **path contract** (machine-readable frontmatter
  declaring where sources/outputs/pipeline I/O live) + description.

Pipeline machine I/O (used by the video/orchestrator targets via their built-in
defaults until contract-resolution is wired): `compositions/<video-id>/`,
`specs/<video-id>.json`, `manim_scenes/`, `scripts/<video-id>/` (copy
`scripts/_template/`).

## Produce
Run the pipeline pointing at this project. For conversion targets give a path
under this project (and `OUTDIR=` to land output under a declared destination);
for the video pipeline pass `PROJECT=<this>`:

    make doc-ingest   FILE=<this>/primary/docs/notes.docx OUTDIR=<this>/output/docs
    make marp-render  FILE=<this>/primary/docs/deck.md FORMAT=pdf OUTDIR=<this>/output/slides
    make video-render NAME=<video-id> PROJECT=<this>
    make subs-<video-id> PROJECT=<this>

`<this>` is `public/<id>` or `_private/<id>`. See the repository-root
`docs/design/project-workspace-taxonomy.md` (the workspace model + path contract),
`docs/video-rules.md`, `docs/conversion-and-export.md`, and `prompts/README.md`.
