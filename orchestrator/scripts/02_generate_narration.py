#!/usr/bin/env python3
"""02_generate_narration.py — synthesize per-video narration audio.

Reads a video spec (specs/<video>.json), synthesizes each scene's
narration with either Piper (English, CPU) or XTTS v2 (voice cloning,
GPU) via `docker exec`, concatenates the per-scene/per-segment WAVs
with calibrated pauses derived from inline markers, and writes:

  compositions/<video>/audio/narration.wav
  compositions/<video>/audio/narration.timing.json   (per-scene durations)

Inline markers in narration text:
  [PAUSE]        -> short pause (0.40 s)
  [FINAL PAUSE]  -> long pause  (0.80 s)
  [EMPHASIS]     -> speaking hint, stripped (no pause)

Isolation: only ever runs `docker exec` against puma_info_piper or
puma_info_xtts. Touches no resource outside the puma_info_* namespace.

Dependencies: Python standard library only (argparse, json, wave, ...).

Usage:
  python3 orchestrator/scripts/02_generate_narration.py specs/demo.json \
      --voice-engine piper
  python3 orchestrator/scripts/02_generate_narration.py specs/demo.json \
      --voice-engine xtts --reference-voice narrator_es.wav
  python3 orchestrator/scripts/02_generate_narration.py specs/demo.json \
      --single-scene s01 --dry-run
"""
import argparse
import contextlib
import datetime
import json
import pathlib
import re
import subprocess
import sys
import wave

REPO = pathlib.Path(__file__).resolve().parents[2]
SPECS_DIR = REPO / "specs"
COMPOSITIONS_DIR = REPO / "compositions"
AI_USE_LOG = REPO / "docs" / "ai-use-log.md"

CONTAINER_PIPER = "puma_info_piper"
CONTAINER_XTTS = "puma_info_xtts"
PIPER_MODEL = "/voices/en_US-amy-medium/en_US-amy-medium.onnx"
XTTS_MODEL = "tts_models/multilingual/multi-dataset/xtts_v2"

# Container-internal mount points (see stacks/C-voice/docker-compose.yml).
CONTAINER_COMPOSITIONS = "/work/compositions"
CONTAINER_REFERENCE = "/work/reference"

PAUSE_SECONDS = {"[PAUSE]": 0.40, "[FINAL PAUSE]": 0.80}
MARKER_RE = re.compile(r"(\[FINAL PAUSE\]|\[PAUSE\]|\[EMPHASIS\])")


def load_spec(spec_path: pathlib.Path) -> dict:
    """Load and minimally validate a video spec JSON."""
    with spec_path.open(encoding="utf-8") as handle:
        spec = json.load(handle)
    if "video" not in spec or "scenes" not in spec:
        raise ValueError("spec must contain 'video' and 'scenes' keys")
    return spec


def split_segments(text: str):
    """Split narration text into (segment_text, trailing_pause_seconds).

    [EMPHASIS] is stripped with no pause; [PAUSE]/[FINAL PAUSE] become a
    trailing pause on the preceding segment.
    """
    parts = MARKER_RE.split(text)
    segments = []
    current = ""
    for part in parts:
        if part in PAUSE_SECONDS:
            segments.append((current.strip(), PAUSE_SECONDS[part]))
            current = ""
        elif part == "[EMPHASIS]":
            continue
        else:
            current += part
    if current.strip():
        segments.append((current.strip(), 0.0))
    return [(t, p) for t, p in segments if t]


def to_container(host_path: pathlib.Path) -> str:
    """Map a host compositions/ path to its in-container path."""
    rel = host_path.relative_to(COMPOSITIONS_DIR)
    return f"{CONTAINER_COMPOSITIONS}/{rel.as_posix()}"


def synth_piper(text: str, out_host: pathlib.Path, dry_run: bool) -> None:
    cmd = ["docker", "exec", CONTAINER_PIPER, "python3", "-m", "piper",
           "-m", PIPER_MODEL, "-f", to_container(out_host), "--", text]
    run(cmd, dry_run)


def synth_xtts(text: str, reference: str, lang: str,
               out_host: pathlib.Path, dry_run: bool) -> None:
    cmd = ["docker", "exec", "-e", "COQUI_TOS_AGREED=1", CONTAINER_XTTS,
           "tts", "--model_name", XTTS_MODEL,
           "--text", text,
           "--speaker_wav", f"{CONTAINER_REFERENCE}/{reference}",
           "--language_idx", lang,
           "--out_path", to_container(out_host)]
    run(cmd, dry_run)


def run(cmd: list, dry_run: bool) -> None:
    print("  $ " + " ".join(cmd))
    if dry_run:
        return
    subprocess.run(cmd, check=True)


