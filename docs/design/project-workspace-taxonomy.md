# Design: definitive project workspace — roles, types & the SKILL path-contract

> Design + generic template. It defines the workspace model and the per-project
> **path contract**, and ships it as the default `templates/project/`. It changes
> **no pipeline code**: targets keep working byte-identically via built-in
> defaults. Contract auto-resolution is specified here for a **later** wiring
> increment. Applies identically to `public/<id>/` and `_private/<id>/`.

## 1. Roles & types (refined, short names)

A project organises material by **role** (what it is) with an optional **type**
axis (what kind) as subfolders. Top-level names are single words:

```
<project>/
├── SKILL.md     # path contract (frontmatter) + description
├── primary/     # MUTABLE canonical source-of-truth        (type subdirs: docs/ media/ data/ code/)
├── context/     # IMMUTABLE research/reference, read-only   (docs/ media/ refs/ ; optional phase subdirs)
├── prompts/     # per-project generation prompts (input→output instructions; traceability)
├── output/      # DERIVED, mirrors sources/ — by type: docs/ video/ audio/ images/ slides/ subs/
└── work/        # OPTIONAL work-in-progress
```

**Name choices (recommended):**
- **`primary`** — kept; clearest word for "the canonical, current thing".
- **`context`** — replaces "secondary": a single word that states its *function*
  (read-only context that informs the primary) rather than a vague ordinal.
- **`output`** — kept; already the pipeline's term and unambiguous as "derived".
- **`work`** — replaces "working": shorter, same meaning.
- The `sources/` wrapper is dropped — `primary/` and `context/` sit at the top
  level (flatter, shorter, each a clear role).

**Optional type folders (anticipating other project types, never mandatory):**
- `data/` — datasets (a data/analysis project), under `primary/` or `work/`.
- `code/` — scripts/notebooks (a code-producing project), under `primary/`.
- `refs/` — external references/citations, under `context/`.
Justification: a doc/media project won't need `data/`/`code/`, but a generic
project might; they stay optional so the structure is **agnostic** — a small set
of known roles/types, and a project uses only what it needs.

**Canonical home per derived type (unambiguous):** `output/docs`, `output/video`,
`output/audio`, `output/images`, `output/slides`, `output/subs`.

### Per-project `prompts/` (input→prompt→output traceability)
A project root holds `prompts/` alongside `primary/`/`context/`/`output/`. It
contains the **generation prompts** — the instructions that transform this
project's inputs into outputs — one per output or task. This replaces the
fragmented status quo (a global launchpad + per-video authoring) with a clear
split:
- **repo-root `prompts/`** = a **generic launchpad only** (how to create a project,
  templates, pointers) — not project material.
- **`<project>/prompts/`** = THIS project's actual generation prompts. Naming a
  prompt after its target output records the trace (which prompt produced which
  artifact), complementing the input-file→output provenance already in the AI-use
  log.
- The video sub-pipeline's per-video authoring (`scripts/<video>/{rules,script}.md`
  → `specs/<video>.json`) is a **specialized prompt form** for video and keeps its
  current location for backward-compat; conceptually it is a project prompt and may
  consolidate under `prompts/<video>/` in a later step.

### `output/` mirrors `sources/` (provenance correspondence)
**Rule:** input enters via `sources/` (and `prompts/` for instructions) and leaves
via `output/` — **never the reverse**; derived material never lands in `sources/`.
`output/` **echoes the type + sub-path layout of `sources/`**: a source at
`sources/<role>/<type>/<subpath>` produces its artifact at
`output/<derived-type>/<subpath>` — same sub-path, type swapped to the derived
type. So a source document at `primary/docs/chapter/intro.docx` yields, e.g.,
`output/docs/chapter/intro.md`, `output/slides/chapter/intro.pptx`,
`output/video/chapter/intro.mp4` — each visibly tied to its source. The mirror is
declared in the contract (`outputs.mirror: sources`) and is the convention today;
auto-enforcement is part of the later wiring.

## 2. The SKILL path-contract

`SKILL.md` is dual-purpose: human descriptor **and** machine-readable path
contract. **Scope:** the **root** `SKILL.md` carries the contract (frontmatter);
**per-folder** `SKILL.md` files stay purely descriptive.

### Frontmatter schema (root)
```yaml
skill: project
contract: 1
sources:
  primary: <path>     # REQUIRED  (default: primary)
  context: <path>     # optional  (default: context)
prompts: <path>       # optional  (default: prompts) — per-project generation prompts
outputs:
  mirror: sources     # optional  — output/ echoes sources/ type+subpath
  docs: <path>        # optional  (default: output  — current hardcoded)
  video|audio|images|slides|subtitles: <path>   # optional (default: output)
work: <path>          # optional  (default: work)
pipeline:             # video/orchestrator machine I/O
  compositions: <path>  # optional (default: compositions)
  specs: <path>         # optional (default: specs)
  manim: <path>         # optional (default: manim_scenes)
```
- **Required:** only `sources.primary`. **Everything else optional.**
- **Defaults:** when a key is absent — **or when a project has no `SKILL.md`** —
  the value is the target's current hardcoded location, so existing flat projects
  behave **byte-identically**.
