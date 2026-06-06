#!/usr/bin/env bash
# smoke_test_marp.sh — Group F Marp end-to-end smoke test.
# Renders the committed documents/marp/test.md (3 slides) to PDF.
set -euo pipefail
C="puma_info_marp_mermaid"
SRC="/work/documents/marp/test.md"
OUT="/work/output/test_marp.pdf"

echo "[marp-smoke] 1/3 rendering test.md -> PDF"
START=$(date +%s)
docker exec "$C" marp "$SRC" -o "$OUT" --allow-local-files
END=$(date +%s)

echo "[marp-smoke] 2/3 verifying"
docker exec "$C" test -s "$OUT" || { echo "[marp-smoke] FAIL: PDF missing/empty"; exit 1; }
SIZE=$(docker exec "$C" stat -c%s "$OUT")
[ "$SIZE" -gt 5120 ] || { echo "[marp-smoke] FAIL: PDF < 5KB ($SIZE B)"; exit 1; }
echo "  size=${SIZE}B  wall-clock=$((END-START))s"

echo "[marp-smoke] 3/3 cleanup"
docker exec "$C" rm -f "$OUT"
echo "[marp-smoke] PASS"
