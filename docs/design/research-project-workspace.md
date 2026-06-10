# Design: research-project workspace + media pipeline

> Design document. It records decisions and the target model; it does **not**
> change code. Anything marked *deferred* or *gated* is intentionally left for a
> separate, approved increment.

## 1. Purpose & scope

puma-info is evolving from a media pipeline into a **research-project manager
plus media pipeline**: a place where each project — public or private — is a
self-contained, navigable workspace that holds its own source-of-truth, prompts,
produced artifacts and traceability, kept separate from the application code
(the Docker stacks and orchestrator).

This document **decides**:

- the naming convention for the private zone (`_private/`),
- that projects are self-contained (their source lives inside the repository),
- how the prompt launchpad and per-project authoring are organised,
- how the AI-use log is routed for public vs private projects.

This document **defers** (states intent, does not implement):

- a single per-project source-of-truth convention (`sources/`) that would close
  the current fragmentation (gap #4b),
- the migration of the private academic material into a private project — a
  one-way operation gated behind a separate approved plan.

It does not modify any merged code, Makefile target, compose file, orchestrator
script, `.gitignore`, or `templates/`. Every capability it cites already exists
in the repository and is referenced by file or Makefile target.

## 2. Target model

**One project = one self-contained, navigable workspace.** A project owns its
inputs, its prompts, its produced artifacts and its traceability; the
application code (stacks under `stacks/A-…G-`, orchestrator under
`orchestrator/scripts/`) is shared infrastructure that operates *on* projects
but lives *outside* them.

Mapped onto the real repository:

- **Public projects** live under `public/<id>/` (tracked, publicly verifiable).
- **Private projects** live under `_private/<id>/` (git-ignored; see §3).
- **The repository root is itself the default public project** — every target
  works exactly as before when no project is selected (see
  `prompts/README.md` and `docs/conversion-and-export.md`).
- **Project skeleton:** `templates/project/` provides the per-project subtree
  copied by `make new-project` (Makefile `new-project`, L327). It contains the
  five input directories `compositions/`, `documents/`, `manim_scenes/`,
  `scripts/` and `specs/` (each with a `.gitkeep`), a `scripts/_template/` with
  `rules.md` and `script.md`, and a `README.md`. `output/` and `docs/` are
  created at runtime.
- **The Group A–G stacks operate on the selected project's tree.** Group A is
  the isolated network; B translation; C voice; D video; E publish; F documents.
  Group G (imagery) is omitted (no stack, absent from `versions.lock`). Output is
  routed into the project's own tree by the per-project derivation in the
  Makefile conversion targets and in the orchestrator's `apply_project()` (see
  §3 and §4).

The user flow the model enables: edit a source document inside a project and,
through prompts, both correct the originals and produce derived material, with
full traceability and explicit public/private visibility.

## 3. Public/private model

### 3.1 `_private/` naming — decision: keep (option b)

The private zone keeps the `_private/` name. The leading underscore denotes a
**git-ignored zone**: `.gitignore` ignores `_private/` outright (the rule
`_private/`), so nothing under it is ever published. Named private projects are
`_private/<id>/`.

*Rationale.* Renaming to a symmetric `private/` would touch every merged
surface that hard-codes the `_private` segment — the conversion targets and
`new-project` in the Makefile, the `(public|_private)/<id>` matching in the three
orchestrator scripts, the six compose mounts that resolve `../../_private`, the
`.gitignore` rule, and the docs — and would additionally disturb the independent
nested git repository that already exists under `_private/wiki-staging`. The
cost is high and the benefit cosmetic, so the name stays and the convention is
documented here instead.

### 3.2 Self-containment — decision: self-contained (option A)

A project's source-of-truth lives **inside the repository**: public projects
under `public/<id>/`, private projects under `_private/<id>/`. There is no
default mount of any tree outside the repository.

*Rationale.* This matches the code reality. The Group C, D, E and F compose
files mount `../../public` and `../../_private` — i.e. `puma-info/public` and
`puma-info/_private` — and Group D's manim service mounts `../../manim_scenes`
plus the same public/private trees under `/manim`. No stack mounts anything
outside the repository, so self-containment is the model the stacks already
enforce. (An external opt-in mount was considered and rejected for the default
path because it would break clone-reproducibility; see §8/§9.)

### 3.3 Prompt launchpad & per-project authoring — see §6.

### 3.4 AI-use-log routing — decision: central for public/root (option i)

The AI-use log is **central** for the root project and for public projects
(`docs/ai-use-log.md`), and **per-project only for private projects**
(`_private/<id>/docs/ai-use-log.md`).

*Grounding.* Each orchestrator script defaults `AI_USE_LOG` to the root
`docs/ai-use-log.md` and reassigns it to the per-project path **only** when the
selected project is private — the guard `if project.startswith("_private/"):`
in `02_generate_narration.py:67`, `03_render_video.py:55` and
`04_generate_subtitles.py:48`. Public and root runs therefore log centrally;
this design records that existing behaviour as intentional rather than changing
it.

## 4. Source-of-truth: current state vs target

### Current state — fragmentation (gap #4b)

Today a project's "source" is spread across five per-tool input directories,
both at the repository root and inside every project created from
`templates/project/`: `compositions/`, `documents/`, `manim_scenes/`,
`scripts/` and `specs/`. The constitution reflects this fragmentation directly:
**C-3** (`docs/constitution.md:16-19`) names the source of truth as
`specs/*.json`, `documents/*.qmd`, `prompts/*.md` and `manim_scenes/*.py` — four
different locations. There is no single entry point per project; an author must
know which tool reads from which directory.

