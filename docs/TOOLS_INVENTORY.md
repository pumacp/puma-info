# puma-info Tools Inventory

Generated 2026-06-05. Source of truth: `versions.lock`.

## Scope

This document enumerates every tool, runtime, library, and model
weight used by the puma-info subproject across Groups A through F.
For each entry: pinned version, Docker image digest (where
applicable), license, and source URL. Use this inventory together
with `versions.lock` to verify a reproducible installation.

## Group A · Foundation

(System-level tools, not Docker-managed)

| Tool | Pinned | License | Source |
|---|---|---|---|
| Docker Engine | 24.0+ | Apache-2.0 | https://www.docker.com |
| git | 2.43+ | GPL-2.0 | https://git-scm.com |
| gh CLI | 2.40+ | MIT | https://cli.github.com |

## Group B · Translation

| Tool | Pinned | Image / Package | License | Source |
|---|---|---|---|---|
| Ollama | 0.5.4 | ollama/ollama:0.5.4@sha256:18bfb1d6… | MIT | https://ollama.com |
| LibreTranslate | v1.9.6 | libretranslate/libretranslate:v1.9.6@sha256:1de2d705… | AGPL-3.0 | https://libretranslate.com |
| PDFMathTranslate | 1.9.11 | byaidu/pdf2zh:1.9.11@sha256:8e083ecb… | AGPL-3.0 | https://github.com/Byaidu/PDFMathTranslate |
| qwen2.5:7b (model) | sha256:845dbda0… | — | Apache-2.0 | https://huggingface.co/Qwen/Qwen2.5-7B-Instruct |
| qwen2.5:3b (model) | sha256:357c53fb… | — | Qwen Research License Agreement | https://huggingface.co/Qwen/Qwen2.5-3B-Instruct |

## Group C · Voice

| Tool | Pinned | Image / Package | License | Source |
|---|---|---|---|---|
| Piper TTS | 1.4.2 | (local image) | MIT | https://github.com/rhasspy/piper |
| en_US-amy-medium voice | (pinned model) | — | MIT | https://huggingface.co/rhasspy/piper-voices |
| Coqui TTS | 0.27.5 | (local image) | MPL-2.0 | https://github.com/coqui-ai/TTS |
| XTTS v2 (weights) | (pinned commit) | — | CPML | https://huggingface.co/coqui/XTTS-v2 |
| torch | 2.7.1+cu126 | wheel index cu126 | BSD-style | https://pytorch.org |
| nvidia/cuda base | 12.6.3-runtime-ubuntu24.04@sha256:92906d87… | — | NVIDIA SLA | https://hub.docker.com/r/nvidia/cuda |
| transformers | 4.57.6 | — | Apache-2.0 | https://github.com/huggingface/transformers |

## Group D · Video

| Tool | Pinned | Image / Package | License | Source |
|---|---|---|---|---|
| HyperFrames | 0.6.74 | npm @ Node 22 | Apache-2.0 | https://github.com/heygen-com/hyperframes |
| node:22-bookworm-slim | sha256:7af03b14… | — | MIT (Node) | https://hub.docker.com/_/node |
| chromium (debian) | 148.0.7778.215-1~deb12u1 | — | BSD-style | https://chromium.org |
| Manim Community Edition | 0.20.1 | manimcommunity/manim:v0.20.1@sha256:f18f53f2… | MIT | https://www.manim.community |

## Group E · Publish

