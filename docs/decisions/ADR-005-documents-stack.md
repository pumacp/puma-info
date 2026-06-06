# ADR-005 · Documents stack (Quarto, Marp, Mermaid, Inkscape)

Status: Accepted
Date: 2026-06-05
Context: puma-info needs to publish the same source material in several
formats — print-ready PDFs, HTML, slide decks, diagrams and processed
vector graphics — reproducibly and without a desktop application.

## Decisions

  - **Quarto over hand-orchestrated LaTeX + Pandoc.** Quarto wraps Pandoc and
    a LaTeX engine behind one CLI, producing PDF, HTML and slides from a
    single `.qmd` source. It removes the need to script the Pandoc/LaTeX
    pipeline by hand.
  - **TinyTeX over texlive-full.** The official Quarto image ships TinyTeX,
    which keeps the image around 2 GB instead of roughly 5 GB for a full
    TeX Live, while still installing missing LaTeX packages on demand.
  - **Marp and Mermaid share one Node 22 image.** Both are npm packages and
    both drive headless Chromium through Puppeteer, so they share a single
    Chromium install and base image rather than duplicating it.
  - **Inkscape gets its own image.** It is a Debian-native package with no
    Node dependency, so a minimal `debian:bookworm-slim` image keeps it
    isolated and small.
  - **All services are CPU-only.** Group F requests no GPU and is not part of
    the GPU mutual-exclusion gate; it can run alongside any other group.

## Chromium under root

Mermaid's `mmdc` will not launch Chromium as root without `--no-sandbox`, so a
`/puppeteer-config.json` carrying that flag is baked into the image and passed
via `mmdc -p`. Marp enables no-sandbox automatically when running as root and
is pointed at Chromium through `CHROME_PATH`.

## Consequences

  - One source document can produce many output formats with pinned tools.
  - Image sizes stay modest (Quarto ~2 GB; the Node and Inkscape images are
    smaller), and no GPU contention is introduced.
  - The full tools inventory and licensing summary will be compiled in the
    final consolidation report.
