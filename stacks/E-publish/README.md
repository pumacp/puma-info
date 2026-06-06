# Group E · Publish

Transcription and YouTube upload for the puma-info pipeline.

## Services

| Service | Container | Engine | GPU |
|---|---|---|---|
| whisperx | puma_info_whisper | WhisperX (large-v3) | Yes (~3 GB) |
| uploader | puma_info_uploader | YouTube Data API v3 client | No |

WhisperX cannot run concurrently with Group B's Ollama or Group C's
XTTS v2. The Makefile gate `gpu-available` enforces this.

## Operation

```
make publish-build              # Build both images
make publish-up-whisper         # Start WhisperX (GPU; requires gpu-available)
make publish-up-uploader        # Start uploader (CPU)
make publish-test-whisper       # Smoke test transcription
make publish-test-uploader      # Smoke test uploader (dry-run, no real API)
make subs-<id>                  # Generate output/<id>.en.srt from output/<id>.mp4
make metadata-<id>              # Generate output/<id>.metadata.json from specs/<id>.json
make upload-dry-<id>            # Dry-run YouTube upload
make publish-auth               # Interactive OAuth flow (one-time)
make upload-<id>                # Real upload (gated by approvals/03_youtube_credentials_approved)
make publish-down               # Stop both services
```

## YouTube credentials setup (operator-side, one-time)

1. Create a project in https://console.cloud.google.com
2. Enable the YouTube Data API v3
3. Create OAuth 2.0 credentials (Desktop application type)
4. Download `credentials.json`, place at `secrets/youtube_credentials.json`
5. Run `make publish-auth` once to complete the OAuth flow.
   This produces `secrets/youtube_token.json` (refresh token persists).
6. Create the approval marker:
   `touch approvals/03_youtube_credentials_approved`

The `secrets/` directory is gitignored. Never commit credentials.

## Auto-dubbing

YouTube's automatic dubbing is enabled at the channel level via
YouTube Studio → Settings → Channel → Advanced settings →
Allow automatic dubbing. Once enabled, any video uploaded with a
`defaultAudioLanguage` declared in its metadata is eligible for
auto-dub to nine target languages (es, fr, de, hi, id, it, ja, pt).

The uploader sets `snippet.defaultAudioLanguage` from the metadata
file. Auto-dubbing then happens server-side; puma-info does not
generate dubbed audio tracks itself.

## License notes

  - WhisperX: BSD-2-Clause
  - faster-whisper (transitive): MIT
  - CTranslate2 (transitive): MIT
  - torch / torchaudio: BSD-style
  - google-api-python-client: Apache-2.0
