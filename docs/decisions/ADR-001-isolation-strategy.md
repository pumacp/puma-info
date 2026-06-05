# ADR-001 · Isolation strategy for puma-info

Status: Accepted
Date: 2026-06-05
Context: The PUMA Project has running infrastructure on the host.
We need a new subproject for public information production without
risk of interference.

## Decision

  - New Docker network `puma_info_network`, subnet 172.30.0.0/16
    (or first free /16 starting at 172.30 if conflict).
  - All new containers prefixed `puma_info_`.
  - All new volumes prefixed `puma_info_`.
  - All resources labeled `puma_info=true` for safe cleanup.
  - Host ports restricted to ranges 11435, 3001-3099, 5000-5099,
    7860-7869.
  - No modification of any existing PUMA resource.

## Consequences

  - Slightly higher disk usage (separate Ollama model copies).
  - Trivial cleanup via `make cleanup` using the label filter.
  - Zero risk of degrading PUMA experimental reproducibility.
