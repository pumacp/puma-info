#!/usr/bin/env bash
# smoke_test_quarto.sh — Group F Quarto end-to-end smoke test.
# Renders the committed documents/quarto/test.qmd to PDF and verifies it.
set -euo pipefail
C="puma_info_quarto"
SRC="/work/documents/quarto/test.qmd"
OUT="/work/output/test.pdf"

echo "[quarto-smoke] 1/3 rendering test.qmd -> PDF"
START=$(date +%s)
docker exec "$C" quarto render "$SRC" --to pdf --output-dir /work/output
END=$(date +%s)

echo "[quarto-smoke] 2/3 verifying"
docker exec "$C" test -s "$OUT" || { echo "[quarto-smoke] FAIL: PDF missing/empty"; exit 1; }
SIZE=$(docker exec "$C" stat -c%s "$OUT")
[ "$SIZE" -gt 5120 ] || { echo "[quarto-smoke] FAIL: PDF < 5KB ($SIZE B)"; exit 1; }
if docker exec "$C" sh -c 'command -v pdfinfo >/dev/null 2>&1'; then
    PAGES=$(docker exec "$C" pdfinfo "$OUT" | awk '/^Pages:/{print $2}')
    echo "  pages=${PAGES}"
    [ "${PAGES:-0}" -gt 0 ] || { echo "[quarto-smoke] FAIL: 0 pages"; exit 1; }
fi
echo "  size=${SIZE}B  wall-clock=$((END-START))s"

echo "[quarto-smoke] 3/3 cleanup"
docker exec "$C" rm -f "$OUT"
echo "[quarto-smoke] PASS"