def wav_duration(path: pathlib.Path) -> float:
    with contextlib.closing(wave.open(str(path), "rb")) as w:
        return w.getnframes() / float(w.getframerate())


def write_silence(template: pathlib.Path, seconds: float,
                  out: pathlib.Path) -> None:
    """Write a silent WAV matching template's format."""
    with contextlib.closing(wave.open(str(template), "rb")) as w:
        params = w.getparams()
    n = int(seconds * params.framerate)
    with contextlib.closing(wave.open(str(out), "wb")) as o:
        o.setparams(params)
        o.writeframes(b"\x00" * (n * params.sampwidth * params.nchannels))


def concat_wavs(parts: list, out: pathlib.Path) -> None:
    """Concatenate WAVs (identical format) into one."""
    if not parts:
        raise ValueError("nothing to concatenate")
    with contextlib.closing(wave.open(str(parts[0]), "rb")) as first:
        params = first.getparams()
    with contextlib.closing(wave.open(str(out), "wb")) as o:
        o.setparams(params)
        for part in parts:
            with contextlib.closing(wave.open(str(part), "rb")) as w:
                o.writeframes(w.readframes(w.getnframes()))


def log_row(video: str, engine: str, status: str) -> None:
    today = datetime.date.today().isoformat()
    row = (f"| {today} | TTS | Narration synthesis ({engine}) for {video} "
           f"| narration.wav + timing.json | {status} |\n")
    with AI_USE_LOG.open("a", encoding="utf-8") as handle:
        handle.write(row)


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate narration audio.")
    parser.add_argument("spec", help="path to specs/<video>.json")
    parser.add_argument("--voice-engine", choices=["piper", "xtts"],
                        default="piper")
    parser.add_argument("--reference-voice",
                        help="reference WAV in voice/reference/ (xtts only)")
    parser.add_argument("--single-scene", help="only synthesize this scene id")
    parser.add_argument("--dry-run", action="store_true",
                        help="print docker commands without executing")
    args = parser.parse_args()

    spec_path = pathlib.Path(args.spec)
    if not spec_path.is_file():
        print(f"ERROR: spec not found: {spec_path}", file=sys.stderr)
        return 2
    if args.voice_engine == "xtts" and not args.reference_voice:
        print("ERROR: --reference-voice is required for the xtts engine",
              file=sys.stderr)
        return 2

    spec = load_spec(spec_path)
    video = spec["video"]
    lang = spec.get("language", "es" if args.voice_engine == "xtts" else "en")
    audio_dir = COMPOSITIONS_DIR / video / "audio"
    audio_dir.mkdir(parents=True, exist_ok=True)

    scenes = spec["scenes"]
    if args.single_scene:
        scenes = [s for s in scenes if s.get("id") == args.single_scene]
        if not scenes:
            print(f"ERROR: scene '{args.single_scene}' not found",
                  file=sys.stderr)
            return 2

    all_parts = []
    timing = {}
    for scene in scenes:
        sid = scene.get("id", f"scene{len(timing)}")
        segments = split_segments(scene.get("narration", ""))
        scene_parts = []
        for idx, (seg_text, pause) in enumerate(segments):
            seg_wav = audio_dir / f"_{sid}_{idx:02d}.wav"
            print(f"[{sid}] segment {idx}: {seg_text[:60]!r}")
            if args.voice_engine == "piper":
                synth_piper(seg_text, seg_wav, args.dry_run)
            else:
                synth_xtts(seg_text, args.reference_voice, lang,
                           seg_wav, args.dry_run)
            scene_parts.append(seg_wav)
            if pause > 0 and not args.dry_run:
                sil = audio_dir / f"_{sid}_{idx:02d}_sil.wav"
                write_silence(seg_wav, pause, sil)
                scene_parts.append(sil)
        all_parts.extend(scene_parts)
        if not args.dry_run:
            timing[sid] = round(
                sum(wav_duration(p) for p in scene_parts), 3)

    if args.dry_run:
        print("\nDry run complete — no audio written.")
        return 0

    out_wav = audio_dir / "narration.wav"
    concat_wavs(all_parts, out_wav)
    (audio_dir / "narration.timing.json").write_text(
        json.dumps({"video": video, "engine": args.voice_engine,
                    "scenes": timing,
                    "total": round(sum(timing.values()), 3)}, indent=2),
        encoding="utf-8")
    for part in all_parts:           # clean intermediate segments
        part.unlink(missing_ok=True)

    log_row(video, args.voice_engine, "PASS")
    print(f"\nWrote {out_wav} ({wav_duration(out_wav):.2f}s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
