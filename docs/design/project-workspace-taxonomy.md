# Design: project workspace taxonomy (role × type)

> Design document. It proposes how a project workspace is organised and adds an
> **additive** skeleton to `templates/project/`. It does not move or rename
> anything the targets already read, and it does not touch the migrated thesis.
> This is the full form of gap #4b, deferred by
> [`research-project-workspace.md`](research-project-workspace.md) §4/§8.

## 1. Purpose & scope

The current per-project layout is flat and tool-oriented: `sources/` plus the
five pipeline dirs (`documents/`, `specs/`, `scripts/`, `manim_scenes/`,
`compositions/`) and `output/`. It does not make the one distinction authors most
need: **what is canonical source, what is a draft/intermediate, and what is the
finished output**. This document defines a richer, role-first taxonomy that:

- cleanly separates **source-of-truth** from **working/drafts** from **produced
  output** (the main pain point);
- admits many **input types** (documents, media, data, notes) and organises
  outputs by type;
- makes it unambiguous **where the correct current output is** at any stage.

It applies identically to `public/<id>/` and `_private/<id>/`. This increment is
**design + additive template only**; reorganising the migrated thesis and any
target re-wiring are separate, later, gated increments.

## 2. The taxonomy decision

### Axes considered
- **ROLE** — source-of-truth vs working/draft vs produced output.
- **TYPE** — documents, media (audio/video/images), data, notes, slides, diagrams.
- **PHASE** — investigation → planning → design → execution → analysis → defence.
- **TIER** — primary / secondary / tertiary importance of documents.

### Evaluation of phase × type (the preferred hypothesis)
A phase axis describes the lifecycle of a **research project**, not of a
**media-production project**. A puma-info project's job is "turn source material
into videos/docs/slides/audio/subtitles/images". Most such projects have no
"investigation" or "defence" phase; forcing a six-phase grid on every project
creates **empty directories and friction**, and the same artifact often spans
phases. Phase × type is therefore **too heavy as a mandatory structure** here.

The author's actual difficulty is **role confusion** (which file is canonical vs
a draft vs the final output), which is **orthogonal to phase** and **universal**
across every project. TYPE is a light, natural secondary axis.

### Decision (recommended)
**ROLE × TYPE**, with **PHASE optional** and **TIER rejected as a mandatory axis**:

- **ROLE is the primary axis** — three top-level roles: `sources/`, `working/`,
  `output/`. This directly solves the source/draft/output separation.
- **TYPE is the secondary axis** — type subdirectories *within* a role
  (e.g. `sources/documents/`, `output/video/`).
- **PHASE is optional and free-form** — a project that genuinely has phases may
  add phase subdirectories *inside* a role (e.g. `working/01-research/`,
  `sources/phases/`); it is never required and never a top-level axis.
- **TIER is not a structural axis** — importance is already expressed by ROLE
  (canonical `sources/` vs `working/` drafts). A project that needs to rank
  documents may do so with optional naming or an optional
  `sources/documents/primary|secondary/` grouping, but the template does not
  mandate it (a rigid tier grid adds confusion without payoff).

## 3. The concrete workspace tree

```
public/<id>/            (identical for _private/<id>/)
├── sources/            ROLE: source-of-truth — canonical, authored, owned inputs
│   ├── documents/      TYPE: source docs (docx, md, pdf you maintain)
│   ├── media/          TYPE: original images, audio, footage
│   ├── data/           TYPE: datasets, csv, json source data
│   └── notes/          TYPE: research notes, references
├── working/            ROLE: drafts / intermediate / scratch (NOT canonical, NOT final)
│   └── …               free-form; optional phase subdirs (e.g. 01-research/) go here
├── output/             ROLE: produced artifacts — the current correct output
│   └── …               flat today; optional TYPE subdirs (video/ docs/ slides/
│                       audio/ subtitles/ images/) via OUTDIR — see §6 (deferred)
│
│  pipeline I/O layer (existing, kept for backward-compat; see §6):
├── specs/              machine specs the pipeline consumes (JSON)
├── scripts/            per-video authoring (<video>/{rules,script}.md)
├── manim_scenes/       Manim scene sources (+ media/ render dir)
├── compositions/       HyperFrames composition dirs
└── docs/               this project's AI-use log (private) + provenance
```

The three **roles** are the contract; the **type** subdirectories under each are
conventions an author can use as needed (empty ones can be deleted per project).

