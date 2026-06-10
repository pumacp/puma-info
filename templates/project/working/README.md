# working/ — drafts and intermediate material

`working/` holds **drafts, scratch and intermediate** material: anything in
progress that is **neither** the canonical source-of-truth (that lives in
`sources/`) **nor** a finished artifact (those land in `output/`).

Nothing here is authoritative. It can be regenerated or discarded without losing
the project's source-of-truth or its produced outputs. No pipeline target reads
from `working/` automatically — it is an organizational space for the author.

If a project genuinely has phases (e.g. research → planning → production), add
free-form phase subdirectories here (e.g. `working/01-research/`); phases are
optional and never required.

See [`docs/design/project-workspace-taxonomy.md`](../../../docs/design/project-workspace-taxonomy.md)
for the full role × type model (sources / working / output).
