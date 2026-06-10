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

## Overview

`puma-info` is the public information-production pipeline of the **PUMA
Project**. It turns specifications and source documents into reproducible,
multi-format artifacts in multiple languages — videos, translated PDFs, slides,
infographics, and documentation — for communicating and disseminating the
project's work.

Everything runs **local-first** inside isolated Docker containers: any operator
with Docker (and, for the GPU-backed groups, the NVIDIA Container Toolkit) can
clone, build, and regenerate the artifacts from pinned sources. The core
platform — a reproducible benchmark of local language models on ICT
project-management tasks — lives in [pumacp/puma](https://github.com/pumacp/puma);
this repository produces the material that explains and disseminates it.

## Features

- **Videos** for the [PUMA YouTube channel](https://www.youtube.com/@PUMA_Project) — composed with HyperFrames, narrated with Piper TTS (English) or XTTS v2 (multilingual voice cloning), subtitled with WhisperX, published via the YouTube Data API.
- **Translated PDFs** — academic and technical documents about PUMA, translated from Spanish to English (and other languages) with PDFMathTranslate + Ollama, preserving layout, tables and equations.
- **Slides and posters** — generated from Markdown via Marp and Pandoc, including **editable `.pptx`** (real shapes and text, via Pandoc) and `.pptx` import (via LibreOffice).
- **Infographics and diagrams** — Manim Community Edition for mathematical animations, Mermaid CLI for system diagrams, Inkscape for SVG batch processing.
- **Documentation** — Quarto for academic multi-format publishing (PDF, HTML, slides) from a single Markdown source.
- **Format conversion & Google interop** — `video-convert` (mp4/webm/mov, with optional resolution scaling), `doc-ingest`/`pptx-ingest` to bring Google Docs/Slides exports back into the pipeline, and `slides-export` to produce editable Google Slides.

## Quick start

Clone the repository and bring up the foundation:

```bash
git clone git@github.com:pumacp/puma-info.git
cd puma-info
make help
make foundation-up
```

Install only the tool groups you need:

```bash
make translation-up    # Group B: PDF translation
make voice-build       # Group C: TTS (Piper + XTTS v2)
make video-build       # Group D: video composition (HyperFrames + Manim)
make publish-build     # Group E: subtitles + YouTube upload
make docs-build        # Group F: documents (Quarto, Marp, Mermaid, Inkscape, LibreOffice)
```

### Produce your first artifact

```bash
# 1. Scaffold a project (creates the role layout primary/ context/ prompts/ output/ work/ + SKILL.md)
make new-project NAME=demo VISIBILITY=public     # or VISIBILITY=private for a git-ignored project

# 2. Put your canonical source-of-truth under primary/
cp my-notes.docx public/demo/primary/docs/

# 3. Bring up the tools and run a target at that file (OUTDIR= places output by type)
make docs-up
make doc-ingest FILE=public/demo/primary/docs/my-notes.docx FORMAT=md OUTDIR=public/demo/output/docs

# 4. Find the result inside the project's own tree
ls public/demo/output/docs/      # derived Markdown + extracted media/
```

Any target given a path (or `PROJECT=`) under `public/<id>/` or `_private/<id>/`
routes its output into that project's own tree; with no project selected, output
goes to the repository root. See [`prompts/README.md`](prompts/README.md) (the
launchpad) to create a project and produce a video.

## Workspace model

The repository root is the default public project; named projects coexist as
`public/<id>/` (tracked, publicly verifiable) and `_private/<id>/` (git-ignored,
with its own nested git and AI-use log). Each project organises material by
role, each with a `SKILL.md` descriptor:

- **`primary/`** — canonical source-of-truth (mutable)
- **`context/`** — research and reference (read-only)
- **`prompts/`** — generation prompts, for input→prompt→output traceability
- **`output/`** — derived artifacts, mirroring the source layout
- **`work/`** — optional work-in-progress

Input enters via `primary/`/`context/`/`prompts/` and leaves via `output/`,
never the reverse. The project's root `SKILL.md` is a machine-readable **path
contract** declaring where each role lives. The document, conversion, Manim, and
video-orchestrator targets read it (resolving `outputs.<type>`, `pipeline.manim`,
and `pipeline.compositions`); a project **without** a contract behaves
identically to a flat layout. Translation (Group B) uses its own fixed workspace,
and auto-enforcing the output↔sources mirror is the documented next step.

For the full mechanics — the path-contract keys, the per-target wiring, and the
output-mirror rule — see the
[Wiki → Architecture](https://github.com/pumacp/puma-info/wiki/Architecture) and
[`docs/design/project-workspace-taxonomy.md`](docs/design/project-workspace-taxonomy.md).

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

## Reproducibility

Reproducibility is scoped by artifact class: **benchmarking results** are
bit-exact on the same hardware/runtime; **generated media** (audio, video,
transcription) is functionally reproducible but not byte-identical; and
**energy/timing** vary. Docker images are pinned by digest and packages by
version in `versions.lock`. See
[`docs/REPRODUCIBILITY_REPORT.md`](docs/REPRODUCIBILITY_REPORT.md).

**Spec-Driven Production** is applied throughout: specs and Markdown documents
are the source of truth; MP4s, PDFs, PPTXs and PNGs are regenerable derivatives.

## Conversion & export

Convert and bridge formats with already-installed tools: document conversion
(Pandoc/Quarto), video format and resolution (`video-convert`), editable Slides
export (`slides-export`), and Google Docs/Slides import (`doc-ingest`,
`pptx-ingest`). See
[`docs/conversion-and-export.md`](docs/conversion-and-export.md).

## Documentation

- **[Wiki](https://github.com/pumacp/puma-info/wiki)** — installation and usage guides per tool group, architecture, the workspace model and path contract, reproducibility, and workflows.
- **[`docs/`](docs/)** — design notes (incl. [`project-workspace-taxonomy.md`](docs/design/project-workspace-taxonomy.md)), the [conversion/export matrix](docs/conversion-and-export.md), [video rules](docs/video-rules.md), the [reproducibility report](docs/REPRODUCIBILITY_REPORT.md), and the [constitution](docs/constitution.md).
- **[GitHub Pages](https://pumacp.github.io/puma-info/)** — the published documentation site.

## Project resources

Code repositories:

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
