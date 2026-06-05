# Group D · Video

Provides video composition and rendering for the puma-info pipeline.

## Services

| Service | Container | Engine | Use |
|---|---|---|---|
| hyperframes | puma_info_hyperframes | HyperFrames (Node 22 + Puppeteer + FFmpeg) | HTML/CSS/JS/GSAP-based scene composition and MP4 render |
| manim | puma_info_manim | Manim Community Edition | Mathematical and infographic animations |

Both services are CPU-only by default. They can coexist with
Group B's puma_info_ollama (GPU service for translation) without
conflict.

## Operation

```
make video-build               # Build hyperframes and manim images
make video-up                  # Start both services
make video-install-skills      # Install HyperFrames skills into compositions/_template/
make video-new-composition NAME=<id>   # Copy _template to compositions/<id>/
make video-preview NAME=<id>   # Launch preview server on port 3001
make video-render NAME=<id>    # Render compositions/<id> to output/<id>.mp4
make manim-render SCENE=<file>:<class>   # Render a Manim scene
make video-down                # Stop both services
```

## Composing a video

1. `make video-new-composition NAME=video01` creates
   `compositions/video01/` with HyperFrames skills already
   installed.
2. Open the agent of your choice inside that directory.
3. The slash commands from HyperFrames (`/hyperframes`, `/gsap`,
   `/animejs`, `/css-animations`, `/lottie`, `/three`, `/waapi`,
   `/tailwind`, `/hyperframes-cli`, `/hyperframes-media`) become
   available where the host agent supports the skill format.
4. Compose, preview with `make video-preview NAME=video01`,
   render with `make video-render NAME=video01`.

## License notes

  - HyperFrames: Apache-2.0
  - Manim Community Edition: MIT
  - Chromium: BSD-style (Chromium Project)
  - FFmpeg: LGPL/GPL (system package)

All licensing details consolidated in the Group H final report.
