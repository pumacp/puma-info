#!/usr/bin/env python3
"""08_render_document.py — render a document to its target format.

Dispatches by file extension to the right Group F service via docker exec:
  .qmd  -> Quarto    (puma_info_quarto)        PDF/HTML/docx
  .md   -> Marp      (puma_info_marp_mermaid)  PDF/PPTX/HTML  (marp:true frontmatter)
  .mmd  -> Mermaid   (puma_info_marp_mermaid)  PNG/SVG/PDF
  .svg  -> Inkscape  (puma_info_inkscape)      PNG/PDF

Inputs come from documents/ (mounted at /work/documents); outputs go to
output/ (mounted at /work/output). Each render is logged to docs/ai-use-log.md
with SHA-256 of input and output.

Isolation: only docker exec against puma_info_* containers. stdlib only.

Usage:
  python3 orchestrator/scripts/08_render_document.py documents/quarto/test.qmd
  python3 orchestrator/scripts/08_render_document.py documents/marp/test.md --format pptx
  python3 orchestrator/scripts/08_render_document.py documents/mermaid/test.mmd --format png
  python3 orchestrator/scripts/08_render_document.py documents/img/logo.svg --dry-run
"""
import argparse
import datetime
import hashlib
import pathlib
import subprocess
import sys

REPO = pathlib.Path(__file__).resolve().parents[2]
OUTPUT_DIR = REPO / "output"
AI_USE_LOG = REPO / "docs" / "ai-use-log.md"

QUARTO = "puma_info_quarto"
MARPMERMAID = "puma_info_marp_mermaid"
INKSCAPE = "puma_info_inkscape"
PUPPETEER_CFG = "/puppeteer-config.json"

DEFAULT_FORMAT = {".qmd": "pdf", ".md": "pdf", ".mmd": "png", ".svg": "png"}


def sha256(path):
    if not path.is_file():
        return "MISSING"
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 16), b""):
            digest.update(chunk)
    return digest.hexdigest()


def build_cmd(rel, ext, fmt, out_name):
    cin = "/work/" + rel.as_posix()
    cout = f"/work/output/{out_name}"
    if ext == ".qmd":
        return [QUARTO, "quarto", "render", cin, "--to", fmt,
                "--output-dir", "/work/output"]
    if ext == ".md":
        return [MARPMERMAID, "marp", cin, "-o", cout, "--allow-local-files"]
    if ext == ".mmd":
        return [MARPMERMAID, "mmdc", "-i", cin, "-o", cout, "-p", PUPPETEER_CFG]
    if ext == ".svg":
        return [INKSCAPE, "inkscape", cin, f"--export-type={fmt}",
                f"--export-filename={cout}"]
    raise SystemExit(f"ERROR: unsupported extension: {ext}")


def log_row(name, in_hash, out_hash, status):
    today = datetime.date.today().isoformat()
    with AI_USE_LOG.open("a", encoding="utf-8") as handle:
        handle.write(f"| {today} | document render | Group F render: {name} "
                     f"| in:{in_hash[:12]} out:{out_hash[:12]} | {status} |\n")


def main():
    parser = argparse.ArgumentParser(description="Render a document via Group F.")
    parser.add_argument("file", help="path under documents/ (e.g. documents/quarto/test.qmd)")
    parser.add_argument("--format", help="target format (pdf, pptx, html, png, svg)")
    parser.add_argument("--dry-run", action="store_true", help="print the command only")
    args = parser.parse_args()

    src = pathlib.Path(args.file)
    if not src.is_file() and not args.dry_run:
        print(f"ERROR: file not found: {src}", file=sys.stderr)
        return 2
    ext = src.suffix.lower()
    if ext not in DEFAULT_FORMAT:
        print(f"ERROR: unsupported extension: {ext}", file=sys.stderr)
        return 2
    fmt = args.format or DEFAULT_FORMAT[ext]

    try:
        rel = src.resolve().relative_to(REPO)
    except ValueError:
        print(f"ERROR: file must live under the repo: {src}", file=sys.stderr)
        return 2

    out_name = f"{src.stem}.{fmt}"
    cmd = ["docker", "exec"] + build_cmd(rel, ext, fmt, out_name)
    print(f"[render] {src.name} -> output/{out_name}")
    print("  $ " + " ".join(cmd))
    if args.dry_run:
        return 0
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    subprocess.run(cmd, check=True)
    out_host = OUTPUT_DIR / out_name
    log_row(src.name, sha256(src), sha256(out_host),
            "PASS" if out_host.is_file() else "FAIL")
    print(f"Wrote output/{out_name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
