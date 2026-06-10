<p align="center">
  <img src="https://raw.githubusercontent.com/pumacp/puma/main/assets/img/PUMA.png" alt="PUMA Logo" width="220">
</p>

<h1 align="center">PUMA Info</h1>

<p align="center">
  <em>Public information production for the PUMA Project: videos,
  translated PDFs, slides, posters, infographics, and editable slides with
  Google-interop import/export, across multiple languages. Reproducible by
  design, fully open-source.</em>
</p>

<p align="center">
  <a href="https://github.com/pumacp/puma-info/actions/workflows/lint.yml">
    <img src="https://github.com/pumacp/puma-info/actions/workflows/lint.yml/badge.svg" alt="Lint">
  </a>
  <a href="https://pumacp.github.io/puma-info/">
    <img src="https://img.shields.io/badge/docs-pumacp.github.io%2Fpuma--info-blue" alt="Documentation">
  </a>
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="License: MIT">
  <img src="https://img.shields.io/badge/runs%20on-Docker-2496ED?logo=docker&logoColor=white" alt="Runs on Docker">
  <br>
  <a href="https://ollama.com">
    <img src="https://img.shields.io/badge/translation-Ollama-7C3AED" alt="Ollama">
  </a>
  <a href="https://github.com/heygen-com/hyperframes">
    <img src="https://img.shields.io/badge/video-HyperFrames-FF6B35" alt="HyperFrames">
  </a>
  <a href="https://github.com/ManimCommunity/manim">
    <img src="https://img.shields.io/badge/animations-Manim-FFD83D" alt="Manim">
  </a>
  <a href="https://github.com/m-bain/whisperX">
    <img src="https://img.shields.io/badge/subtitles-WhisperX-2EA44F" alt="WhisperX">
  </a>
  <a href="https://github.com/pumacp/puma-info/releases/latest">
    <img src="https://img.shields.io/github/v/tag/pumacp/puma-info?label=release" alt="Latest release">
  </a>
  <br>
  <a href="https://github.com/pumacp/puma">
    <img src="https://img.shields.io/badge/PUMA-Platform-blue" alt="PUMA Platform">
  </a>
  <a href="https://github.com/pumacp/puma-community">
    <img src="https://img.shields.io/badge/PUMA-Community-orange" alt="PUMA Community">
  </a>
</p>

<p align="center">
  <sub><strong>PUMA Platform</strong></sub><br>
  <a href="../../wiki">Wiki</a> ·
  <a href="CONTRIBUTING.md">Contribute</a> ·
  <a href="../../issues">Issues</a>  
  <a href="https://pumacp.github.io/puma">PUMA</a> ·
  <a href="https://pumacp.github.io/puma-community">PUMA Community</a> ·
  <a href="https://pumacp.github.io/puma-vault">PUMA Vault</a>
</p>

<p align="center">
  <sub><strong>PUMA Info</strong></sub><br>
  <a href="https://www.youtube.com/@PUMA_Project">YouTube</a> ·
  <a href="https://github.com/pumacp/puma-info/wiki">PUMA Info Wiki</a> ·
  <a href="https://github.com/pumacp/puma-community/wiki">PUMA Community Wiki</a> ·
  <a href="https://drive.google.com/drive/folders/1TKbYhYqLIrq7liAPlSF7ztS2Bv0l7vZS?usp=sharing">Drive (info)</a>  
</p>

<p align="center">
  <sub><strong>PUMA Contact</strong></sub><br>
  <a href="https://www.reddit.com/r/pumaproject/">Reddit</a> ·
  <a href="https://discord.gg/fVhcpHREJv">Discord</a> ·
  <a href="https://github.com/pumacp/puma-community/discussions">GitHub Discussions</a> ·
  <a href="https://x.com/puma__project">Twitter/X</a> ·
</p>

<br>

## What this repository does

`puma-info` is the public information production pipeline of the
**PUMA Project**. It turns specifications into reproducible,
multi-format artifacts in multiple languages:

