# puma-info — Agent operating instructions

You are working inside the `puma-info` subproject of the PUMA
Project, at the puma-info repository root. This subproject produces
public, multi-format, multi-language information artifacts about
PUMA: videos, translated PDFs, slides, posters, infographics,
documentation sites.

## Critical isolation rules

  - DO NOT touch any container, network, volume, image, or process
    outside the `puma_info_*` namespace.
  - DO NOT bind to ports outside the allowed ranges:
    11435, 3001-3099, 5000-5099, 7860-7869.
  - Existing PUMA resources to leave alone:
    containers `puma_runner`, `puma_dashboard`, `puma_ollama`;
    network `puma_network`; volumes `puma_ollama_models`,
    `puma_puma_data`; port 11434.

## Plan-Approve-Execute-Verify

For any change involving file creation, Docker resources, package
installation, or git operations:

  1. Analyze with read-only commands.
  2. Plan: list every change with full content and commands.
  3. Stop and print
     "Plan ready. Reply 'approved' to execute."
  4. Execute only after `approved`.
  5. Verify with evidence (commands, listings).

If in doubt, stop and ask.

## Naming conventions

  - Containers: `puma_info_<service>`
  - Network: `puma_info_network`
  - Volumes: `puma_info_<purpose>`
  - Images: `pumacp/puma-info-<service>:<version>`
  - Every Docker resource: label `puma_info=true`

## GPU mutual exclusion

The host has an NVIDIA RTX 2060 with ~6 GB VRAM. Only ONE GPU-heavy
service can run at a time. Before starting any GPU service, the
agent runs `make gpu-status` and `make gpu-release` if another GPU
service is active.

## Reproducibility

  - Every Docker image pinned by digest in `versions.lock`.
  - Every Python/npm dependency pinned.
  - Every significant operation logged in `docs/ai-use-log.md`.
  - Every render command logs SHA-256 of inputs and outputs.

## Repositories to reference (read-only, for documentation lookup)

  - https://github.com/heygen-com/hyperframes (Apache 2.0)
  - https://github.com/PDFMathTranslate/PDFMathTranslate
  - https://github.com/OHF-Voice/piper1-gpl
  - https://github.com/coqui-ai/TTS (XTTS v2)
  - https://github.com/m-bain/whisperX
  - https://github.com/quarto-dev/quarto-cli
  - https://github.com/ManimCommunity/manim
  - https://github.com/marp-team/marp-cli
  - https://github.com/argosopentech/argos-translate
  - https://github.com/LibreTranslate/LibreTranslate
  - https://github.com/AUTOMATIC1111/stable-diffusion-webui (optional)

## Style

  - English-first for code, documentation, prompts.
  - Spanish is used only inside subtitle tracks of videos
    whose original audio is Spanish, and in localised YouTube
    descriptions targeted at Spanish-speaking audiences. Never
    in committed source files of this repository.
  - Conventional commits.
  - Constitution-style hard rules in `docs/constitution.md`.

## AI-Use-Log (Marco Veritas)

Every significant AI-tool interaction is logged in
`docs/ai-use-log.md` with: date (ISO-8601), tool family
(translation, TTS, transcription, code generation, etc.), purpose,
output summary, human validation performed. Do not name specific
agent products unless strictly necessary for technical accuracy.