| Tool | Pinned | Image / Package | License | Source |
|---|---|---|---|---|
| WhisperX | 3.8.6 | (local image) | BSD-2-Clause | https://github.com/m-bain/whisperX |
| faster-whisper (transitive) | 1.2.0+ | pypi | MIT | https://github.com/SYSTRAN/faster-whisper |
| CTranslate2 (transitive) | 4.5.0+ | pypi | MIT | https://github.com/OpenNMT/CTranslate2 |
| Whisper large-v3 (model) | (pinned weights) | — | MIT | https://huggingface.co/openai/whisper-large-v3 |
| torch | 2.8.0+cu126 | wheel index cu126 | BSD-style | https://pytorch.org |
| python:3.12-slim | sha256:090ba77e… | — | PSF | https://hub.docker.com/_/python |
| google-api-python-client | 2.197.0 | pypi | Apache-2.0 | https://github.com/googleapis/google-api-python-client |
| google-auth | 2.53.0 | pypi | Apache-2.0 | https://github.com/googleapis/google-auth-library-python |
| google-auth-oauthlib | 1.4.0 | pypi | Apache-2.0 | (same org) |
| google-auth-httplib2 | 0.4.0 | pypi | Apache-2.0 | (same org) |
| jsonschema | 4.26.0 | pypi | MIT | https://github.com/python-jsonschema/jsonschema |

## Group F · Documents

| Tool | Pinned | Image / Package | License | Source |
|---|---|---|---|---|
| Quarto | 1.9.38 | ghcr.io/quarto-dev/quarto:1.9.38@sha256:cdc12093… | GPL-2.0 | https://quarto.org |
| TinyTeX | v2026.06 | (installed in Quarto image) | LPPL | https://yihui.org/tinytex |
| Pandoc (bundled with Quarto) | (Quarto-bundled) | — | GPL-2.0-or-later | https://pandoc.org |
| Marp CLI | 4.4.0 | npm @ Node 22 | MIT | https://github.com/marp-team/marp-cli |
| Mermaid CLI | 11.15.0 | npm @ Node 22 | MIT | https://github.com/mermaid-js/mermaid-cli |
| debian:bookworm-slim | sha256:0104b334… | — | (various, per package) | https://hub.docker.com/_/debian |
| Inkscape | 1.2.2-2+b1 | apt @ bookworm | GPL-3.0 | https://inkscape.org |

## Group G · Imagery — NOT INSTALLED

Group G (Stable Diffusion 1.5 for YouTube thumbnails) was
evaluated but skipped from the current iteration. Equivalent
functionality is achieved via:

  - HyperFrames (Group D) for static composition rendering
  - Inkscape (Group F) for SVG-based thumbnails

May be added in a future iteration if the alternatives prove
insufficient.

## Locally built images

| Image | Tag | ID | Built from |
|---|---|---|---|
| pumacp/puma-info-piper | 0.1.0 | (see versions.lock) | Group C |
| pumacp/puma-info-xtts | 0.1.0 | (see versions.lock) | Group C |
| pumacp/puma-info-hyperframes | 0.1.0 | (see versions.lock) | Group D |
| pumacp/puma-info-manim | 0.1.0 | (see versions.lock) | Group D |
| pumacp/puma-info-whisperx | 0.1.0 | (see versions.lock) | Group E |
| pumacp/puma-info-uploader | 0.1.0 | (see versions.lock) | Group E |
| pumacp/puma-info-quarto | 0.1.0 | (see versions.lock) | Group F |
| pumacp/puma-info-marp-mermaid | 0.1.0 | (see versions.lock) | Group F |
| pumacp/puma-info-inkscape | 0.1.0 | (see versions.lock) | Group F |

## Summary by license

(Aggregate count; see `LICENSE_MATRIX.md` for compatibility
analysis.)

  - MIT: 14 entries
  - Apache-2.0: 10 entries
  - GPL-2.0 / GPL-2.0+ / GPL-3.0: 4 entries
  - BSD-2/BSD-style: 5 entries
  - MPL-2.0: 1 entry
  - LPPL: 1 entry
  - AGPL-3.0: 2 entries
  - CPML (academic/non-commercial): 1 entry (XTTS weights)
  - Qwen Research License Agreement: 1 entry (qwen2.5:3b weights, research/academic only)
  - PSF, NVIDIA SLA, various: bookkeeping

## See also

- `docs/LICENSE_MATRIX.md` — license compatibility analysis
- `docs/REPRODUCIBILITY_REPORT.md` — pinning and verification protocol
- `versions.lock` — machine-readable pin source of truth
