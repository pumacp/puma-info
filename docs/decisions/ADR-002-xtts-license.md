# ADR-002 · XTTS v2 license and acceptance

Status: Accepted
Date: 2026-06-05
Context: puma-info includes voice cloning capability via XTTS v2
(Coqui TTS). The XTTS v2 model weights are distributed under the
Coqui Public Model License (CPML), which restricts commercial use.

## Decision

  - XTTS v2 is used inside puma-info exclusively for academic,
    research, and non-commercial public information artifacts
    about the PUMA Project.
  - The CPML acceptance flag `COQUI_TOS_AGREED=1` is set in the
    XTTS Dockerfile and in the docker-compose service environment,
    consistent with the upstream Coqui acceptance mechanism.
  - The full CPML text and the path to its acceptance is referenced
    in `stacks/C-voice/README.md`.
  - Any future commercial derivative of puma-info must replace XTTS
    v2 with a permissively licensed alternative (e.g. retraining
    voices in MIT-licensed engines).

## Consequences

  - No restriction on the academic and non-commercial public use
    cases that puma-info targets.
  - Operators producing commercial derivatives must observe
    CPML and choose alternatives.
  - The dependency is documented in `versions.lock` with its
    pinned image digest.
