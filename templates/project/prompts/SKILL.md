# SKILL: prompts

- **Role:** per-project generation prompts — the instructions that transform
  input → output.
- **Mutability:** MUTABLE — authored and curated per project.
- **Contains:** the prompt/instruction files that drive THIS project's generation,
  one per output or task (e.g. "render these docs as slides in style X",
  "generate the infographic for section Y from `primary/`"). This is where
  **input → prompt → output traceability** is recorded.
- **Purpose / how to use:** an agent/operator reads a prompt here to produce a
  derived artifact **from `primary/`** (with `context/` as read-only context); the
  artifact lands in `output/` (mirroring `sources/` — see below). Name a prompt
  after its target output so the trace is explicit.
- **Relation to the global launchpad:** the repository-root `prompts/` is only a
  **generic launchpad** (how to create a project, templates, pointers). This
  **per-project** `prompts/` holds the project's actual generation prompts. The
  video sub-pipeline's per-video authoring (`scripts/<video>/{rules,script}.md` →
  `specs/<video>.json`) is a specialized prompt form for video and keeps its
  existing location.
- **Provenance:** authored from the project's needs; maps `primary/`/`context/`
  inputs to `output/` artifacts.
