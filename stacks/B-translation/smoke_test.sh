#!/usr/bin/env bash
# smoke_test.sh — Group B end-to-end translation smoke test.
#
# 1. Generates a 1-page synthetic Spanish PDF with ReportLab inside a
#    one-shot python:3.12-slim container (no host Python deps).
# 2. Translates it ES->EN via the puma_info_pdf_translator service,
#    backed by the dedicated puma_info_ollama (host port 11435).
# 3. Verifies mono + dual outputs exist and are non-empty; reports timing.
#
# Isolation: touches only puma_info_* resources and transient --rm
# helper containers. Never uses host port 11434.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${HERE}/../.." && pwd)"
INPUT="${REPO}/translation/input_es"
OUTPUT="${REPO}/translation/output_en"
BILINGUAL="${REPO}/translation/bilingual"
TESTNAME="smoke_test_es"

mkdir -p "${INPUT}" "${OUTPUT}" "${BILINGUAL}"

echo "[smoke] 1/4 generating synthetic Spanish PDF via reportlab container"
docker run --rm --label puma_info=true \
    -v "${INPUT}:/out" \
    python:3.12-slim \
    bash -c "pip install --quiet reportlab && python -c \"
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
c = canvas.Canvas('/out/${TESTNAME}.pdf', pagesize=A4)
t = c.beginText(72, 770)
t.setFont('Helvetica', 12)
for line in [
    'Prueba de traduccion automatica del proyecto PUMA.',
    'Este documento contiene una sola pagina de texto.',
    'El objetivo es verificar la canalizacion de traduccion.',
    'La energia es igual a la masa por la velocidad al cuadrado.',
]:
    t.textLine(line)
c.drawText(t)
c.showPage()
c.save()
print('generated /out/${TESTNAME}.pdf')
\""

test -s "${INPUT}/${TESTNAME}.pdf" || { echo "[smoke] FAIL: test PDF not created"; exit 1; }

echo "[smoke] 2/4 translating via pdf_translator (ES->EN, ollama:qwen2.5:7b)"
START=$(date +%s)
( cd "${REPO}/stacks/B-translation" && \
  docker compose run --rm pdf_translator \
      pdf2zh "/app/input/${TESTNAME}.pdf" \
      -s "ollama:qwen2.5:7b" -li es -lo en -o /app/output )
END=$(date +%s)

echo "[smoke] 3/4 verifying outputs"
MONO="${OUTPUT}/${TESTNAME}-mono.pdf"
DUAL="${OUTPUT}/${TESTNAME}-dual.pdf"
test -s "${MONO}" || { echo "[smoke] FAIL: mono output missing/empty: ${MONO}"; exit 1; }
test -s "${DUAL}" || { echo "[smoke] FAIL: dual output missing/empty: ${DUAL}"; exit 1; }
# Move dual into the bilingual directory, matching the batch script behaviour.
mv -f "${DUAL}" "${BILINGUAL}/${TESTNAME}-dual.pdf"

echo "[smoke] 4/4 PASS"
echo "  mono: ${MONO} ($(stat -c%s "${MONO}") bytes)"
echo "  dual: ${BILINGUAL}/${TESTNAME}-dual.pdf ($(stat -c%s "${BILINGUAL}/${TESTNAME}-dual.pdf") bytes)"
echo "  wall-clock: $((END-START))s"
