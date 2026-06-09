# &lt;project&gt; — puma-info project

A self-contained production project. Inputs here drive the puma-info
pipeline (documents, slides, diagrams, video, narration, subtitles) and
outputs are written under this project's own `output/` (auto-created).

## Layout
- `documents/` — Quarto/Marp/Mermaid/Inkscape sources (`.qmd` / `.md` / `.mmd` / `.svg`).
- `scripts/<video-id>/` — per-video authoring (copy `scripts/_template/`):
  `rules.md` (production rules) + `script.md` (scene script). A project may
  hold several videos, one `scripts/<video-id>/` each.
- `specs/<video-id>.json` — machine spec the pipeline consumes.
- `compositions/<video-id>/` — HyperFrames composition
  (e.g. `cp -r compositions/_template <this>/compositions/<video-id>`).
- `manim_scenes/` — Manim scenes (`.py`).
- `output/` — rendered artefacts (auto-created; git-ignored for public projects).
- `docs/ai-use-log.md` — AI-use log (auto-created for private projects).

## Produce
Run the pipeline pointing at this project. For conversion targets, give a
path under this project; for the video pipeline, pass `PROJECT=<this>`:

    make marp-render FILE=<this>/documents/deck.md FORMAT=pdf
    make video-render NAME=<video-id> PROJECT=<this>
    make subs-<video-id> PROJECT=<this>

`<this>` is `public/<id>` or `_private/<id>`. See the repository-root
`docs/video-rules.md`, `docs/conversion-and-export.md`, and
`prompts/README.md` (the launchpad).
