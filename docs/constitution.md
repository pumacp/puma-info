# puma-info Constitution

These rules are non-negotiable for this subproject. Any change
requires an ADR documenting the exception.

## C-1 · Isolation
No resource without `puma_info_*` prefix or `puma_info=true` label
may be created or modified by this subproject. Existing PUMA
Project resources are read-only.

## C-2 · Reproducibility
Reproducibility is scoped by artifact class:
- **Benchmarking results** are reproducible bit-exact on the same
  hardware-and-runtime profile — fixed seed and `temperature=0.0`, a
  prompt-hash cache, versions pinned in `versions.lock`, and a predictions
  hash that gates releases.
- **Generated media and documents** (TTS audio, video, GPU transcription,
  rendered PDF/PPTX/PNG) are functionally reproducible — regenerable from
  pinned sources and specs — but not guaranteed byte-identical, because of
  generative sampling, GPU non-determinism, and toolchain timestamps.
- **Energy and timing** measurements are inherently run-to-run variable.

Image digests are pinned in `versions.lock`; random seeds are fixed wherever
a stage supports them.

## C-3 · Spec-Driven Production
Specs (`specs/*.json`, `documents/*.qmd`, `prompts/*.md`,
`manim_scenes/*.py`) are the source of truth. Outputs are
derivatives that may be regenerated.

## C-4 · Marco Veritas
Every significant AI-tool interaction is logged in
`docs/ai-use-log.md`. No fabricated references, statistics,
quotes, or attributions are committed.

## C-5 · Local-first
All compute happens on the local machine. No mandatory cloud
service, no API key required for the core pipeline. Optional
fallbacks (YouTube upload API) are clearly marked and isolated.

## C-6 · Approval gates
Destructive or expensive operations (PDF batch translation, video
render, YouTube upload) require an `approvals/<step>_approved`
marker file created by the user before the corresponding
Makefile target can proceed.

## C-7 · Open license
All code and documentation in this repository ships under the
MIT License, consistent with other PUMA Project repositories.

## C-8 · GPU mutual exclusion
With 6 GB VRAM, only one GPU-heavy service runs at a time.
`make gpu-release` is mandatory before starting another.