- **Videos** for the [PUMA YouTube channel](https://www.youtube.com/@PUMA_Project) — composed with HyperFrames, narrated with Piper TTS (English) or XTTS v2 (multilingual voice cloning), subtitled with WhisperX, published via the YouTube Data API.
- **Translated PDFs** — academic and technical documents about PUMA, translated from Spanish to English (and other languages) with PDFMathTranslate + Ollama, preserving layout, tables and equations.
- **Slides and posters** — generated from Markdown via Marp and Pandoc, including **editable `.pptx`** (real shapes and text, via Pandoc) and `.pptx` import (via LibreOffice).
- **Infographics and diagrams** — Manim Community Edition for mathematical animations, Mermaid CLI for system diagrams, Inkscape for SVG batch processing.
- **Documentation** — Quarto for academic multi-format publishing (PDF, HTML, slides) from a single Markdown source.
- **Format conversion & Google interop** — `video-convert` (mp4/webm/mov, with optional resolution scaling), `doc-ingest`/`pptx-ingest` to bring Google Docs/Slides exports back into the pipeline, and `slides-export` to produce editable Google Slides.

## How it works

All tools run inside isolated Docker containers under the
`puma_info_network` bridge. The repository is self-contained: any
operator with Docker and the NVIDIA Container Toolkit can clone,
build, and regenerate every artifact from its pinned sources.
Benchmarking results are bit-exact on the same hardware/runtime; generated
media (audio, video, transcription) is functionally reproducible but not
byte-identical (see [`docs/REPRODUCIBILITY_REPORT.md`](docs/REPRODUCIBILITY_REPORT.md)).

**Spec-Driven Production** is applied throughout: JSON specs and
Markdown documents are the source of truth; MP4s, PDFs, PPTXs and
PNGs are regenerable derivatives.

**Projects: public and private.** The repository root is the default
public project. Named projects coexist as `public/<id>/` (tracked and
publicly verifiable) and `_private/<id>/` (git-ignored, with its own
independent nested git and an isolated AI-use log); each target routes
its output into that project's own tree.

**Workspace model.** A project organises material by role —
`primary/` (mutable canonical source-of-truth), `context/` (immutable
research/reference), `prompts/` (per-project generation prompts that turn
inputs into outputs, for input→prompt→output traceability), `output/`
(derived artifacts, by type: `docs/`, `video/`, `audio/`, `images/`,
`slides/`, `subs/`), and optional `work/` (work-in-progress) — with a
per-folder `SKILL.md` descriptor. Input enters via `sources/`/`prompts/`
and leaves via `output/`, never the reverse; **`output/` mirrors `sources/`**
(same type + sub-path), so each input visibly corresponds to what it
generated. The root `SKILL.md` is the project's **path contract**: a
machine-readable declaration of where sources, prompts, outputs and pipeline
I/O live. Today targets operate on explicit paths and built-in default dirs;
reading the contract to resolve paths automatically (and enforce the mirror)
is the documented next step — it is not yet wired, and projects without a
contract behave exactly as before. See
[`docs/design/project-workspace-taxonomy.md`](docs/design/project-workspace-taxonomy.md).

## Quick start

```bash
git clone git@github.com:pumacp/puma-info.git
cd puma-info
make help
make foundation-up
```

Then install the tool groups you need:

```bash
make translation-up    # Group B: PDF translation
make voice-build       # Group C: TTS (Piper + XTTS v2)
make video-build       # Group D: video composition (HyperFrames + Manim)
make publish-build     # Group E: subtitles + YouTube upload
make docs-build        # Group F: documents (Quarto, Marp, Mermaid, Inkscape, LibreOffice)
```

Create a named project (the repository root is the default public project):

```bash
make new-project NAME=<id> VISIBILITY=public    # tracked, publicly verifiable
make new-project NAME=<id> VISIBILITY=private    # git-ignored, own nested git
```

See [`prompts/README.md`](prompts/README.md) (the launchpad) to create a
project and produce a video, and
[`docs/conversion-and-export.md`](docs/conversion-and-export.md) for the
conversion, export and ingest targets.

See the [Wiki](https://github.com/pumacp/puma-info/wiki) for full
installation and usage guides per tool group.

## Getting started

Produce your first artifact in a named project, end to end:

```bash
# 1. Scaffold a project (gets the role layout primary/ context/ output/ work/ + SKILL.md)
make new-project NAME=demo VISIBILITY=public

# 2. Put your canonical source-of-truth under primary/
cp my-notes.docx public/demo/primary/docs/

# 3. Bring up the tools and run a target at that file; OUTDIR= lands output by type
make docs-up
make doc-ingest FILE=public/demo/primary/docs/my-notes.docx FORMAT=md OUTDIR=public/demo/output/docs

# 4. Find the result inside the project's own tree
ls public/demo/output/docs/   # derived markdown + extracted media/
```

Any target given a path (or `PROJECT=`) under `public/<id>/` or `_private/<id>/`
routes its output into that project's own tree; with no project selected, output
goes to the repository root. Each project declares its layout in the root
`SKILL.md` (path contract); until contract-resolution is wired, pass `OUTDIR=` to
place output under a declared destination (otherwise targets use their built-in
default dirs). Next steps: the project launchpad
[`prompts/README.md`](prompts/README.md), the full conversion/export matrix
[`docs/conversion-and-export.md`](docs/conversion-and-export.md), the workspace
model [`docs/design/project-workspace-taxonomy.md`](docs/design/project-workspace-taxonomy.md),
and video authoring [`docs/video-rules.md`](docs/video-rules.md).

## Tool groups

| Group | Purpose | Components |
|---|---|---|
| A · Foundation | Workspace + isolated network | docker, git, gh |
| B · Translation | Multi-language document translation | PDFMathTranslate, Ollama (qwen2.5:7b), LibreTranslate |
| C · Voice | Narration synthesis | Piper TTS (CPU), XTTS v2 (GPU) |
| D · Video | Composition and rendering | HyperFrames, Manim CE |
| E · Publish | Transcription and YouTube upload | WhisperX, YouTube Data API v3 |
| F · Documents | Multi-format academic publishing | Quarto, Pandoc, Marp, Mermaid, Inkscape, LibreOffice |
| G · Imagery (optional) | Image generation | Stable Diffusion 1.5 |

Each group is installed independently. See the group READMEs under
`stacks/<group>/` and the dedicated Wiki pages.

## Conversion & export

Convert and bridge formats with already-installed tools: document
conversion (Pandoc/Quarto), video format and resolution (`video-convert`),
editable Slides export (`slides-export`), and Google Docs/Slides import
(`doc-ingest`, `pptx-ingest`). See
[`docs/conversion-and-export.md`](docs/conversion-and-export.md).

## Sister repositories in the PUMA Project

GitHub:

- [pumacp/puma](https://github.com/pumacp/puma) — reproducible local-LLM benchmarking framework for ICT Project Management tasks
- [pumacp/puma-community](https://github.com/pumacp/puma-community) — public submission hub for community-contributed results
- [pumacp/puma-vault](https://github.com/pumacp/puma-vault) — PUMA Research Vault (knowledge graph)

Hugging Face Spaces:

- [pumaproject/puma-leaderboard](https://huggingface.co/spaces/pumaproject/puma-leaderboard)
- [pumaproject/puma-verifier](https://huggingface.co/spaces/pumaproject/puma-verifier)

## Constitution

This subproject follows the principles in [`docs/constitution.md`](docs/constitution.md): isolation, reproducibility, Spec-Driven Production, trustworthy AI usage, local-first execution, approval gates, open licensing, GPU mutual exclusion, public/private separation, neutral naming.

## License

MIT. See [LICENSE](LICENSE).
