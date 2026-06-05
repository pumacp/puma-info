#!/usr/bin/env bash
# smoke_test_piper.sh — Group C Piper end-to-end smoke test (CPU-only).
# Synthesizes a short phrase inside puma_info_piper and verifies the WAV
# with ffprobe (duration > 1 s, sample rate 22050 Hz). No GPU interaction.
set -euo pipefail

CONTAINER="puma_info_piper"
MODEL="/voices/en_US-amy-medium/en_US-amy-medium.onnx"
OUT="/tmp/piper_smoke.wav"
PHRASE="PUMA: understand, measure, decide."

echo "[piper-smoke] 1/3 synthesizing: ${PHRASE}"
docker exec "${CONTAINER}" python3 -m piper -m "${MODEL}" -f "${OUT}" -- "${PHRASE}"

echo "[piper-smoke] 2/3 probing output"
DUR=$(docker exec "${CONTAINER}" ffprobe -v error \
    -show_entries format=duration -of default=nw=1:nk=1 "${OUT}")
SR=$(docker exec "${CONTAINER}" ffprobe -v error -select_streams a:0 \
    -show_entries stream=sample_rate -of default=nw=1:nk=1 "${OUT}")
SIZE=$(docker exec "${CONTAINER}" stat -c%s "${OUT}")
echo "  duration=${DUR}s  sample_rate=${SR}Hz  size=${SIZE}B"

echo "[piper-smoke] 3/3 verifying thresholds"
awk "BEGIN{exit !(${DUR} > 1.0)}" \
    || { echo "[piper-smoke] FAIL: duration <= 1s"; exit 1; }
[ "${SR}" = "22050" ] \
    || { echo "[piper-smoke] FAIL: sample_rate != 22050"; exit 1; }

docker exec "${CONTAINER}" rm -f "${OUT}"
echo "[piper-smoke] PASS"
