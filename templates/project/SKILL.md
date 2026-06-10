---
skill: project
contract: 1
# Machine-readable PATH CONTRACT. Every path is RELATIVE to the project root
# (public/<id>/ or _private/<id>/). All keys are OPTIONAL except sources.primary;
# when a key is absent — or when a project has no SKILL.md at all — tools fall
# back to the built-in defaults shown in comments, so existing flat projects keep
# working byte-identically.
sources:
  primary: primary       # REQUIRED — mutable canonical source-of-truth
  context: context       # optional — immutable research/reference (read-only)
outputs:
  docs: output/docs      # optional (default: output  — current hardcoded)
  video: output/video    # optional (default: output)
  audio: output/audio    # optional (default: output)
  images: output/images  # optional (default: output)
  slides: output/slides  # optional (default: output)
  subtitles: output/subs # optional (default: output)
work: work               # optional — work-in-progress staging
pipeline:                # where the video/orchestrator machine I/O lives
  compositions: compositions   # default: compositions      (current hardcoded)
  specs: specs                 # default: specs
  manim: manim_scenes          # default: manim_scenes
---

# Project — workspace contract

This file is the **project's path contract**: the single, machine-readable place
that declares where this project keeps its source-of-truth, its derived output,
and its pipeline machine I/O. Tools read it once and resolve paths from it instead
of assuming a fixed layout.

## Roles
- **`primary/`** — MUTABLE canonical source-of-truth (see `primary/SKILL.md`).
- **`context/`** — IMMUTABLE research/reference, read-only context (see `context/SKILL.md`).
- **`output/`** — DERIVED, produced artifacts, by type (`docs/`, `video/`, `audio/`,
  `images/`, `slides/`, `subs/`).
- **`work/`** — OPTIONAL work-in-progress (see `work/SKILL.md`).

## Status (what IS vs what is DESIGNED)
- **Today:** targets operate on explicit paths (`FILE=`, `SCENE=`, `--composition`,
  `--project`) and write to the built-in default dirs (`output/`, `documents/`,
  `compositions/`, `manim_scenes/media/`). Point a target at a role path and, if
  needed, pass `OUTDIR=` to land output under the declared destination.
- **Designed (not yet wired):** a later increment teaches the targets to read this
  contract and resolve `outputs.*`/`pipeline.*` automatically, falling back to the
  built-in defaults when a key or the contract is absent. Until then this file is
  the **declared convention**; see `docs/design/project-workspace-taxonomy.md`.

Adapt the paths above to your project; delete optional keys you don't use.
