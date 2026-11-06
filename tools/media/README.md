# Media tools

Local video/audio toolchain, kept outside the pnpm workspace (it is not an app or a package of the monorepo).

| Tool                                          | What it does                    | Installed as                                        | Version                   |
| --------------------------------------------- | ------------------------------- | --------------------------------------------------- | ------------------------- |
| [Remotion](https://www.remotion.dev)          | Videos as React components      | `remotion`, `@remotion/cli` (pnpm, `node_modules/`) | 4.0.541                   |
| [HyperFrames](https://hyperframes.heygen.com) | Videos as HTML + GSAP timelines | `hyperframes` (pnpm, `node_modules/`)               | 0.9.19                    |
| [FFmpeg](https://ffmpeg.org)                  | Encoding, probing, cutting      | system package (`apt-get install ffmpeg`)           | 6.1.1                     |
| [Whisper](https://github.com/openai/whisper)  | Speech-to-text                  | `openai-whisper` (Python venv, `.venv/`)            | 20250625 (PyTorch 2.15.0) |
| [yt-dlp](https://github.com/yt-dlp/yt-dlp)    | Download video/audio from URLs  | `yt-dlp` (Python venv, `.venv/`)                    | 2026.10.26                |

## Setup

Requirements: Node.js >= 22, pnpm, Python >= 3.10, FFmpeg on `PATH`.

```bash
cd tools/media

# Node tools (Remotion, HyperFrames, GSAP). --ignore-workspace keeps this out of the monorepo install.
pnpm install --ignore-workspace

# Python tools (Whisper, yt-dlp)
python3 -m venv .venv
.venv/bin/pip install openai-whisper yt-dlp
# Optional, much smaller CPU-only PyTorch (install BEFORE openai-whisper):
#   .venv/bin/pip install torch --index-url https://download.pytorch.org/whl/cpu

# FFmpeg (Debian/Ubuntu); macOS: brew install ffmpeg
sudo apt-get install -y ffmpeg
# Optional: espeak-ng lets the test script synthesize real speech for Whisper
sudo apt-get install -y espeak-ng
```

`postinstall` copies `gsap.min.js` into `hyperframes-demo/assets/vendor/` so HyperFrames renders do not depend on a CDN.

## Test everything

```bash
pnpm test          # = bash test-tools.sh
```

It renders/encodes a short clip with each tool into `out/` (git-ignored) and prints a pass/fail summary:

- **FFmpeg** — encodes a 2 s test pattern + tone (`out/ffmpeg-test.mp4`)
- **Remotion** — renders the `HelloWorld` composition (`out/remotion-hello.mp4`)
- **HyperFrames** — renders `hyperframes-demo/` (`out/hyperframes-hello.mp4`)
- **Whisper** — transcribes a synthesized sentence with the `tiny.en` model (`WHISPER_MODEL=base` to change)
- **yt-dlp** — downloads a video from a local HTTP server, then reads a YouTube video's metadata

Network hosts used at runtime: `openaipublic.azureedge.net` (Whisper model weights, first run only) and `www.youtube.com` (yt-dlp). Downloading actual YouTube media also needs the `*.googlevideo.com` CDN.

## Everyday usage

```bash
# Remotion
pnpm remotion:studio                         # edit compositions in the browser
pnpm remotion:render                         # -> out/remotion-hello.mp4

# HyperFrames
cd hyperframes-demo && npx hyperframes preview
npx hyperframes render . -o ../out/video.mp4

# Whisper
.venv/bin/whisper audio.mp3 --model small --language pt --output_format srt

# yt-dlp
.venv/bin/yt-dlp -f "bv*+ba/b" -o "out/%(title)s.%(ext)s" "<url>"
.venv/bin/yt-dlp -x --audio-format mp3 "<url>"   # audio only (uses FFmpeg)
```

If a pre-installed Chromium exists, point the renderers at it with `CHROMIUM_PATH=/path/to/chrome` (the test script also picks up `/opt/pw-browsers/chromium` automatically); otherwise Remotion and HyperFrames download their own headless browser.
