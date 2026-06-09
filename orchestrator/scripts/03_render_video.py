#!/usr/bin/env python3
"""03_render_video.py — render a HyperFrames composition to MP4.

Invokes `npx hyperframes render` inside the puma_info_hyperframes container
against compositions/<id>/, producing output/<id>.mp4. If an audio track is
supplied (e.g. compositions/<id>/audio/narration.wav from Group C) it is
muxed into the rendered video with ffmpeg (also inside the container) — the
HyperFrames CLI has no native --audio flag.

Each render is logged to docs/ai-use-log.md with SHA-256 of the composition
index and the resulting MP4 for reproducibility tracking.

Isolation: only runs `docker exec` against puma_info_hyperframes. Touches no
resource outside the puma_info_* namespace.

Dependencies: Python standard library only.

Usage:
  python3 orchestrator/scripts/03_render_video.py --composition video01
  python3 orchestrator/scripts/03_render_video.py --composition video01 \
      --audio compositions/video01/audio/narration.wav
  python3 orchestrator/scripts/03_render_video.py --composition video01 --preview
  python3 orchestrator/scripts/03_render_video.py --composition video01 --dry-run
"""
import argparse
import datetime
import hashlib
import pathlib
import re
import subprocess
import sys

REPO = pathlib.Path(__file__).resolve().parents[2]
COMPOSITIONS_DIR = REPO / "compositions"
OUTPUT_DIR = REPO / "output"
AI_USE_LOG = REPO / "docs" / "ai-use-log.md"

CONTAINER = "puma_info_hyperframes"
CONTAINER_COMPOSITIONS = "/work/compositions"
CONTAINER_OUTPUT = "/work/output"


def apply_project(project: str) -> None:
    """Route all I/O under public/<id> or _private/<id>; default: repo root."""
    global COMPOSITIONS_DIR, OUTPUT_DIR, AI_USE_LOG
    global CONTAINER_COMPOSITIONS, CONTAINER_OUTPUT
    if not project:
        return
    if not re.fullmatch(r"(public|_private)/[^/]+", project):
        sys.exit(f"ERROR: --project must match (public|_private)/<id>, got: {project!r}")
    COMPOSITIONS_DIR = REPO / project / "compositions"
    OUTPUT_DIR = REPO / project / "output"
    CONTAINER_COMPOSITIONS = f"/work/{project}/compositions"
    CONTAINER_OUTPUT = f"/work/{project}/output"
    if project.startswith("_private/"):
        AI_USE_LOG = REPO / project / "docs" / "ai-use-log.md"


def sha256(path: pathlib.Path) -> str:
    if not path.is_file():
        return "MISSING"
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 16), b""):
            digest.update(chunk)
    return digest.hexdigest()


def run(cmd: list, dry_run: bool) -> None:
    print("  $ " + " ".join(cmd))
    if dry_run:
        return
    subprocess.run(cmd, check=True)


def preview(composition: str, dry_run: bool) -> int:
    comp_dir = COMPOSITIONS_DIR / composition
    if not comp_dir.is_dir():
        print(f"ERROR: composition not found: {comp_dir}", file=sys.stderr)
        return 2
    cmd = ["docker", "exec", "-d", CONTAINER, "bash", "-c",
           f"cd {CONTAINER_COMPOSITIONS}/{composition} && "
           f"npx hyperframes preview --port 3000"]
    print(f"[preview] {composition} -> http://localhost:3001")
    run(cmd, dry_run)
    return 0


def render(composition: str, audio: str, dry_run: bool) -> int:
    comp_dir = COMPOSITIONS_DIR / composition
    if not comp_dir.is_dir():
        print(f"ERROR: composition not found: {comp_dir}", file=sys.stderr)
        return 2
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    out_name = f"{composition}.mp4"
    container_out = f"{CONTAINER_OUTPUT}/{out_name}"

    render_cmd = ["docker", "exec", CONTAINER, "bash", "-c",
                  f"cd {CONTAINER_COMPOSITIONS}/{composition} && "
                  f"npx hyperframes render --output {container_out}"]
    print(f"[render] {composition} -> output/{out_name}")
    run(render_cmd, dry_run)

    if audio:
        audio_path = pathlib.Path(audio).resolve()
        if not audio_path.is_file():
            print(f"ERROR: audio not found: {audio_path}", file=sys.stderr)
            return 2
        rel_audio = audio_path.relative_to(COMPOSITIONS_DIR)
        container_audio = f"{CONTAINER_COMPOSITIONS}/{rel_audio.as_posix()}"
        muxed = f"{CONTAINER_OUTPUT}/{composition}.muxed.mp4"
        mux_cmd = ["docker", "exec", CONTAINER, "bash", "-c",
                   f"ffmpeg -y -i {container_out} -i {container_audio} "
                   f"-c:v copy -c:a aac -shortest {muxed} && "
                   f"mv -f {muxed} {container_out}"]
        print(f"[mux] {composition} + {audio_path.name}")
        run(mux_cmd, dry_run)

    if dry_run:
        return 0
    out_host = OUTPUT_DIR / out_name
    log_row(composition, sha256(comp_dir / "index.html"), sha256(out_host),
            "PASS" if out_host.is_file() else "FAIL")
    print(f"Wrote output/{out_name}")
    return 0


def log_row(composition: str, in_hash: str, out_hash: str, status: str) -> None:
    today = datetime.date.today().isoformat()
    row = (f"| {today} | video render | HyperFrames render: {composition} "
           f"| in:{in_hash[:12]} out:{out_hash[:12]} | {status} |\n")
    AI_USE_LOG.parent.mkdir(parents=True, exist_ok=True)
    with AI_USE_LOG.open("a", encoding="utf-8") as handle:
        handle.write(row)


def main() -> int:
    parser = argparse.ArgumentParser(description="Render a HyperFrames composition.")
    parser.add_argument("--composition", required=True,
                        help="composition id under compositions/")
    parser.add_argument("--audio", help="optional WAV to mux (e.g. narration.wav)")
    parser.add_argument("--preview", action="store_true",
                        help="launch the preview server instead of rendering")
    parser.add_argument("--dry-run", action="store_true",
                        help="print docker commands without executing")
    parser.add_argument("--project",
                        help="route I/O under public/<id> or _private/<id> (default: repo root)")
    args = parser.parse_args()
    apply_project(args.project)
    if args.preview:
        return preview(args.composition, args.dry_run)
    return render(args.composition, args.audio, args.dry_run)


if __name__ == "__main__":
    sys.exit(main())
