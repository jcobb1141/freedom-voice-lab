#!/usr/bin/env bash
# Static payload evidence ONLY; this cannot prove execution or audible output.
set -euo pipefail
APP="${1:?path to built .app required}"
BIN="$APP/PocketPal"
BUNDLE="$APP/main.jsbundle"
test -s "$BIN" && test -s "$BUNDLE"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
xcrun nm "$BIN" > "$WORK/symbols"
strings "$BIN" > "$WORK/strings"
for symbol in llama_init_from_model whisper_init_from_file_with_params; do
  grep -q "$symbol" "$WORK/symbols" || { echo "Missing native symbol: $symbol"; exit 1; }
done
grep -Eiq 'onnxruntime|OrtGetApiBase' "$WORK/symbols"
grep -Eiq 'AudioPcmStream|AudioPCMStream' "$WORK/strings"
for marker in Freedom af_heart kokoro; do
  LC_ALL=C grep -aqF "$marker" "$BUNDLE" || { echo "Missing JS marker: $marker"; exit 1; }
done
"$(dirname "$0")/verify-bundle.sh" "$BUNDLE" release
echo "PASS static native symbols and JS markers; execution and model weights NOT verified"
