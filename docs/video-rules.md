# Video authoring rules (all videos)

General rules for authoring any puma-info video. They apply to every
video. Per-video rules live in `scripts/<id>/rules.md` and the scene
script in `scripts/<id>/script.md`.

> Repository-wide hard rules (isolation, naming conventions, GPU mutual
> exclusion, reproducibility, content hygiene, Marco Veritas / AI-use log)
> are defined in `AGENTS.md` and `docs/constitution.md` and are not
> repeated here.

## Authoring workflow (HyperFrames composition)

1. Build and start the Group D services: `make video-up`.
2. Create the composition directory from the template:
   `make video-new-composition NAME=<id>` (clones the HyperFrames skill
   bundle into `compositions/<id>/`).
3. Author the scene script in `scripts/<id>/script.md` (one entry per
   scene), governed by this file and by `scripts/<id>/rules.md`.
4. Transcribe the approved scenes into the machine spec
   `specs/<id>.json` (the pipeline's source of truth).
5. Open your coding agent with `compositions/<id>/` as its working
   directory; the HyperFrames skills are discovered from the bundle and
   write `index.html` and any sub-compositions in HTML, CSS and JS. They
   cover the HyperFrames CLI plus animation libraries (GSAP, anime.js,
   CSS animations, Lottie, three.js, the Web Animations API, Tailwind and
   the HyperFrames media helpers).
6. Preview locally: `make video-preview NAME=<id>` (http://localhost:3001).
7. Render: `make video-render NAME=<id>`, producing `output/<id>.mp4`.
   Attach Group C narration (`compositions/<id>/audio/narration.wav`) at
   render time.

## Conventions

- **English only.** All committed source — rules, scripts, on-screen text
  and narration — is in English (per `AGENTS.md`). Spanish appears only in
  subtitle tracks and localized descriptions, never in source files.
- **Rules and scenes are separated.** Production-governing rules go in
  `rules.md`; the scene content goes in `script.md`. Do not mix them.
- **Spec-driven.** `scripts/<id>/script.md` is the human source; each
  scene maps to a section of `specs/<id>.json`. The production layer
  (`specs/`, `compositions/`, `manim_scenes/`, `output/`) is produced from
  these and is not edited by hand except through the pipeline.

## Reference

- HyperFrames documentation: https://hyperframes.heygen.com
- HyperFrames source (Apache-2.0): https://github.com/heygen-com/hyperframes
