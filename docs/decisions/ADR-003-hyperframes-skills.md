# ADR-003 · HyperFrames skills installation and composition isolation

Status: Accepted
Date: 2026-06-05
Context: puma-info produces ten divulgative videos (and possibly more)
with HyperFrames. HyperFrames ships an agent skill bundle that guides a
coding agent through composition. We need a reproducible, per-composition
way to make those skills available without coupling to one specific agent.

## Decision

  - The HyperFrames skill bundle is installed into a template directory,
    `compositions/_template/`, via `make video-install-skills` (which runs
    the upstream installer `npx skills add heygen-com/hyperframes` inside
    puma_info_hyperframes).
  - The installer (`skills` CLI) writes an agent-agnostic bundle under
    `compositions/_template/.agents/skills/` (some agents instead use
    `.claude/skills/`). The bundle is NOT tracked in git: it is regenerated
    locally per checkout. This keeps the public remote free of any
    AI-assistant-brand trace, while still giving operators a ready-to-use
    template.
  - Each video gets its own directory created by copying the template
    (`make video-new-composition NAME=<id>`), so every composition is
    self-contained and isolated; render artifacts never leak between videos.
  - Per-composition build artifacts (`node_modules/`, `.hyperframes/`,
    `render/`, `preview/`, `.agents/`, `.claude/`) are gitignored; only
    authored composition source is tracked.
  - The skill bundle is agent-agnostic: it is consumed by whichever coding
    agent the operator opens the composition with. No specific agent product
    is required or named in committed files.

## Consequences

  - New videos start from a consistent, skills-equipped baseline.
  - The template is refreshed by re-running the installer; the pinned bundle
    commit is recorded in `versions.lock`.
  - A fresh checkout must run `make video-install-skills` once before
    `make video-new-composition` (the Makefile target enforces this).