### Target — a `sources/` convention (DEFERRED, design intent only)

The intended resolution of gap #4b is a per-project **`sources/`** directory
that serves as the single, human-facing entry point for a project's
source-of-truth, from which the existing per-tool inputs are derived or
organised. This is **design intent, not yet implemented**: it would be a future
**additive** increment (a new directory in `templates/project/`, documentation,
and — only if chosen — optional input-resolution wiring). Nothing in the current
pipeline is changed by this document; the five input directories above remain
exactly as they are until that increment is designed and approved.

## 5. Prompt-driven flow

The model is: **inputs in many formats → prompts → outputs of many types**, with
traceability (the AI-use log, §3.4) and explicit public/private visibility
(§3.1–3.2). The conversion surface that realises this already exists and is
documented in `docs/conversion-and-export.md`; it is referenced here, not
re-specified:

- **Documents / slides / diagrams:** the Group F targets `quarto-render`
  (L267), `marp-render` (L273), `mermaid-render` (L279), `inkscape-convert`
  (L285) and `pandoc-convert` (L291).
- **Editable slides & Google interop:** `slides-export` (L343, editable `.pptx`
  via Pandoc), `pptx-ingest` (L351, `.pptx` import via LibreOffice), `doc-ingest`
  (L321, `.docx` → Markdown/HTML). The `.pptx → Markdown` path is the documented
  two-step bridge (LibreOffice → HTML, then `quarto pandoc`), not an
  auto-chained target — see `docs/conversion-and-export.md`.
- **Video format conversion:** `video-convert` (L300, ffmpeg, optional
  resolution scaling).

Each of these auto-routes its output into the selected project's tree when the
input path is under `public/<id>/` or `_private/<id>/` (the per-project OUTDIR
derivation in the Makefile; mirrored by `apply_project()` in the orchestrator).
Prompts orchestrate these targets; the targets themselves are unchanged.

## 6. Prompt launchpad model

- **Global launchpad:** `prompts/README.md` is the single entry point for
  creating a project and producing a video. The intent (§3.3) is to consolidate
  the launchpad there; the existing `prompts/00_overview.md` and
  `prompts/01_presentation.md` remain as pointers. Any actual consolidation is a
  later **additive** docs edit — this document only states the intended model and
  does not perform it.
- **Per-project authoring** already lives inside each project at
  `<project>/scripts/<video-id>/{rules.md, script.md}`, created from
  `templates/project/scripts/_template/`. For private projects this content is
  git-ignored by virtue of living under `_private/`, so there is no leakage.
  General authoring rules are in `docs/video-rules.md`.

## 7. Decision log

| # | Decision | Option chosen | Rationale | Risk | Status |
|---|----------|---------------|-----------|------|--------|
| 3.1 | Private-zone naming | Keep `_private/`, document `_` = git-ignored zone | Renaming touches all merged code + the nested `_private/wiki-staging` git; benefit cosmetic | Low | Resolved |
| 3.2 | Project scope | Self-contained; source under `public/<id>/` or `_private/<id>/` | No stack mounts any external tree; compose mounts resolve to `puma-info/_private` | Low | Resolved |
| 3.3 | Prompt launchpad | Consolidate in `prompts/README.md`; per-project authoring under `<project>/scripts/<video>/` | Single entry point; per-project content already isolated | Low | Resolved (consolidation = later additive edit) |
| 3.4 | AI-use-log routing | Central for public/root; per-project for `_private/*` | Matches existing orchestrator guard `startswith("_private/")` | None | Resolved |
| 3.5 | Single source-of-truth | Proposed `sources/` convention | Closes gap #4b; additive | Low | **Deferred** (design intent, not implemented) |
| 3.6 | Academic material | **Migrate** into `_private/<id>/` as a self-contained private project | Self-containment (3.2); preserves traceability and visibility | High / irreversible | **Decided, deferred & gated** |

## 8. Deferred & gated work

- **§3.5 — `sources/` convention (additive, later).** Introduce a single
  per-project source-of-truth entry point that resolves the fragmentation in §4.
  To be designed and approved as its own additive increment; no pipeline path
  changes until then.
- **§3.6 — Academic-material migration (irreversible, gated).** The decision of
  record is to migrate the private academic material into a private project
  under `_private/<id>/`, self-contained per §3.2. This is a **one-way
  (irreversible) operation** and is **not performed in this increment**. It is
  gated behind a separate, approved migration plan, with the preconditions:
  verified backups already in place, the original source left untouched until
  the migrated copy is validated, and traceability preserved. Because the
  destination is under `_private/`, the migrated material remains git-ignored and
  is never published.

## 9. Invariants honoured

This design respects the project invariants:

- **Clone-reproducibility** — public projects keep tracked inputs and
  regenerable outputs; `versions.lock` pinning is untouched. Self-containment
  (§3.2) keeps public projects reproducible from a clone.
- **Commit identity** — `pumacp <266590835+pumacp@users.noreply.github.com>`;
  no AI trailers, no personal identifier.
- **CLI-local merge** — branch from `main` → commit → merge `--ff-only` → push;
  never via the GitHub API.
- **Constitution** (`docs/constitution.md`) — isolation, reproducibility,
  Spec-Driven Production, the AI-use log (Marco Veritas), local-first, approval
  gates, open license, and GPU mutual exclusion all stand; nothing here weakens
  them.
- **No break to existing functionality** — this is a docs-only, additive
  document; defaults remain byte-identical because no code path is modified.
- **Design-then-implement with gates** — this document is the design step;
  §3.5 and §3.6 are explicitly held for separate, approved increments.
