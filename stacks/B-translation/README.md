# Group B · Translation

Provides PDF and short-text translation for the puma-info pipeline.

## Services

| Service | Container | Host port | Purpose |
|---|---|---|---|
| ollama | puma_info_ollama | 11435 | LLM backend (qwen2.5:7b) for PDFMathTranslate |
| libretranslate | puma_info_libretranslate | 5000 | REST API for short-text translations |
| pdf_translator | puma_info_pdf_translator | n/a | CLI invocation of PDFMathTranslate |

All services attach to the isolated `puma_info_network`. None of them
touches the existing PUMA Project Ollama on host port 11434.

## Operation

```
make translation-up           # Start ollama + libretranslate
make translation-pull-models  # Pull qwen2.5:7b into puma_info_ollama
make translation-smoke-test   # End-to-end test on a 1-page test PDF
make translation-run          # Translate every PDF in translation/input_es/
                              # (gated behind approvals/01_pdf_translation_approved)
make translation-down         # Stop all Group B services
```

## Notes on GPU

The Ollama service requests one NVIDIA GPU. qwen2.5:7b needs
approximately 5 GB of VRAM. The Group B services are mutually
exclusive with Group C/D/E/G GPU services — start only one stack at
a time. See `make gpu-status` and `make gpu-release` in the root
Makefile.

## License notes

  - PDFMathTranslate: see upstream LICENSE in
    https://github.com/PDFMathTranslate/PDFMathTranslate
  - LibreTranslate: AGPLv3
  - Ollama: MIT
  - qwen2.5:7b: model weights under their respective Hugging Face
    license terms; PUMA uses them locally for translation only

All licensing notes for the consolidated tool inventory will appear
in the Group H final report.
