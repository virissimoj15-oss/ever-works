#!/usr/bin/env bash
# Smoke-tests every tool in the media toolchain. Run from anywhere:
#   bash tools/media/test-tools.sh          (or: cd tools/media && pnpm test)
# Outputs go to tools/media/out/ (git-ignored).
set -uo pipefail

cd "$(dirname "$0")"
OUT="$PWD/out"
VENV="$PWD/.venv/bin"
mkdir -p "$OUT"

# Use a pre-installed Chromium when there is one (e.g. cloud containers);
# otherwise Remotion / HyperFrames download their own headless shell.
BROWSER_ARGS=()
for c in "${CHROMIUM_PATH:-}" /opt/pw-browsers/chromium; do
	if [ -n "$c" ] && [ -x "$c" ]; then
		export PUPPETEER_EXECUTABLE_PATH="$c"
		BROWSER_ARGS=(--browser-executable="$c")
		break
	fi
done

PASS=()
FAIL=()
ok() { PASS+=("$1"); printf '\033[32m✔ %s\033[0m\n' "$1"; }
ko() { FAIL+=("$1"); printf '\033[31m✘ %s\033[0m\n' "$1"; }
duration() { ffprobe -v error -show_entries format=duration -of csv=p=0 "$1" 2>/dev/null; }

echo "== FFmpeg =="
ffmpeg -version | head -1
if ffmpeg -y -loglevel error -f lavfi -i testsrc=size=640x360:rate=30 -f lavfi -i sine=frequency=440 \
	-t 2 -c:v libx264 -pix_fmt yuv420p -c:a aac "$OUT/ffmpeg-test.mp4" && [ -s "$OUT/ffmpeg-test.mp4" ]; then
	ok "FFmpeg: encoded out/ffmpeg-test.mp4 ($(duration "$OUT/ffmpeg-test.mp4")s)"
else
	ko "FFmpeg"
fi

echo "== Remotion =="
npx remotion --version 2>/dev/null | tail -1
if npx remotion render remotion/index.ts HelloWorld "$OUT/remotion-hello.mp4" "${BROWSER_ARGS[@]}" --log=error \
	&& [ -s "$OUT/remotion-hello.mp4" ]; then
	ok "Remotion: rendered out/remotion-hello.mp4 ($(duration "$OUT/remotion-hello.mp4")s)"
else
	ko "Remotion"
fi

echo "== HyperFrames =="
npx hyperframes --version 2>/dev/null | tail -1
if (cd hyperframes-demo && npx hyperframes render . -o "$OUT/hyperframes-hello.mp4" --quality draft --quiet) \
	&& [ -s "$OUT/hyperframes-hello.mp4" ]; then
	ok "HyperFrames: rendered out/hyperframes-hello.mp4 ($(duration "$OUT/hyperframes-hello.mp4")s)"
else
	ko "HyperFrames"
fi

echo "== Whisper =="
"$VENV/whisper" --help >/dev/null 2>&1 && "$VENV/pip" show openai-whisper 2>/dev/null | grep -i '^version'
PHRASE="Hello world. This is a test of the Whisper transcription."
if command -v espeak-ng >/dev/null; then
	espeak-ng -w "$OUT/speech.wav" "$PHRASE"
else
	echo "espeak-ng not found: using a silent clip (only checks that Whisper runs)"
	ffmpeg -y -loglevel error -f lavfi -i anullsrc=r=16000:cl=mono -t 2 "$OUT/speech.wav"
fi
if "$VENV/whisper" "$OUT/speech.wav" --model "${WHISPER_MODEL:-tiny.en}" --language en --fp16 False \
	--output_dir "$OUT" --output_format txt >/dev/null 2>&1 && [ -f "$OUT/speech.txt" ]; then
	TEXT="$(tr -s '[:space:]' ' ' <"$OUT/speech.txt")"
	if ! command -v espeak-ng >/dev/null || grep -qi "test" <<<"$TEXT"; then
		ok "Whisper: transcribed -> \"$TEXT\""
	else
		ko "Whisper: unexpected transcript \"$TEXT\""
	fi
else
	ko "Whisper (model download needs openaipublic.azureedge.net)"
fi

echo "== yt-dlp =="
"$VENV/yt-dlp" --version
# Offline check: download a file over HTTP from a local server (generic extractor).
PORT=8765
python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$OUT" >/dev/null 2>&1 &
SERVER=$!
sleep 1
rm -f "$OUT/yt-dlp-local.mp4"
if "$VENV/yt-dlp" -q --no-warnings -o "$OUT/yt-dlp-local.mp4" "http://127.0.0.1:$PORT/ffmpeg-test.mp4" \
	&& [ -s "$OUT/yt-dlp-local.mp4" ]; then
	ok "yt-dlp: downloaded a local HTTP video"
else
	ko "yt-dlp (local download)"
fi
kill "$SERVER" 2>/dev/null
# Online check: read YouTube metadata (no media download).
TITLE="$("$VENV/yt-dlp" --no-warnings --skip-download --print title "https://www.youtube.com/watch?v=jNQXAC9IVRw" 2>&1 | tail -1)"
if [ -n "$TITLE" ] && ! grep -qi 'error' <<<"$TITLE"; then
	ok "yt-dlp: read YouTube metadata -> \"$TITLE\""
else
	ko "yt-dlp (YouTube metadata): $TITLE"
fi

echo
echo "Passed: ${#PASS[@]}  Failed: ${#FAIL[@]}"
[ "${#FAIL[@]}" -eq 0 ]
