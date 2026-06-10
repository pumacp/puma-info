# Design: project workspace — primary / secondary / derived + SKILL descriptors

> Design document. It defines how a project workspace is organised and adds
> **additive, generic** templates. It supersedes the earlier role×type sketch.
> It changes no code, no target behaviour, and does not reorganise any existing
> project's files. Applies identically to `public/<id>/` and `_private/<id>/`.

## 1. Purpose & scope

A project's material falls into a few clear roles. The earlier flat, tool-oriented
layout did not separate **what is canonical and editable**, **what is fixed
background knowledge**, and **what is produced**. This document fixes the final
model around three source/output roles plus an optional working area, and adds a
per-folder **SKILL descriptor** so any agent/tool can read a folder and know what
it is and how to use it.

## 2. The model (generic; any project, public or private)

- **`sources/primary/` — MUTABLE source-of-truth.** The project's most important
  documents: authored, edited and corrected over time. This is the main basis for
  derived material. It changes; it is the canonical "current truth".
- **`sources/secondary/` — IMMUTABLE source-of-truth.** The accumulated knowledge
  from the project's earlier research/work — kept as a fixed record, never
  modified. It feeds and corrects the primary and serves as **context** for
  generation. Phase sub-organisation is natural here: optional phase subfolders
  (e.g. `01-…/`, `02-…/`) belong under `secondary/`.
- **`output/` — DERIVED material.** Everything produced from the primary (with
  secondary optionally as context): infographics, images, translations,
  animations, video, audio, slides, transcripts. Subdivide by type as needed
  (`output/video/`, `output/images/`, `output/docs/`, …). This is the produced
  role — "where the current correct output is".
- **`working/` — OPTIONAL work-in-progress.** Kept, but optional. For genuine
  scratch/drafts that are *not yet* primary, *not* secondary, and *not* a finished
  derived artifact. Lightweight; nothing here is authoritative. Justification for
  keeping it: a draft being promoted toward `primary/` needs a home that is
  clearly "not canonical yet"; without `working/`, drafts pollute `sources/`.

Type is a secondary axis expressed as subfolders *within* a role. Importance
("primary vs secondary") is a **role**, not a separate tier grid.

## 3. Provenance flow (explicit)

```
secondary  ──(distilled / corrected by the author, OUTSIDE puma-info)──▶  primary
primary    ──(puma-info generates: convert / render / synthesize)──────▶  derived (output/)
secondary  ──(available as context during generation)──────────────────▶  derived
```

- **puma-info operates on `sources/` to produce `output/`.** It does **not**
  automate `secondary → primary`; that distillation/correction is the author's
  job, done with other tools. puma-info enters once `primary/` exists, and may
  consult `secondary/` as context.
- `secondary/` is immutable: generation reads it, never writes it.

## 4. How generation and traceability actually work (verified)

The conceptual picture — "a prompt in a project folder drives generation, and
prompts give input→output traceability" — maps onto the real system as follows
(no mechanism is claimed that does not exist):

- **Generation is human/CLI-invoked, not an autonomous prompt-watcher.** The
  operator runs a `make` target (or an `orchestrator/` script) pointing at an
  input under the project (`FILE=…/sources/…`, `PROJECT=public/<id>`). There is no
  daemon that reads a prompt file and auto-produces derivatives.
- **The "prompts" are two layers:** the global launchpad `prompts/` (human
  guidance) and per-project authoring under `<project>/scripts/<video>/{rules,
  script}.md`, transcribed into the machine spec `specs/<id>.json` that the
  orchestrator consumes.
- **Traceability is real, at the input-file level.** The orchestrator records, in
  the AI-use log, the input path **and its sha256** mapped to the produced output
  (`02` logs `spec:<path>@<hash>`, `03` logs `in:<hash> out:<hash>`, `04` logs
  `in:<mp4>@<hash>`). So a produced artifact can be traced to the exact input file
  that produced it. What is **not** captured is the conversational prompt an agent
  used to author the spec — provenance is at the spec/source-file granularity.

## 5. SKILL descriptor system (per folder)

Each role folder carries a **`SKILL.md`** so any tool/agent can read it first and
know what it is working with. Fields (tool-agnostic markdown):

- **Role** — primary / secondary / derived / working.
- **Mutability** — MUTABLE or IMMUTABLE.
- **Contains** — what kind of material lives here.
- **Purpose / how to use** — how prompts/agents should treat it (e.g. "edit
  freely", "read-only context", "regenerable output").
- **Provenance** — where it comes from and what it feeds.

### Mechanism in the agent flow (verified)
`AGENTS.md` at the repository root is the **auto-read** entry point for agents.
There is **no** automatic per-folder `SKILL.md` discovery today (the only existing
"skills" are the HyperFrames capability bundle under `.agents/`, a different
concept — ADR-003). A per-folder `SKILL.md` is therefore a **read-on-entry
convention**: an agent reads a folder's `SKILL.md` before operating on that
folder, and `AGENTS.md` points agents to the convention. The format is plain
markdown so any tool can consume it; a future agent could also glob for `SKILL.md`.

Generic example `SKILL.md` templates ship in `templates/project/` (and a derived
example at the template root, since `output/` is created at runtime and
git-ignored) so any user can copy and adapt them.

## 6. Mapping to existing targets (backward-compatible)

Unchanged from the verified behaviour: the per-project OUTDIR derivation is
depth-agnostic (`proj` = first two path segments), and targets take an explicit
`FILE=` path. So pointing any target at `sources/primary/<file>` or
`sources/secondary/<file>` already routes output into `<id>/output/` with **no
code change**. Default `output/` stays flat; type subfolders are available via
`OUTDIR=` and a default-routed output remains a separate, deferred wiring step.
Existing pipeline dirs (`specs/`, `scripts/`, `manim_scenes/`, `compositions/`)
and all targets remain **byte-identical**.

## 7. public / _private symmetry

The same roles and SKILL descriptors apply to both. `.gitignore:2` ignores
`_private/` wholesale, so a private project's `SKILL.md` files and all role
subfolders stay git-ignored automatically. Compose mounts (`../../public`,
`../../_private`) reach every subfolder at any depth. No symmetry concern.

## 8. Migration sketch for an existing project (design only — not executed here)

When a migrated project is later reorganised (separate gated step, with backups):

- canonical, editable documents → `sources/primary/`;
- fixed historical research/context → `sources/secondary/` (with optional phase
  subfolders);
- produced conversions/media → `output/` (by type: `output/docs/`,
  `output/images/`, …);
- a `SKILL.md` is added to each role folder.

## 9. What this increment changes

- **Design:** this document (final model).
- **Additive/generic template:** `templates/project/` gains generic `SKILL.md`
  descriptors for `sources/primary/`, `sources/secondary/`, `working/`, and a
  derived-output example; the interim type-subfolders under `sources/` are
  replaced by the `primary/`/`secondary/` roles.
- **Deferred (separate increments):** default type-routed `output/`; physically
  moving pipeline dirs under roles; reorganising any existing project.

## 10. Invariants honoured

- **No-break / byte-identical:** existing dirs and every target behave exactly as
  before; new dirs/descriptors are read by no target automatically.
- **Reproducibility & public/private model** unchanged; `_private/` git-ignored;
  compose reachability preserved.
- **Design-then-implement with gates:** heavier moves are deferred to approved
  increments.
