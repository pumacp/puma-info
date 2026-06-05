#!/usr/bin/env bash
# smoke_test_xtts.sh — Group C XTTS v2 start/verify (GPU). NO synthesis:
# no reference voice exists yet (gated behind PAUSE 2). Confirms the model
# loads, is listed, and a CUDA device is visible inside the container.
set -euo pipefail

CONTAINER="puma_info_xtts"
XTTS_MODEL="tts_models/multilingual/multi-dataset/xtts_v2"

echo "[xtts-smoke] 1/4 model loads"
docker exec -e COQUI_TOS_AGREED=1 "${CONTAINER}" python3 -c \
    "from TTS.api import TTS; TTS('${XTTS_MODEL}', progress_bar=False); print('XTTS v2 OK')"

echo "[xtts-smoke] 2/4 model listed"
# Capture the full listing first: piping straight into `grep -q` makes grep
# close the pipe on first match, so the upstream `tts` process hits a broken
# pipe and exits non-zero, which `set -o pipefail` would treat as failure.
MODELS="$(docker exec "${CONTAINER}" tts --list_models 2>/dev/null || true)"
if printf '%s\n' "${MODELS}" | grep -q "${XTTS_MODEL}"; then
    echo "  listed: yes"
else
    echo "[xtts-smoke] FAIL: model not listed"; exit 1
fi

echo "[xtts-smoke] 3/4 nvidia-smi inside container"
docker exec "${CONTAINER}" nvidia-smi \
    --query-gpu=name,memory.total --format=csv,noheader \
    || { echo "[xtts-smoke] FAIL: nvidia-smi unavailable"; exit 1; }

echo "[xtts-smoke] 4/4 torch CUDA available"
docker exec "${CONTAINER}" python3 -c \
    "import torch; assert torch.cuda.is_available(), 'CUDA not available to torch'; print('torch CUDA device:', torch.cuda.get_device_name(0))" \
    || { echo "[xtts-smoke] FAIL: torch CUDA unavailable"; exit 1; }

echo "[xtts-smoke] PASS (no synthesis — no reference voice yet)"