## 4. Roles defined + input↔output clarity

- **`sources/` = source-of-truth.** The canonical inputs you author and own. If
  it is the authoritative version of something, it lives here. For a private
  project this is the precious material (handle with backups).
- **`working/` = drafts / intermediate.** Anything in progress, scratch, or
  machine-intermediate that is *neither* the canonical source *nor* the finished
  artifact. Nothing here is authoritative; it can be regenerated or discarded.
- **`output/` = produced artifacts.** The **current correct output** of the
  pipeline. "Where is the finished video / document / slides?" → always
  `<id>/output/`. Drafts never live here.

This removes the ambiguity: **canonical → `sources/`, in-progress → `working/`,
finished → `output/`.** A reviewer opening a project reads `output/` for results,
`sources/` for what they were built from, and ignores `working/`.

## 5. Type axis

Types are: **documents**, **media** (audio / video / images), **data**, **notes**
(under `sources/`); and **video / docs / slides / audio / subtitles / images**
(under `output/`). Types are a navigation aid, not a hard schema — a project uses
the subset it needs.

## 6. Mapping to existing targets (backward-compatible)

The per-project OUTDIR derivation is **depth-agnostic**: for any input path it
computes the project as the first two path segments
(`case "$FILE" in public/*/*|_private/*/*) proj=$(… cut -d/ -f1-2)`), so a path at
**any depth** routes correctly — verified:

| Input path | Routes output to |
|---|---|
| `public/<id>/sources/documents/x.docx` | `public/<id>/output` (or `…/documents` for ingest) |
| `_private/<id>/sources/media/a.png` | `_private/<id>/output` |
| `public/<id>/working/drafts/y.md` | `public/<id>/output` |

Targets take an **explicit `FILE=` path**; they do not enumerate a fixed input
directory. Therefore:

- **Pointing any target at `sources/<type>/<file>` already works** and routes
  output into the project tree — **no code change needed**, fully backward
  compatible. Existing flat dirs and all targets remain **byte-identical**.
- **`output/` stays flat by default** (targets write to `<id>/output/`). Output
  *type* subdirectories (`output/video/`, `output/slides/`, …) are available
  **per call** today via `OUTDIR=<id>/output/video` (the documented override).
  Making type-routed output the **default** would change where targets write →
  that is a **separate, medium-risk wiring increment**, explicitly **deferred**
  (do not do it here).
- The existing **pipeline I/O dirs** (`specs/`, `scripts/`, `manim_scenes/`,
  `compositions/`, and the produced `documents/`) are kept exactly where the
  targets expect them. In role terms they are *working/intermediate* (`specs/`,
  `scripts/`, `manim_scenes/`, `compositions/`) and *produced* (`documents/`);
  **physically moving** them under `working/`/`output/` would change target paths
  → also a **deferred** increment. This design positions the new role dirs
  **around** them additively.

## 7. public / _private symmetry

The same tree applies to both. `.gitignore:2` ignores `_private/` wholesale, so
every subdirectory of a private project (including the new role/type dirs) is
git-ignored automatically. The Group C/D/E/F compose files mount `../../public`
and `../../_private`, so all subdirectories — at any depth — are reachable inside
the containers. No symmetry or reachability concern is introduced.

## 8. Migration sketch (design only — NOT executed here)

When the migrated thesis is later reorganised (separate gated increment, with
backups, original untouched until validated):

- the 15 canonical `.docx` → `sources/documents/` (source-of-truth);
- their converted `.md` + extracted `media/` → `output/docs/` (produced);
- any scratch/intermediate → `working/`;
- the per-project AI-use log + manifests → `docs/`.

This is a forward plan; this increment does not move the thesis.

## 9. What this increment changes

- **Additive template only:** `templates/project/` gains `sources/{documents,
  media,data,notes}/` and `working/` (with `.gitkeep` + short READMEs explaining
  the roles). Existing template dirs are untouched.
- **Deferred (separate increments):** default type-routed `output/`; physically
  moving `specs/`/`scripts/`/etc. under role dirs; reorganising the thesis.

## 10. Invariants honoured

- **No-break / byte-identical:** existing dirs and every target behave exactly as
  before; the new dirs are organisational and read by no target automatically.
- **Reproducibility & public/private model** unchanged; `_private/` stays
  git-ignored; compose reachability preserved.
- **Design-then-implement with gates:** the heavier moves (wiring, thesis
  reorg) are explicitly deferred to approved increments.
