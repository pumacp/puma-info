#!/usr/bin/env bash
# smoke_test_whisper.sh — Group E WhisperX end-to-end smoke test.
# Synthesizes an English phrase with the Group C Piper image, transcribes it
# with WhisperX (large-v3) on GPU, and verifies the SRT contains "PUMA".
set -euo pipefail

WHISPER="puma_info_whisper"
PIPER_IMAGE="pumacp/puma-info-piper:0.1.0"
TMP="$(mktemp -d)"
PHRASE="PUMA Project measures local language models objectively."
WAV="${TMP}/smoke.wav"

echo "[wx-smoke] 1/5 synthesizing English audio (Piper, CPU one-shot)"
docker run --rm -v "${TMP}:/out" --label puma_info=true "${PIPER_IMAGE}" \
    python3 -m piper -m /voices/en_US-amy-medium/en_US-amy-medium.onnx \
    -f /out/smoke.wav -- "${PHRASE}"
test -s "${WAV}" || { echo "[wx-smoke] FAIL: audio not generated"; exit 1; }

echo "[wx-smoke] 2/5 copying audio into ${WHISPER}"
docker cp "${WAV}" "${WHISPER}:/work/smoke.wav"

echo "[wx-smoke] 3/5 transcribing with WhisperX large-v3 (GPU)"
START=$(date +%s)
docker exec "${WHISPER}" whisperx /work/smoke.wav \
    --model large-v3 --language en --compute_type float16 \
    --output_format srt --output_dir /work
END=$(date +%s)

echo "[wx-smoke] 4/5 verifying SRT"
docker exec "${WHISPER}" test -s /work/smoke.srt \
    || { echo "[wx-smoke] FAIL: SRT missing/empty"; exit 1; }
SNIPPET=$(docker exec "${WHISPER}" cat /work/smoke.srt)
echo "--- transcript ---"; echo "${SNIPPET}"; echo "------------------"
echo "${SNIPPET}" | grep -iq "puma" \
    || { echo "[wx-smoke] FAIL: 'PUMA' not found in transcript"; exit 1; }

echo "[wx-smoke] 5/5 cleanup"
docker exec "${WHISPER}" rm -f /work/smoke.wav /work/smoke.srt
rm -rf "${TMP}"
echo "[wx-smoke] PASS (wall-clock $((END-START))s)"
