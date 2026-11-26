#!/usr/bin/env bash
# Static iOS JS packaging checks only: not Xcode compilation or engine execution.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HERE/../.."
OUTPUT="${1:-out/hermes}"
mkdir -p "$OUTPUT"
OUTPUT="$(cd "$OUTPUT" && pwd)"
NODE="${NODE_BINARY:-node}"
export NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=3072}"
export NODE_ENV=production PLUS_STORE_GATE=false

if [ -z "${HERMESC:-}" ]; then
  case "$(uname -s)" in
    Linux) PLATFORM=linux64-bin ;;
    Darwin) PLATFORM=osx-bin ;;
    *) echo "Unsupported Hermes host" >&2; exit 2 ;;
  esac
  HERMESC="$PWD/node_modules/hermes-compiler/hermesc/$PLATFORM/hermesc"
fi
test -x "$HERMESC"

# Clear both modes before the first attempt, even if release fails early.
rm -f "$OUTPUT/release/main.jsbundle" "$OUTPUT/release/main.hbc" \
  "$OUTPUT/e2e/main.jsbundle" "$OUTPUT/e2e/main.hbc"
for mode in release e2e; do
  export E2E_BUILD=false
  [ "$mode" != e2e ] || export E2E_BUILD=true
  mkdir -p "$OUTPUT/$mode"
  # One worker runs transforms in Metro's parent process. Two isolates them.
  # Reset between modes: environment-only Babel flags must not reuse cached code.
  "$NODE" node_modules/react-native/cli.js bundle \
    --platform ios --dev false --minify false --reset-cache \
    --entry-file index.js --max-workers 2 \
    --bundle-output "$OUTPUT/$mode/main.jsbundle" \
    --assets-dest "$OUTPUT/$mode/assets"
  "$HERMESC" -O -emit-binary -out "$OUTPUT/$mode/main.hbc" \
    "$OUTPUT/$mode/main.jsbundle"
  bash "$HERE/verify-bundle.sh" "$OUTPUT/$mode/main.hbc" "$mode"
done
