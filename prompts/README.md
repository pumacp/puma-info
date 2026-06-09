# puma-info launchpad — create a project and produce a video

Entry point for producing documentation and media with puma-info. The
repository root itself is the default public project (works exactly as
before); named projects live under `public/<id>/` or `_private/<id>/`.

## 1. Author the rules and the script
- General authoring rules: [`docs/video-rules.md`](../docs/video-rules.md).
- Per-video authoring lives in `scripts/<video-id>/{rules.md, script.md}`
  (template: [`scripts/_template/`](../scripts/_template/) at the root, or
  `scripts/_template/` inside a project).

## 2. Create a project (public or private)
    make new-project NAME=<id> VISIBILITY=public      # tracked, publicly verifiable
    make new-project NAME=<id> VISIBILITY=private      # _private/<id>/, git-ignored, own nested git

This scaffolds the per-project subtree (`documents/`, `scripts/`, `specs/`,
`compositions/`, `manim_scenes/`) under `public/<id>/` or `_private/<id>/`
from `templates/project/`. Private projects also get an independent nested
git (no remote).

## 3. Produce outputs
- Documents, slides, diagrams, conversions and Google import/export:
  [`docs/conversion-and-export.md`](../docs/conversion-and-export.md)
  (`quarto-render`, `marp-render`, `mermaid-render`, `inkscape-convert`,
  `pandoc-convert`, `video-convert`, `doc-ingest`).
- Video pipeline:
  `make video-render NAME=<video-id> [PROJECT=public/<id>|_private/<id>]`,
  `make subs-<video-id> [PROJECT=...]`. Narration (`02_generate_narration`)
  takes `--project` directly on its CLI.

## How routing works
- Conversion targets and the orchestrator auto-route output into the
  project's own tree when the input path (or `PROJECT=`) is under
  `public/<id>/` or `_private/<id>/`; otherwise the repository-root
  `output/`. Without `PROJECT=`, behaviour is identical to today.
- Private projects keep their AI-use log inside their own tree
  (`<project>/docs/ai-use-log.md`); public/root log to `docs/ai-use-log.md`.

## See also
- Repository-wide hard rules: [`AGENTS.md`](../AGENTS.md),
  [`docs/constitution.md`](../docs/constitution.md).
- The default public project's authoring:
  [`scripts/01-presentation/`](../scripts/01-presentation/).
