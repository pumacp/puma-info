#!/usr/bin/env bash
# smoke_test_mermaid.sh — Group F Mermaid end-to-end smoke test.
# Renders documents/mermaid/test.mmd to PNG. mmdc needs --no-sandbox as root,
# supplied via the baked /puppeteer-config.json.
set -euo pipefail
C="puma_info_marp_mermaid"
SRC="/work/documents/mermaid/test.mmd"
OUT="/work/output/test_mermaid.png"

echo "[mermaid-smoke] 1/3 rendering test.mmd -> PNG"
START=$(date +%s)
docker exec "$C" mmdc -i "$SRC" -o "$OUT" -p /puppeteer-config.json
END=$(date +%s)

echo "[mermaid-smoke] 2/3 verifying"
docker exec "$C" test -s "$OUT" || { echo "[mermaid-smoke] FAIL: PNG missing/empty"; exit 1; }
SIZE=$(docker exec "$C" stat -c%s "$OUT")
[ "$SIZE" -gt 1024 ] || { echo "[mermaid-smoke] FAIL: PNG < 1KB ($SIZE B)"; exit 1; }
echo "  size=${SIZE}B  wall-clock=$((END-START))s"

echo "[mermaid-smoke] 3/3 cleanup"
docker exec "$C" rm -f "$OUT"
echo "[mermaid-smoke] PASS"
