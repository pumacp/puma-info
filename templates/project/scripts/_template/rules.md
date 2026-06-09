# Video <id> — rules

Per-video production rules. Inherits the general rules in the
repository-root `docs/video-rules.md`.

- Target length: <e.g. ~3 minutes>
- Audience: <who the video is for>
- Language: English (narration via Group C; subtitles optional)
- Composition: HyperFrames (HTML/CSS/JS), optional Manim inserts
- Spec: `specs/<id>.json`
- Composition dir: `compositions/<id>/`

## Production notes

- Each scene in `script.md` maps to a section of `specs/<id>.json`.
- Narration timing comes from
  `compositions/<id>/audio/narration.timing.json` (Group C).
- Keep all on-screen text and narration in English.
