# ADR-004 · Publishing stack (WhisperX + YouTube)

Status: Accepted
Date: 2026-06-05
Context: puma-info must generate subtitles for its videos and publish them to
YouTube, in a reproducible, local-first way.

## Decisions

  - **WhisperX over plain faster-whisper.** WhisperX adds word-level
    alignment (accurate subtitle timing) and is diarization-ready for future
    multi-speaker content. It runs on the GPU (large-v3, ~3 GB VRAM) and is
    subject to the `gpu-available` mutual-exclusion gate.
  - **Independent torch pin.** The WhisperX image pins torch 2.8.0+cu126
    (whisperx requires torch~=2.8.0), separate from the XTTS image's
    torch 2.7.1+cu126. The two never share a Python environment.
  - **No locally generated localized subtitles or dubs.** We ship one English
    SRT per video and declare `defaultAudioLanguage`. YouTube auto-translates
    captions client-side and auto-dubs server-side (channel setting).
    puma-info does not generate translated SRTs or dubbed audio.
  - **Metadata is human-authored.** `06_generate_metadata.py` scaffolds a
    schema-valid stub and emits a prompt; it never calls an external LLM.
    Titles/descriptions are creative decisions requiring human review (C-4).
  - **Secrets and approval gate.** OAuth credentials/tokens live only in
    `secrets/` (gitignored). Real uploads require both valid credentials and
    the `approvals/03_youtube_credentials_approved` marker; smoke tests are
    dry-run only and make no API calls.

## Quota

  YouTube Data API v3 default quota is 10,000 units/day. videos.insert costs
  ~1,600 units, captions.insert ~400. Ten videos with captions fit within a
  single day's quota; uploads are run deliberately, not in automated batches.

## Consequences

  - One SRT per video keeps the pipeline simple and leverages YouTube's
    translation/dubbing instead of duplicating it locally.
  - The GPU mutex means transcription is serialized with narration (Group C)
    and translation (Group B).
