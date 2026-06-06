# puma-info License Compatibility Matrix

Generated 2026-06-05.

## Repository license

puma-info itself is licensed under the **MIT License** (see
`LICENSE`). This document analyzes the compatibility of the MIT
license with every tool used by puma-info, organized by license
class.

## Compatibility analysis

Compatibility is assessed in the **usage context**: puma-info
invokes these tools as standalone executables or services via
Docker containers; it does not statically or dynamically link
their libraries. This distinction is essential for AGPL and GPL
tools.

### Permissive licenses (MIT, Apache-2.0, BSD)

Fully compatible with MIT in all use cases. No restrictions on
linking, modification, or redistribution beyond attribution.

Affected tools: Ollama, Marp CLI, Mermaid CLI, Manim CE,
WhisperX (BSD-2), faster-whisper, CTranslate2, jsonschema,
HyperFrames, google-api-python-client (and Google auth libs),
gh CLI, Piper TTS, Docker Engine, Node.js, Chromium.

### Weak copyleft (MPL-2.0, LPPL)

  - **Coqui TTS** (MPL-2.0): file-level copyleft. puma-info does
    not modify Coqui TTS source; we use it as an installed package
    inside a Docker image. Fully compatible.
  - **TinyTeX** (LPPL): the LaTeX Project Public License is
    accepted as a "permissive license" by SPDX and the FSF when
    used as a complete distribution (which is our case). Fully
    compatible.

### Strong copyleft used at runtime, not linked (GPL-2.0, GPL-3.0)

  - **Quarto** (GPL-2.0), **Pandoc** (GPL-2.0+), **Inkscape**
    (GPL-3.0), **PDFMathTranslate** (AGPL-3.0): used as standalone
    executables inside Docker containers. We invoke them via CLI;
    we do not link them into our Python or Node code. The MIT
    license of puma-info does not derive from their source, so
    distribution of puma-info code under MIT is unaffected.
  - **git** (GPL-2.0): system-level tool. Same reasoning.

### AGPL services

  - **LibreTranslate** (AGPL-3.0) and **PDFMathTranslate**
    (AGPL-3.0): run as network-accessible services inside our
    Docker network. The AGPL's "network access" clause requires
    that users who access the service over a network be offered
    the source code. Since puma-info is a single-operator
    pipeline that does NOT expose these services to the public
    internet, the network clause is not triggered. The puma-info
    operator already has access to the source code (via the
    public repository).

### Non-commercial / academic licenses

  - **XTTS v2 model weights** (Coqui Public Model License, CPML):
    permits academic, research, and non-commercial use; commercial
    use requires a separate license from Coqui. puma-info is an
    open-source academic project, fully compatible with CPML for
    its current use.
  - **qwen2.5:7b** (Apache-2.0): fully permissive; no
    restrictions on commercial or academic use. Listed here
    only because it is a model weight; the actual license is
    fully permissive.
  - **qwen2.5:3b** (Qwen Research License Agreement): permits
    research, academic, and personal use. Commercial use
    requires a separate license from Alibaba Cloud. puma-info
    is an academic open-source project and fully compliant.

### NVIDIA Software License Agreement

The CUDA runtime image (`nvidia/cuda`) is distributed under the
NVIDIA SLA. It permits redistribution within Docker images and
use for AI workloads. puma-info complies.

## Citation requirements

Several tools request academic citation when used in publications:

  - **WhisperX**: Bain et al. 2023, arXiv:2303.00747
  - **XTTS v2**: Casanova et al. 2024, arXiv:2406.04904
  - **Piper TTS**: GitHub credit (no canonical paper)
  - **Coqui TTS**: see Coqui's CITATION.cff
  - **Manim**: GitHub credit
  - **HyperFrames**: GitHub credit

Include these citations in your publication's references when
puma-info results are used.

## Summary

All licenses encountered are compatible with puma-info's MIT
license in the actual usage context (Docker-isolated invocation,
no static or dynamic linking). The two model weights carrying
non-commercial restrictions are:

  1. **XTTS v2 weights** (CPML) — academic / non-commercial only.
  2. **qwen2.5:3b weights** (Qwen Research License Agreement) —
     research, academic, and personal use; commercial use requires
     a separate license from Alibaba Cloud.

qwen2.5:7b is Apache-2.0 (fully permissive). The XTTS v2
restriction is documented in ADR-002 (Group C); both restrictions
are noted here and in the README. Commercial use of XTTS v2
requires a separate license from Coqui, and commercial use of
qwen2.5:3b a separate license from Alibaba Cloud.

## See also

- `docs/TOOLS_INVENTORY.md` — full pin list
- `docs/REPRODUCIBILITY_REPORT.md` — verification protocol
- `docs/decisions/ADR-002-xtts-license.md` — XTTS CPML acceptance
- `LICENSE` — puma-info's MIT license
