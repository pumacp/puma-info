#!/usr/bin/env bash
# smoke_test_hyperframes.sh — Group D HyperFrames end-to-end smoke test.
# Scaffolds the blank starter composition inside puma_info_hyperframes,
# renders it to MP4, verifies the MP4 with ffprobe, then cleans up.
set -euo pipefail

CONTAINER="puma_info_hyperframes"
NAME="smoke-test"
WORK="/tmp/${NAME}"
OUT="/tmp/smoke.mp4"

echo "[hf-smoke] 1/5 scaffolding blank composition"
docker exec "${CONTAINER}" bash -c \
    "rm -rf ${WORK} && cd /tmp && npx hyperframes init ${NAME} --example blank"

echo "[hf-smoke] 2/5 confirming starter files"
docker exec "${CONTAINER}" bash -c "ls -la ${WORK}/index.html"

echo "[hf-smoke] 3/5 rendering to MP4"
START=$(date +%s)
docker exec "${CONTAINER}" bash -c \
    "cd ${WORK} && npx hyperframes render --output ${OUT}"
END=$(date +%s)

echo "[hf-smoke] 4/5 verifying output"
docker exec "${CONTAINER}" bash -c "test -s ${OUT}" \
    || { echo "[hf-smoke] FAIL: MP4 missing/empty"; exit 1; }
DUR=$(docker exec "${CONTAINER}" ffprobe -v error \
    -show_entries format=duration -of default=nw=1:nk=1 "${OUT}")
SIZE=$(docker exec "${CONTAINER}" stat -c%s "${OUT}")
echo "  duration=${DUR}s  size=${SIZE}B  wall-clock=$((END-START))s"
awk "BEGIN{exit !(${DUR} > 0)}" \
    || { echo "[hf-smoke] FAIL: duration not > 0"; exit 1; }

echo "[hf-smoke] 5/5 cleanup"
docker exec "${CONTAINER}" bash -c "rm -rf ${WORK} ${OUT}"
echo "[hf-smoke] PASS"
