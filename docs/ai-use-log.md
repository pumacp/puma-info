# AI-Use-Log · puma-info

This log records every significant AI-tool interaction inside the
puma-info subproject, per principle C-4 of the constitution
(Marco Veritas). Entries are append-only and chronological.

| Date (ISO-8601) | Tool family | Purpose | Output | Validation |
|---|---|---|---|---|
| 2026-06-05 | code generation | Bootstrap workspace skeleton | Created directory tree, AGENTS.md, constitution, ADR-001 | Human review pending |
| 2026-06-05 | code-generation | Group A push correction | Amended author to Puma, re-routed origin to github-pumacp; pre-push identity scan returned clean (no non-PUMA references); pushed main to pumacp/puma-info | Human approved |
| 2026-06-05 | code generation | Group B translation stack installation | Added isolated docker-compose (puma_info_ollama:11435, puma_info_libretranslate:5000, puma_info_pdf_translator), Makefile targets, orchestrator script; pinned image+model digests in versions.lock; fixed libretranslate healthcheck (image lacks curl -> Python urllib check) | Human approved |
| 2026-06-05 | translation | Group B end-to-end smoke test | Synthetic 1-page ES PDF translated ES->EN via PDFMathTranslate + qwen2.5:7b backend; mono (6938 B) + dual (7349 B) outputs verified non-empty, 8s wall-clock | PASS |
| 2026-06-05 | code generation | Group C voice stack installation | Added Piper (CPU) + XTTS v2 (GPU) Dockerfiles, compose, orchestrator, smoke tests, ADR-002 (CPML), Makefile gpu-available gate; pinned torch 2.7.1/transformers 4.57.6/coqui-tts 0.27.5 after resolving dependency conflicts; scrubbed legacy references and hardcoded paths from AGENTS.md/Makefile | Human approved |
| 2026-06-05 | TTS | Group C Piper smoke test | Synthesized "PUMA: understand, measure, decide." via Piper en_US-amy-medium; WAV 2.87s @ 22050 Hz, 126508 B; XTTS v2 verified (model loads, listed, CUDA visible) without synthesis | PASS |
| 2026-06-05 | code generation | Group D video stack installation | Built HyperFrames (node22+chromium+ffmpeg, hyperframes 0.6.74) and Manim CE v0.20.1 CPU images, compose, orchestrator, smoke tests, ADR-003; HyperFrames skills (15 bundles) installed locally under .agents/ and gitignored per zero-brand policy; pinned base digests in versions.lock | Human approved |
| 2026-06-05 | video render | Group D smoke tests | HyperFrames rendered blank starter to 10s MP4 (26200 B, 12s); Manim rendered TestScene circle to 1.0s MP4 (6055 B); both verified | PASS |
| 2026-06-05 | code generation | Group E publish stack installation | Built WhisperX (large-v3, torch 2.8.0+cu126) GPU image and YouTube uploader (google-api-python-client 2.197.0) CPU image, compose, orchestrator scripts (subtitles/metadata/upload), metadata JSON schema, ADR-004, Makefile gates; secrets gitignored; pinned digests | Human approved |
| 2026-06-05 | transcription | Group E smoke tests | WhisperX transcribed a Piper-synthesized phrase to SRT ("PUMA Project measures local language models objectively.", 25s); uploader dry-run planned videos.insert + captions.insert with no real API call | PASS |
