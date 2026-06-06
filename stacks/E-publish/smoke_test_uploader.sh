#!/usr/bin/env bash
# smoke_test_uploader.sh — Group E uploader DRY-RUN smoke test.
# Builds a schema-valid metadata.json + placeholder MP4 + caption in output/,
# then runs the uploader in --dry-run. MUST NOT make any real YouTube API call.
set -euo pipefail

UPLOADER="puma_info_uploader"
VID="tmp_smoke"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${REPO}/output"
mkdir -p "${OUT}"

echo "[up-smoke] 1/4 creating placeholder MP4 + metadata + caption"
: > "${OUT}/${VID}.mp4"               # placeholder (dry-run checks existence only)
cat > "${OUT}/${VID}.metadata.json" <<JSON
{
  "video_id": "${VID}",
  "title": "PUMA smoke test (placeholder)",
  "description": "Dry-run smoke test metadata. Not a real upload.",
  "tags": ["PUMA", "smoke-test"],
  "category_id": "28",
  "audio_language": "en",
  "default_language": "en"
}
JSON
printf '1\n00:00:00,000 --> 00:00:02,000\nPUMA smoke test.\n\n' > "${OUT}/${VID}.en.srt"

echo "[up-smoke] 2/4 running uploader --dry-run (no API call)"
OUTPUT=$(docker exec "${UPLOADER}" python3 \
    /work/orchestrator/scripts/07_upload_youtube.py --video "${VID}" --dry-run)
echo "${OUTPUT}"

echo "[up-smoke] 3/4 asserting dry-run made no API call and planned the right calls"
echo "${OUTPUT}" | grep -q '"api_called": false' \
    || { echo "[up-smoke] FAIL: api_called not false"; exit 1; }
echo "${OUTPUT}" | grep -q 'youtube.videos.insert' \
    || { echo "[up-smoke] FAIL: videos.insert not planned"; exit 1; }
echo "${OUTPUT}" | grep -q 'youtube.captions.insert' \
    || { echo "[up-smoke] FAIL: captions.insert not planned"; exit 1; }

echo "[up-smoke] 4/4 cleanup"
rm -f "${OUT}/${VID}.mp4" "${OUT}/${VID}.metadata.json" "${OUT}/${VID}.en.srt" "${OUT}/${VID}.upload.log"
echo "[up-smoke] PASS"
