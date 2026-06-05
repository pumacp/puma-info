#!/usr/bin/env python3
"""05_translate_pdfs.py — batch-translate every PDF in translation/input_es/.

Invokes the puma_info_pdf_translator service (PDFMathTranslate / pdf2zh)
with the dedicated puma_info_ollama backend (host port 11435). For each
<name>.pdf in translation/input_es/ it produces:

  translation/output_en/<name>-mono.pdf    English-only
  translation/bilingual/<name>-dual.pdf    side-by-side ES/EN

Every translation is appended as one Marco-Veritas row to
docs/ai-use-log.md.

Isolation: this script ONLY ever runs the puma_info_pdf_translator
service defined in stacks/B-translation/docker-compose.yml. It never
touches host port 11434 or any non-puma_info resource.

Usage:
  python3 orchestrator/scripts/05_translate_pdfs.py             # all PDFs
  python3 orchestrator/scripts/05_translate_pdfs.py --single foo.pdf
  python3 orchestrator/scripts/05_translate_pdfs.py --dry-run   # print only
"""
import argparse
import datetime
import pathlib
import subprocess
import sys

# Repo root is two levels up from orchestrator/scripts/.
REPO = pathlib.Path(__file__).resolve().parents[2]
INPUT_DIR = REPO / "translation" / "input_es"
OUTPUT_DIR = REPO / "translation" / "output_en"
BILINGUAL_DIR = REPO / "translation" / "bilingual"
COMPOSE_DIR = REPO / "stacks" / "B-translation"
AI_USE_LOG = REPO / "docs" / "ai-use-log.md"

MODEL = "qwen2.5:7b"
SRC_LANG = "es"
TGT_LANG = "en"


def compose_run_cmd(pdf_name: str) -> list:
    """Build the `docker compose run --rm` command for one PDF.

    The pdf_translator container mounts input_es -> /app/input (read-only)
    and output_en -> /app/output. pdf2zh writes <name>-mono.pdf and
    <name>-dual.pdf into the output directory.
    """
    return [
        "docker", "compose", "run", "--rm", "pdf_translator",
        "pdf2zh",
        f"/app/input/{pdf_name}",
        "-s", f"ollama:{MODEL}",
        "-li", SRC_LANG,
        "-lo", TGT_LANG,
        "-o", "/app/output",
    ]


def log_row(pdf_name: str, status: str) -> None:
    """Append one Marco-Veritas row to docs/ai-use-log.md."""
    today = datetime.date.today().isoformat()
    row = (f"| {today} | translation | PDF translation ES->EN: {pdf_name} "
           f"| {pdf_name} mono+dual | {status} |\n")
    with AI_USE_LOG.open("a", encoding="utf-8") as handle:
        handle.write(row)


def translate_one(pdf: pathlib.Path, dry_run: bool) -> bool:
    """Translate a single PDF. Returns True on success."""
    cmd = compose_run_cmd(pdf.name)
    print(f"[translate] {pdf.name}")
    print(f"  cwd: {COMPOSE_DIR}")
    print(f"  cmd: {' '.join(cmd)}")
    if dry_run:
        return True
    result = subprocess.run(cmd, cwd=str(COMPOSE_DIR))
    ok = result.returncode == 0
    # Move the produced dual file into the bilingual directory.
    produced_dual = OUTPUT_DIR / f"{pdf.stem}-dual.pdf"
    if ok and produced_dual.exists():
        produced_dual.replace(BILINGUAL_DIR / produced_dual.name)
    log_row(pdf.name, "PASS" if ok else "FAIL")
    return ok


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Batch-translate PDFs (ES->EN) via puma_info pdf_translator.")
    parser.add_argument("--single", metavar="FILENAME",
                        help="translate only this file inside input_es/")
    parser.add_argument("--dry-run", action="store_true",
                        help="print the exact commands without executing")
    args = parser.parse_args()

    if not INPUT_DIR.is_dir():
        print(f"ERROR: input dir not found: {INPUT_DIR}", file=sys.stderr)
        return 2

    if args.single:
        candidate = INPUT_DIR / args.single
        if not candidate.is_file():
            print(f"ERROR: not found: {candidate}", file=sys.stderr)
            return 2
        pdfs = [candidate]
    else:
        pdfs = sorted(INPUT_DIR.glob("*.pdf"))

    if not pdfs:
        print("No PDFs to translate in translation/input_es/.")
        return 0

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    BILINGUAL_DIR.mkdir(parents=True, exist_ok=True)

    failures = 0
    for pdf in pdfs:
        if not translate_one(pdf, args.dry_run):
            failures += 1
            print(f"  -> FAILED: {pdf.name}", file=sys.stderr)

    total = len(pdfs)
    print(f"\nDone. {total - failures}/{total} succeeded.")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
