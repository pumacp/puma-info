#!/usr/bin/env bash
# smoke_test_inkscape.sh — Group F Inkscape end-to-end smoke test.
# Creates a tiny SVG inside the container, exports it to PNG, verifies.
set -euo pipefail
C="puma_info_inkscape"
SVG="/tmp/test.svg"
PNG="/tmp/test.png"

echo "[inkscape-smoke] 1/3 creating SVG + exporting to PNG"
docker exec "$C" bash -c "cat > ${SVG} <<'SVGEOF'
<svg xmlns='http://www.w3.org/2000/svg' width='200' height='200'>
  <circle cx='100' cy='100' r='80' fill='#2496ED'/>
</svg>
SVGEOF"
START=$(date +%s)
docker exec "$C" inkscape "$SVG" --export-type=png --export-filename="$PNG"
END=$(date +%s)

echo "[inkscape-smoke] 2/3 verifying"
docker exec "$C" test -s "$PNG" || { echo "[inkscape-smoke] FAIL: PNG missing/empty"; exit 1; }
SIZE=$(docker exec "$C" stat -c%s "$PNG")
[ "$SIZE" -gt 100 ] || { echo "[inkscape-smoke] FAIL: PNG < 100B ($SIZE B)"; exit 1; }
echo "  size=${SIZE}B  wall-clock=$((END-START))s"

echo "[inkscape-smoke] 3/3 cleanup"
docker exec "$C" rm -f "$SVG" "$PNG"
echo "[inkscape-smoke] PASS"
