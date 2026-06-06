# puma-info Reproducibility Report

Generated 2026-06-05.

## Claim

Given the same hardware tier and a clean Docker installation, every
artifact produced by puma-info is regenerable bit-exact from its
source spec by running the corresponding `make` target.

The verification protocol below describes how to confirm this
claim.

## What is pinned

`versions.lock` is the single source of truth. It contains:

  - **Docker images** by `@sha256:` digest (not by tag)
  - **npm packages** (HyperFrames, Marp CLI, Mermaid CLI) by exact
    version
  - **Python packages** (torch, transformers, whisperx,
    google-api-python-client, etc.) by exact version
  - **Debian system packages** (chromium, inkscape) by exact
    Debian package version
  - **Model weights** by canonical identifier (e.g., `qwen2.5:7b`)
    or by Hugging Face commit SHA where applicable
  - **Locally built image IDs** for every `pumacp/puma-info-*`
    image, recorded at build time

A diff against `versions.lock` is the canonical proof that an
installation deviated from the reference.

## Hardware requirements for reproduction

Minimum to run the full pipeline end-to-end:

  - x86_64 Linux (verified on Ubuntu 24.04)
  - 16 GB RAM
  - 6 GB VRAM on a CUDA-capable NVIDIA GPU (the GPU mutex serializes
    Ollama, XTTS, and WhisperX)
  - 50 GB free disk (images + model weights + working space)
  - Docker 24+ and NVIDIA Container Toolkit (for the GPU groups)

Reference environment: laptop with NVIDIA RTX 2060 Mobile (6 GB),
Intel i7-10750H, 32 GB RAM, Ubuntu 24.04.

## Verification protocol

To verify reproducibility of any artifact `X`:

  1. Clone the repository: `git clone git@github.com:pumacp/puma-info.git`
  2. Check out the same tag or commit as the reference run
  3. `make foundation-up` and the relevant group install targets
  4. Confirm `versions.lock` matches:
     `git diff <reference-tag> -- versions.lock` returns empty
  5. Run the make target that produced `X` in the reference run
  6. Compute `sha256sum` of the resulting `output/<X>` and compare
     against the AI-Use-Log entry from the reference run

If the hashes match, the artifact is reproduced bit-exact. If they
diverge, either:
  - A pinned package or image silently updated (rare with digests)
  - Hardware non-determinism affected a GPU operation
  - A network-fetched LaTeX package or font shifted

## What is NOT reproducible

The following aspects are inherently or practically not bit-exact:

  - **Wall-clock times** vary by hardware.
  - **Some GPU operations** are non-deterministic at the bit level
    (CUDA reductions, certain attention implementations). Most
    inference paths in puma-info are deterministic at temperature 0,
    but exact equality is not guaranteed.
  - **Third-party API responses** (YouTube uploads, captions
    insertions) are outside our control. We log the response IDs
    in `output/<id>.upload.log` for audit.
  - **Network-fetched packages at install time** (TinyTeX LaTeX
    packages, npm registry mirrors). The first build downloads from
    public mirrors; if a mirror has updated since the reference run,
    the local cache may diverge slightly. The image digest pins
    rebuild bit-exactly within the Docker layer cache.

These divergences affect **production timing**, not artifact
**content**.

## Content-hygiene scans

Before every push, all tracked files are scanned for forbidden
private identifiers (academic terms case-sensitive, personal
account names case-insensitive). The scan is configured with a
project-specific token list and runs on both the main repository
and the wiki repository independently. Zero matches is the gate.

This protects against accidental leakage of private context into
the public artifact.

## GPU mutual exclusion

Three services request GPU access: Ollama (Group B), XTTS v2
(Group C), and WhisperX (Group E). With a 6 GB VRAM reference
device, they cannot coexist. The Makefile target `gpu-available`
fails fast if any container labelled `gpu=true` is already running;
`make gpu-release` frees the slot.

This serialization simplifies reproducibility: at any moment, at
most one GPU model is in flight, making memory pressure predictable
and inference output deterministic at temperature 0.

## Audit trail

  - **`docs/ai-use-log.md`** records each pipeline run with input
    and output SHA-256 hashes.
  - **`versions.lock`** is appended at every group install.
  - **Git history** is append-only (no force-pushes, no rebases on
    pushed branches).
  - **ADRs** under `docs/decisions/` document every architectural
    choice that deviated from the obvious default.

The combination is sufficient for forensic reconstruction of how
any artifact was produced.

## See also

- `docs/TOOLS_INVENTORY.md` — pin matrix
- `docs/LICENSE_MATRIX.md` — compatibility analysis
- `versions.lock` — machine-readable source of truth