- All paths are **relative to the project root** (`public/<id>/` or `_private/<id>/`).

## 3. Pipeline-resolution interface (WIRED for the targets below)

The resolver is implemented in `orchestrator/scripts/pathcontract.py`:

```
resolve(project, key, builtin_default):
    contract = read_frontmatter(project + "/SKILL.md")     # if file & frontmatter present
    if contract and key in contract:
        return contract[key]                               # path relative to project root
    return builtin_default                                 # fallback (today's behaviour)
```

It has no third-party dependency (frontmatter parsed by hand) and never raises:
missing file / missing frontmatter / missing key / malformed → returns the
default.

**Wired targets (now IS):**
- `doc-ingest`, `pptx-ingest` → `outputs.docs` (default `documents`).
- the video orchestrator `03_render_video` & `02_generate_narration` →
  `pipeline.compositions` (default `compositions`).

**Still on built-in defaults (DESIGNED, not yet wired):** the generic conversions
(`quarto/marp/mermaid/inkscape/pandoc-render`, `video-convert`, `slides-export`),
`manim-render`, and the orchestrator `output/` location (`03`/`04`). Wiring these
(a per-FORMAT→type map for conversions; `outputs.video`/etc.) is a follow-up; they
remain byte-identical today.

- **No contract / no SKILL.md →** every key falls back to the built-in default →
  identical to today. This is the backward-compatibility guarantee.
- The keys map to the verified hardcoded defaults the contract overrides:

| Contract key | Built-in default (file:line) |
|---|---|
| `outputs.docs` (doc-ingest) | `<proj>/documents` — `Makefile:324,354` |
| `outputs.*` (conversions) | `<proj>/output` — `Makefile:270` |
| `pipeline.manim` media | `<proj>/manim_scenes/media` — `Makefile:177` |
| `pipeline.compositions` | `<proj>/compositions` — `03_render_video.py:51`, `02_generate_narration.py:66` |
| `outputs.video` / subtitles | `<proj>/output` (flat) — `03:52`, `04:48` |

The resolution is **wired** for the targets listed above (doc-ingest/pptx-ingest
and the orchestrator compositions); the remaining targets are a follow-up.

## 4. What IS vs what is DESIGNED (Marco Veritas)

- **IS, today:** targets take explicit paths (`FILE=`, `SCENE=`, `--composition`,
  `--project`) and read/write the built-in default dirs; `OUTDIR=` still overrides.
  **Contract-aware (wired):** `doc-ingest`/`pptx-ingest` resolve `outputs.docs`,
  and the video orchestrator resolves `pipeline.compositions`, from a project's
  root `SKILL.md` — proven by real execution: a contract-less project lands in the
  default dirs (byte-identical), a contract-bearing project lands at the declared
  paths. Conversion/ingest also read material at any depth (depth-agnostic `proj`).
- **DESIGNED (not yet wired):** contract resolution for the generic conversions,
  `manim-render`, and the orchestrator `output/` location; and auto-enforcement of
  the `outputs.mirror`. These stay on built-in defaults (byte-identical) until a
  follow-up increment.
The `pipeline.*` keys exist because the video sub-pipeline assumed
`<proj>/compositions/`, `<proj>/specs/`, `<proj>/manim_scenes/`; the template keeps
those dirs so the pipeline works by default. `pipeline.compositions` is now
contract-aware (a project can relocate its compositions via the contract); the
others remain on defaults pending the follow-up.

## 5. public / _private symmetry

Identical for both. `.gitignore:2` ignores `_private/` wholesale, so a private
project's `SKILL.md` and role folders are git-ignored automatically; compose mounts
(`../../public`, `../../_private`) reach every subfolder at any depth.

## 6. Migration of an existing project (design only)

To adopt the refined model, a project moves canonical material → `primary/`,
research → `context/`, produced → `output/<type>/`, adds the role `SKILL.md`s and
the root contract. This is move-only + checksum-verified, with backups. The real
`_private/puma` reorg to this refined model is a **separate, gated** step and is
**not done here**.

## 7. Invariants honoured

- **No-break / byte-identical:** no pipeline code changed; targets fall back to
  built-in defaults; the contract and refined dirs are additive/opt-in.
- **Reproducibility & public/private model** unchanged; `_private/` git-ignored.
- **Design-then-implement with gates:** contract auto-resolution wiring and the
  `_private/puma` reorg are deferred to approved increments.
