#!/usr/bin/env bash
# smoke_test_manim.sh — Group D Manim end-to-end smoke test.
# Renders a tiny scene (a circle) inside puma_info_manim at low quality,
# verifies the resulting MP4 with ffprobe, then cleans up.
set -euo pipefail

CONTAINER="puma_info_manim"
SCENE="/tmp/test_scene.py"

echo "[manim-smoke] 1/4 writing test scene"
docker exec "${CONTAINER}" bash -c "cat > ${SCENE} <<'PY'
from manim import Scene, Circle, Create

class TestScene(Scene):
    def construct(self):
        self.play(Create(Circle()))
PY"

echo "[manim-smoke] 2/4 rendering (low quality)"
START=$(date +%s)
docker exec "${CONTAINER}" bash -c "cd /tmp && manim -ql ${SCENE} TestScene -o test"
END=$(date +%s)

echo "[manim-smoke] 3/4 verifying output"
MP4=$(docker exec "${CONTAINER}" bash -c "find /tmp/media -name 'test.mp4' | head -1")
[ -n "${MP4}" ] || { echo "[manim-smoke] FAIL: output MP4 not found"; exit 1; }
# Manim v0.20.x encodes via PyAV; the image has no system ffprobe, so probe
# the MP4 with PyAV (duration + size) inside the container.
read -r DUR SIZE <<< "$(docker exec "${CONTAINER}" python3 -c \
    "import av, os; p='${MP4}'; c=av.open(p); s=c.streams.video[0]; \
print('%.3f %d' % (float(s.duration * s.time_base), os.path.getsize(p)))")"
echo "  output=${MP4}  duration=${DUR}s  size=${SIZE}B  wall-clock=$((END-START))s"
awk "BEGIN{exit !(${DUR} > 0)}" \
    || { echo "[manim-smoke] FAIL: duration not > 0"; exit 1; }

echo "[manim-smoke] 4/4 cleanup"
docker exec "${CONTAINER}" bash -c "rm -rf /tmp/media ${SCENE}"
echo "[manim-smoke] PASS"
