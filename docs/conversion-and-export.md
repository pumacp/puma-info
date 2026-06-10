# Conversion, export and ingest targets

All of these use **tools already installed** in the Group D (video) and
Group F (documents) stacks — no new dependencies. Inputs live under the
stack-mounted directories; outputs go to `output/` (or `documents/` for
ingest). Bring the relevant stack up first (`make video-up` or
`make docs-up`); the wrapper targets declare it as a prerequisite.

## Document conversion (Group F · Quarto + Pandoc)

| Target | Tool | In → out |
|--------|------|----------|
| `make quarto-render FILE=<f> FORMAT=<pdf\|html\|docx>` | Quarto | `.qmd`/`.md` → `output/` |
| `make pandoc-convert FILE=<f> FORMAT=<docx\|html\|epub>` | Pandoc | `.md` → `output/` |
| `make mermaid-render FILE=<f> FORMAT=<png\|svg\|pdf>` | Mermaid CLI | `.mmd` → `output/` |
| `make inkscape-convert FILE=<f> FORMAT=<png\|pdf>` | Inkscape | `.svg` → `output/` |

Pandoc/Quarto interconvert Markdown ↔ DOCX ↔ HTML ↔ EPUB freely, and
produce PDF via TinyTeX. **PDF as a *source* is not supported** (Pandoc
does not read PDF input).

## Video conversion (Group D · ffmpeg)

| Target | Tool | In → out |
|--------|------|----------|
| `make video-convert FILE=<f> FORMAT=<mp4\|webm\|mov> RESOLUTION=<1080p\|720p\|4k>` | ffmpeg | video under `compositions/` or `output/` → `output/` |

`RESOLUTION` is optional (omit to keep the source resolution). Example:
`make video-convert FILE=output/01.mp4 FORMAT=webm RESOLUTION=720p`.

## Export to Google (bridge formats)

- **Google Slides** ← `make marp-render FILE=<deck>.md FORMAT=pptx` → `output/<deck>.pptx`.
  > Caveat: Marp's `.pptx` renders each slide as an **image**; Google
  > Slides imports it but the slides are **not natively editable** (no
  > editable text/shapes).
- **Google Slides (editable)** ← `make slides-export FILE=<f.md|.docx>` →
  `output/<f>.pptx` with **real editable shapes/text** (pandoc), unlike
  Marp's image slides.
- **Google Docs** ← `make quarto-render FILE=<f> FORMAT=docx` (or
  `make pandoc-convert FILE=<f> FORMAT=docx`) → `output/<f>.docx`, which
  Google Docs imports cleanly.

## Ingest from Google (Google → local)

| Target | Tool | In → out |
|--------|------|----------|
| `make doc-ingest FILE=documents/<f>.docx FORMAT=<md\|html>` | Pandoc | `.docx` (exported from Google Docs) → `documents/<f>.md` |
| `make pptx-ingest FILE=<f>.pptx FORMAT=<pdf\|html>` | LibreOffice | `.pptx` (exported from Google Slides) → `documents/<f>.<pdf\|html>` |

`doc-ingest` extracts any embedded images into a `media/` subdirectory next to
the output (so `<proj>/documents/media/…`), and the figure links in the
generated Markdown resolve. Documents without embedded media convert unchanged.

> **Google Slides import (`.pptx` → local) is supported** via
> `make pptx-ingest` (LibreOffice → pdf/html). For `.pptx` → Markdown, use the
> two-step bridge: `make pptx-ingest FILE=x.pptx FORMAT=html`, then
> `docker exec puma_info_quarto quarto pandoc documents/x.html -o documents/x.md`.

## Per-project output (OUTDIR convention)

When the input path is under a named project — `public/<id>/…` or
`_private/<id>/…` — these targets route their output into that project's
own directory instead of the repository-root `output/`:

| Target family | Root (default) | Per-project (`public/<id>/…` / `_private/<id>/…`) |
|---|---|---|
| quarto / marp / mermaid / inkscape / pandoc / video-convert | `output/` | `<id-prefix>/output/` |
| doc-ingest (source ingestion) | `documents/` | `<id-prefix>/documents/` |
| manim-render (`--media_dir`) | `manim_scenes/media/` | `<id-prefix>/manim_scenes/media/` |

- A root-level input (no `public/`/`_private/` prefix) behaves **exactly as
  before** — output goes to the repository-root directory.
- A malformed prefix (e.g. `public/x.md`, only two segments) falls back to
  the root default.
- Pass `OUTDIR=<dir>` to override the auto-derived destination.
- A file under a project's **`sources/`** directory (the single source-of-truth
  entry point) is a valid input: a path like `public/<id>/sources/<f>` or
  `_private/<id>/sources/<f>` is classified by its `<id>` prefix, so output
  routes into that project's own tree exactly like any other per-project input —
  no extra flag needed. You still invoke each target explicitly; nothing is
  auto-converted or auto-chained.

> **Per-project render pipeline:** the orchestrator (`make video-render`,
> `make subs-<id>`, `02_generate_narration`, `04_generate_subtitles`) routes its
> output into the selected project's tree when given `PROJECT=public/<id>` (or
> `_private/<id>`) / `--project`: `apply_project()` repoints `output/` and
> `compositions/` under that project. Without it, output goes to the
> repository-root `output/`/`compositions/`, exactly as before.
> `05_translate` keeps its own `translation/` workspace.

## Notes

- Repository-wide hard rules (isolation, reproducibility, content
  hygiene) are in `AGENTS.md` and `docs/constitution.md`.
- These targets are thin wrappers; they do not alter the production
  pipeline paths (`specs/`, `compositions/`, `manim_scenes/`, `output/`,
  `translation/`).
