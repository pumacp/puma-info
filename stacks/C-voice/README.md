# Group C · Voice

Provides narration synthesis for the puma-info pipeline.

## Services

| Service | Container | Engine | Use | GPU |
|---|---|---|---|---|
| piper | puma_info_piper | Piper TTS | English narration for divulgative videos | No |
| xtts | puma_info_xtts | XTTS v2 (Coqui TTS) | Multilingual voice cloning | Yes (~4-6 GB) |

## Operation

```
make voice-up-piper           # Start CPU service (Piper)
make voice-test-piper         # Smoke test: synthesize a short phrase
make voice-up-xtts            # Start GPU service (XTTS) — requires GPU available
make voice-test-xtts          # Verify model loads; full cloning gated on PAUSE 2
make voice-down               # Stop both services
```

## GPU mutual exclusion

XTTS holds ~4-6 GB VRAM on an RTX 2060 (6 GB total). It cannot run
concurrently with Group B's Ollama, Group D's HyperFrames render
pipeline, Group E's WhisperX, or Group G's Stable Diffusion. The
Makefile gate `gpu-available` blocks `voice-up-xtts` if any
puma_info container with label `gpu=true` is already running.
Release manually with `make gpu-release` before switching stacks.

## Voice cloning workflow (deferred to PAUSE 2)

1. Record a 30-60 second reference WAV of the target narrator,
   reading neutral technical text in the target language. Place
   the file at `voice/reference/<name>_<lang>.wav`.
2. Create the approval marker: `touch
   approvals/02_reference_voice_approved`.
3. Run `make narration-clone REFERENCE=<name>_<lang>.wav
   TEXT_FILE=<path>`.

Reference voice files are listed in `.gitignore` and never committed
to the public repository.

## License notes

  - piper-tts: MIT/GPL (per package metadata).
  - en_US-amy-medium voice: see model card in piper-voices.
  - coqui-tts: MPL-2.0 (the package).
  - XTTS v2 model weights: Coqui Public Model License (CPML).
    Academic non-commercial use is permitted; see ADR-002 for the
    full rationale and the `COQUI_TOS_AGREED=1` acceptance.
