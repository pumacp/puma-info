#!/usr/bin/env bash
# smoke_test_libreoffice.sh — Group F slides round-trip smoke test.
# Proves: (1) editable .pptx export via pandoc (real <a:t> text runs, NOT
# Marp-style image-only slides); (2) LibreOffice .pptx import -> pdf and
# html; (3) the documented pptx->html->md bridge (LibreOffice + pandoc).
# Files live under the output/ mount; verification runs on the host with
# python3 (stdlib zipfile).
set -euo pipefail
LO="puma_info_libreoffice"; QU="puma_info_quarto"
HOSTDIR="output/_lo-smoke"; CDIR="/work/output/_lo-smoke"
P="-env:UserInstallation=file:///tmp/lo-profile"
mkdir -p "$HOSTDIR"

echo "[lo-smoke] 1/5 seed markdown"
printf '%% Deck\n\n# Slide one\n\nPUMA editable test bullet.\n\n# Slide two\n\nSecond slide.\n' > "$HOSTDIR/seed.md"

echo "[lo-smoke] 2/5 EXPORT seed.md -> editable seed.pptx (pandoc, no LibreOffice)"
docker exec "$QU" quarto pandoc "$CDIR/seed.md" -o "$CDIR/seed.pptx"
test -s "$HOSTDIR/seed.pptx" || { echo "[lo-smoke] FAIL: pptx missing"; exit 1; }

echo "[lo-smoke] 3/5 VERIFY editability: real <a:t> text runs, no image-only slides"
python3 - "$HOSTDIR/seed.pptx" <<'PY'
import sys, zipfile
z = zipfile.ZipFile(sys.argv[1])
slides = [n for n in z.namelist() if n.startswith('ppt/slides/slide') and n.endswith('.xml')]
alltxt = "".join(z.read(s).decode('utf-8', 'ignore') for s in slides)
media = [n for n in z.namelist() if n.startswith('ppt/media/')]
assert '<a:t>' in alltxt and 'PUMA' in alltxt, "FAIL: no editable <a:t> text run with PUMA"
print(f"  ok {len(slides)} slides, editable <a:t> runs incl. 'PUMA'; ppt/media entries={len(media)} (0 = no image-only slides)")
PY

echo "[lo-smoke] 4/5 IMPORT seed.pptx -> pdf AND html (LibreOffice)"
docker exec "$LO" soffice --headless $P --convert-to pdf  --outdir "$CDIR" "$CDIR/seed.pptx" >/dev/null
docker exec "$LO" soffice --headless $P --convert-to html --outdir "$CDIR" "$CDIR/seed.pptx" >/dev/null
test -s "$HOSTDIR/seed.pdf"  || { echo "[lo-smoke] FAIL: pdf missing"; exit 1; }
test -s "$HOSTDIR/seed.html" || { echo "[lo-smoke] FAIL: html missing"; exit 1; }
echo "  ok seed.pdf and seed.html produced"

echo "[lo-smoke] 5/5 BRIDGE pptx->html->md (LibreOffice + pandoc), text survives"
docker exec "$QU" quarto pandoc "$CDIR/seed.html" -o "$CDIR/seed.bridge.md"
grep -qi PUMA "$HOSTDIR/seed.bridge.md" \
  && echo "  ok pptx->html->md retains 'PUMA'" \
  || { echo "[lo-smoke] FAIL: text lost in bridge"; exit 1; }

rm -rf "$HOSTDIR"; docker exec "$LO" rm -rf /tmp/lo-profile 2>/dev/null || true
echo "[lo-smoke] PASS"
