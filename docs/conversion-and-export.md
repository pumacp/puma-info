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
- **Google Docs** ← `make quarto-render FILE=<f> FORMAT=docx` (or
  `make pandoc-convert FILE=<f> FORMAT=docx`) → `output/<f>.docx`, which
  Google Docs imports cleanly.

## Ingest from Google (Google → local)

| Target | Tool | In → out |
|--------|------|----------|
| `make doc-ingest FILE=documents/<f>.docx FORMAT=<md\|html>` | Pandoc | `.docx` (exported from Google Docs) → `documents/<f>.md` |

> **Google Slides import (`.pptx` → local) is not supported** by the
> current tools (Pandoc/Marp do not read `.pptx`). Use a PDF/image export
> as the bridge, or add a `.pptx` reader if this becomes necessary.

## Notes

- Repository-wide hard rules (isolation, reproducibility, content
  hygiene) are in `AGENTS.md` and `docs/constitution.md`.
- These targets are thin wrappers; they do not alter the production
  pipeline paths (`specs/`, `compositions/`, `manim_scenes/`, `output/`,
  `translation/`).
