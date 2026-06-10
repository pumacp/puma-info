#!/usr/bin/env python3
"""04_generate_subtitles.py — generate an SRT subtitle track from a rendered MP4.

Runs WhisperX (large-v3) inside puma_info_whisper via docker exec against
output/<video_id>.mp4 and writes output/<video_id>.<lang>.srt. After
transcription, common project acronyms are normalised to canonical casing.
With --review the SRT is opened in $EDITOR for manual correction.

Isolation: only runs docker exec against puma_info_whisper. stdlib only.

Usage:
  python3 orchestrator/scripts/04_generate_subtitles.py --video video01
  python3 orchestrator/scripts/04_generate_subtitles.py --video video01 --language en --review
  python3 orchestrator/scripts/04_generate_subtitles.py --video video01 --dry-run
"""
import argparse
import datetime
import hashlib
import os
import pathlib
import re
import subprocess
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from pathcontract import resolve  # noqa: E402  (resolve project SKILL.md path-contract)

REPO = pathlib.Path(__file__).resolve().parents[2]
OUTPUT_DIR = REPO / "output"
AI_USE_LOG = REPO / "docs" / "ai-use-log.md"

CONTAINER = "puma_info_whisper"
CONTAINER_WORK = "/work"   # output/ is mounted at /work in puma_info_whisper
MODEL = "large-v3"

# Acronyms WhisperX tends to lowercase or mis-split; force canonical casing.
ACRONYMS = ["PUMA", "API", "DSR", "MAE", "F1", "LLM", "PMO", "JSON", "CSV"]


PROJECT = ""


def apply_project(project: str) -> None:
    """Route all I/O under public/<id> or _private/<id>; default: repo root."""
    global OUTPUT_DIR, AI_USE_LOG, PROJECT
    if not project:
        return
    if not re.fullmatch(r"(public|_private)/[^/]+", project):
        sys.exit(f"ERROR: --project must match (public|_private)/<id>, got: {project!r}")
    PROJECT = project
    OUTPUT_DIR = REPO / project / resolve(str(REPO / project), "outputs.video", "output")
    if project.startswith("_private/"):
        AI_USE_LOG = REPO / project / "docs" / "ai-use-log.md"


def run(cmd, dry_run):
    print("  $ " + " ".join(cmd))
    if dry_run:
        return 0
    return subprocess.run(cmd, check=True).returncode


def normalise_acronyms(srt_path):
    text = srt_path.read_text(encoding="utf-8")
    for acr in ACRONYMS:
        text = re.sub(rf"\b{re.escape(acr)}\b", acr, text, flags=re.IGNORECASE)
    srt_path.write_text(text, encoding="utf-8")


def sha256(path):
    if not path.is_file():
        return "MISSING"
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 16), b""):
            digest.update(chunk)
    return digest.hexdigest()


def repo_rel(path):
    try:
        return str(path.resolve().relative_to(REPO))
    except ValueError:
        return path.name


def log_row(video, lang, status, mp4_path):
    today = datetime.date.today().isoformat()
    in_ref = f"{repo_rel(mp4_path)}@{sha256(mp4_path)[:12]}"
    row = (f"| {today} | transcription | WhisperX SRT ({lang}) for {video} "
           f"(in:{in_ref}) | {video}.{lang}.srt | {status} |\n")
    AI_USE_LOG.parent.mkdir(parents=True, exist_ok=True)
    with AI_USE_LOG.open("a", encoding="utf-8") as fh:
        fh.write(row)


def main():
    p = argparse.ArgumentParser(description="Generate SRT subtitles via WhisperX.")
    p.add_argument("--video", required=True, help="video id (expects output/<id>.mp4)")
    p.add_argument("--language", default="en", help="language code (default en)")
    p.add_argument("--review", action="store_true",
                   help="open the resulting SRT in $EDITOR for manual fixes")
    p.add_argument("--dry-run", action="store_true", help="print commands only")
    p.add_argument("--project",
                   help="route I/O under public/<id> or _private/<id> (default: repo root)")
    args = p.parse_args()
    apply_project(args.project)

    mp4 = OUTPUT_DIR / f"{args.video}.mp4"
    if not mp4.is_file() and not args.dry_run:
        print(f"ERROR: input MP4 not found: {mp4}", file=sys.stderr)
        return 2

    # whisper mounts output/ at /work; per-project trees nest at /work/<project>/.
    if PROJECT:
        c_mp4 = f"/work/{PROJECT}/output/{args.video}.mp4"
        c_outdir = f"/work/{PROJECT}/output"
    else:
        c_mp4 = f"{CONTAINER_WORK}/{args.video}.mp4"
        c_outdir = CONTAINER_WORK
    cmd = ["docker", "exec", CONTAINER, "whisperx",
           c_mp4,
           "--model", MODEL,
           "--language", args.language,
           "--compute_type", "float16",
           "--output_format", "srt",
           "--output_dir", c_outdir]
    print(f"[subs] {args.video} -> output/{args.video}.{args.language}.srt")
    run(cmd, args.dry_run)
    if args.dry_run:
        return 0

    produced = OUTPUT_DIR / f"{args.video}.srt"
    final = OUTPUT_DIR / f"{args.video}.{args.language}.srt"
    if produced.exists():
        produced.replace(final)
    if not final.is_file():
        print(f"ERROR: SRT not produced: {final}", file=sys.stderr)
        log_row(args.video, args.language, "FAIL", mp4)
        return 1
    normalise_acronyms(final)

    if args.review:
        subprocess.run([os.environ.get("EDITOR", "nano"), str(final)])

    log_row(args.video, args.language, "PASS", mp4)
    print(f"Wrote output/{final.name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
