#!/usr/bin/env python3
"""07_upload_youtube.py — upload a rendered video to YouTube (Data API v3).

Reads output/<video_id>.mp4, any output/<video_id>.<lang>.srt caption tracks,
and output/<video_id>.metadata.json. Validates metadata against
metadata_schema.json, then performs a resumable videos.insert followed by
captions.insert for each SRT. Localizations (if present) applied via
videos.update.

--dry-run prints exactly what would be sent WITHOUT importing credentials or
touching the API. --auth-only runs the OAuth installed-app flow to mint
secrets/youtube_token.json.

Runs inside puma_info_uploader. Credentials/tokens live only in secrets/.

Usage (inside container):
  python3 07_upload_youtube.py --video video01 --dry-run
  python3 07_upload_youtube.py --auth-only
  python3 07_upload_youtube.py --video video01
"""
import argparse
import datetime
import glob
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))      # /work in the container
OUTPUT_DIR = os.path.join(REPO, "output")
SECRETS_DIR = os.path.join(REPO, "secrets")
SCHEMA_PATH = os.path.join(HERE, "metadata_schema.json")
AI_USE_LOG = os.path.join(REPO, "docs", "ai-use-log.md")

CREDENTIALS = os.path.join(SECRETS_DIR, "youtube_credentials.json")
TOKEN = os.path.join(SECRETS_DIR, "youtube_token.json")
SCOPES = ["https://www.googleapis.com/auth/youtube.force-ssl"]
QUOTA_NOTE = "videos.insert ~1600 units; captions.insert ~400; daily default 10000."


def load_json(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def validate_metadata(meta):
    try:
        import jsonschema
        jsonschema.validate(meta, load_json(SCHEMA_PATH))
    except ImportError:
        for key in ("video_id", "title", "description", "tags",
                    "category_id", "audio_language"):
            if key not in meta:
                raise ValueError(f"metadata missing required field: {key}")
    return True


def find_captions(video_id):
    return sorted(glob.glob(os.path.join(OUTPUT_DIR, f"{video_id}.*.srt")))


def plan(video_id):
    mp4 = os.path.join(OUTPUT_DIR, f"{video_id}.mp4")
    meta_path = os.path.join(OUTPUT_DIR, f"{video_id}.metadata.json")
    if not os.path.isfile(meta_path):
        raise SystemExit(f"ERROR: metadata not found: {meta_path}")
    meta = load_json(meta_path)
    validate_metadata(meta)
    return mp4, meta, find_captions(video_id)


def build_insert_body(meta):
    return {
        "snippet": {
            "title": meta["title"],
            "description": meta["description"],
            "tags": meta.get("tags", []),
            "categoryId": str(meta["category_id"]),
            "defaultLanguage": meta.get("default_language", meta["audio_language"]),
            "defaultAudioLanguage": meta["audio_language"],
        },
        "status": {"privacyStatus": meta.get("privacy_status", "private")},
    }


def write_upload_log(video_id, payload):
    log = os.path.join(OUTPUT_DIR, f"{video_id}.upload.log")
    with open(log, "a", encoding="utf-8") as fh:
        fh.write(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
    return log


def maybe_log_aiuse(video_id, status):
    if not os.path.isdir(os.path.dirname(AI_USE_LOG)):
        return
    today = datetime.date.today().isoformat()
    with open(AI_USE_LOG, "a", encoding="utf-8") as fh:
        fh.write(f"| {today} | publishing | YouTube upload: {video_id} "
                 f"| videos.insert + captions | {status} |\n")


def do_dry_run(video_id):
    mp4, meta, captions = plan(video_id)
    payload = {
        "mode": "dry-run",
        "video_id": video_id,
        "planned_calls": [
            {"api": "youtube.videos.insert", "media": mp4,
             "media_exists": os.path.isfile(mp4),
             "part": ["snippet", "status"], "body": build_insert_body(meta)},
        ] + [
            {"api": "youtube.captions.insert",
             "language": os.path.basename(c).split(".")[-2], "media": c}
            for c in captions
        ],
        "localizations": meta.get("localizations", {}),
        "quota_note": QUOTA_NOTE,
        "api_called": False,
    }
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    log = write_upload_log(video_id, payload)
    maybe_log_aiuse(video_id, "DRY-RUN")
    print(f"\n[dry-run] No API call made. Plan written to {log}")
    return 0


def get_credentials():
    from google.oauth2.credentials import Credentials
    from google_auth_oauthlib.flow import InstalledAppFlow
    from google.auth.transport.requests import Request
    creds = None
    if os.path.isfile(TOKEN):
        creds = Credentials.from_authorized_user_file(TOKEN, SCOPES)
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            if not os.path.isfile(CREDENTIALS):
                raise SystemExit(f"ERROR: {CREDENTIALS} missing. See README.")
            creds = InstalledAppFlow.from_client_secrets_file(
                CREDENTIALS, SCOPES).run_local_server(port=0)
        try:
            with open(TOKEN, "w", encoding="utf-8") as fh:
                fh.write(creds.to_json())
        except OSError:
            print("WARNING: could not persist token (read-only secrets mount).",
                  file=sys.stderr)
    return creds


def do_auth_only():
    get_credentials()
    print("OAuth complete; token stored at secrets/youtube_token.json")
    return 0


def do_upload(video_id):
    from googleapiclient.discovery import build
    from googleapiclient.http import MediaFileUpload
    mp4, meta, captions = plan(video_id)
    if not os.path.isfile(mp4):
        raise SystemExit(f"ERROR: video file not found: {mp4}")
    youtube = build("youtube", "v3", credentials=get_credentials())
    request = youtube.videos().insert(
        part="snippet,status", body=build_insert_body(meta),
        media_body=MediaFileUpload(mp4, chunksize=-1, resumable=True))
    response = None
    while response is None:
        status, response = request.next_chunk()
        if status:
            print(f"  upload {int(status.progress() * 100)}%")
    remote = response["id"]
    print(f"Uploaded: https://youtu.be/{remote}")
    for srt in captions:
        lang = os.path.basename(srt).split(".")[-2]
        youtube.captions().insert(
            part="snippet",
            body={"snippet": {"videoId": remote, "language": lang,
                              "name": lang, "isDraft": False}},
            media_body=MediaFileUpload(srt)).execute()
        print(f"  caption added: {lang}")
    if meta.get("localizations"):
        youtube.videos().update(
            part="localizations",
            body={"id": remote, "localizations": meta["localizations"]}).execute()
    write_upload_log(video_id, {"mode": "upload", "remote_id": remote})
    maybe_log_aiuse(video_id, "UPLOADED")
    return 0


def main():
    p = argparse.ArgumentParser(description="Upload a video to YouTube (Data API v3).")
    p.add_argument("--video", help="video id under output/")
    p.add_argument("--dry-run", action="store_true", help="print plan, no API call")
    p.add_argument("--auth-only", action="store_true", help="run OAuth flow only")
    args = p.parse_args()
    if args.auth_only:
        return do_auth_only()
    if not args.video:
        print("ERROR: --video required (or --auth-only)", file=sys.stderr)
        return 2
    return do_dry_run(args.video) if args.dry_run else do_upload(args.video)


if __name__ == "__main__":
    sys.exit(main())
