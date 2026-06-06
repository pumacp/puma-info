#!/usr/bin/env python3
"""06_generate_metadata.py — scaffold (or validate) YouTube metadata for a video.

Reads specs/<video_id>.json and writes a STUB output/<video_id>.metadata.json
conforming to metadata_schema.json. Title, description and tags are creative
decisions: this script does NOT call any external LLM. It emits a placeholder
plus a prompt the operator can hand to the agent of their choice. With
--validate it checks an existing metadata.json against the schema.

stdlib only.

Usage:
  python3 orchestrator/scripts/06_generate_metadata.py --spec specs/video01.json
  python3 orchestrator/scripts/06_generate_metadata.py --spec specs/video01.json --from-template my.json
  python3 orchestrator/scripts/06_generate_metadata.py --validate output/video01.metadata.json
"""
import argparse
import json
import pathlib
import sys

REPO = pathlib.Path(__file__).resolve().parents[2]
OUTPUT_DIR = REPO / "output"
SCHEMA = REPO / "orchestrator" / "scripts" / "metadata_schema.json"

REQUIRED = ["video_id", "title", "description", "tags", "category_id", "audio_language"]


def minimal_validate(meta, schema):
    errs = []
    for key in schema.get("required", REQUIRED):
        if key not in meta:
            errs.append(f"missing required field: {key}")
    if len(meta.get("title", "")) > 100:
        errs.append("title exceeds 100 chars")
    if len(meta.get("description", "")) > 5000:
        errs.append("description exceeds 5000 chars")
    if len(meta.get("tags", [])) > 30:
        errs.append("tags exceeds 30 items")
    return errs


def stub_from_spec(spec):
    vid = spec.get("video", spec.get("video_id", "unknown"))
    return {
        "video_id": vid,
        "title": f"<TITLE for {vid} — author manually, max 100 chars>",
        "description": "<DESCRIPTION — author manually, max 5000 chars. "
                       "Include links to the public PUMA repositories.>",
        "tags": ["PUMA", "open science", "local LLM", "benchmarking"],
        "category_id": "28",
        "audio_language": "en",
        "default_language": "en",
    }


def main():
    p = argparse.ArgumentParser(description="Scaffold/validate YouTube metadata.")
    p.add_argument("--spec", help="path to specs/<id>.json")
    p.add_argument("--from-template", help="starter metadata template to copy")
    p.add_argument("--validate", help="validate an existing metadata.json")
    args = p.parse_args()

    schema = json.loads(SCHEMA.read_text(encoding="utf-8")) if SCHEMA.is_file() else {"required": REQUIRED}

    if args.validate:
        meta = json.loads(pathlib.Path(args.validate).read_text(encoding="utf-8"))
        errs = minimal_validate(meta, schema)
        if errs:
            print("INVALID:")
            for e in errs:
                print(f"  - {e}")
            return 1
        print("valid")
        return 0

    if not args.spec:
        print("ERROR: --spec or --validate required", file=sys.stderr)
        return 2
    spec_path = pathlib.Path(args.spec)
    if not spec_path.is_file():
        print(f"ERROR: spec not found: {spec_path}", file=sys.stderr)
        return 2
    spec = json.loads(spec_path.read_text(encoding="utf-8"))

    if args.from_template:
        meta = json.loads(pathlib.Path(args.from_template).read_text(encoding="utf-8"))
        meta.setdefault("video_id", spec.get("video", "unknown"))
    else:
        meta = stub_from_spec(spec)

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    out = OUTPUT_DIR / f"{meta['video_id']}.metadata.json"
    out.write_text(json.dumps(meta, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    vid = meta["video_id"]
    print(f"Wrote {out} (STUB).")
    print()
    print("Next: author the title/description/tags. Suggested prompt for your agent:")
    prompt = (
        "Write YouTube metadata (title <=100 chars, description <=5000, up to "
        f"30 tags) for the PUMA video '{vid}' based on specs/{spec_path.name}. "
        "English only. Return JSON matching orchestrator/scripts/metadata_schema.json."
    )
    print("  " + prompt)
    return 0


if __name__ == "__main__":
    sys.exit(main())
