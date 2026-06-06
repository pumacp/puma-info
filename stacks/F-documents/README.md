# Group F · Documents

Multi-format publishing for the puma-info pipeline. All services are
CPU-only and coexist with any other group.

## Services

| Service | Container | Engine | Use |
|---|---|---|---|
| quarto | puma_info_quarto | Quarto + Pandoc + TinyTeX | Academic publishing (PDF/HTML/slides) from `.qmd` |
| marp-mermaid | puma_info_marp_mermaid | Marp CLI + Mermaid CLI (Node 22 + Chromium) | Markdown slide decks and diagram rendering |
| inkscape | puma_info_inkscape | Inkscape | SVG batch processing and conversion |

## Operation

```
make docs-build            # Build all three images
make docs-up               # Start all services
make docs-test-all         # Run all four smoke tests
make quarto-render FILE=documents/quarto/<f>.qmd FORMAT=pdf
make marp-render FILE=documents/marp/<f>.md FORMAT=pdf
make mermaid-render FILE=documents/mermaid/<f>.mmd FORMAT=png
make inkscape-convert FILE=documents/img/<f>.svg FORMAT=png
make pandoc-convert FILE=<f>.md FORMAT=docx
make docs-down             # Stop all services
```

Source documents live in `documents/` (committed); rendered outputs go to
`output/` (gitignored).

## Notes

Marp and Mermaid both drive headless Chromium via Puppeteer. Running as root
in a container, Mermaid requires `--no-sandbox`, supplied through the baked
`/puppeteer-config.json` (passed with `mmdc -p`). Marp enables no-sandbox
automatically under root and is pointed at Chromium through `CHROME_PATH`.

## License notes

  - Quarto: GPL-2.0 (Posit)
  - Pandoc (bundled with Quarto): GPL-2.0-or-later
  - Marp CLI: MIT
  - Mermaid CLI: MIT
  - Inkscape: GPL-3.0
  - Chromium (Puppeteer backend): BSD-style (Chromium Project)

All licensing details will be consolidated in the final tools-inventory report.
