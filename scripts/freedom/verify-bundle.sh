#!/usr/bin/env bash
# Works on Metro JS and Hermes bytecode. Does not execute the application.
set -euo pipefail
BUNDLE="${1:?bundle required}"
MODE="${2:?release or e2e required}"
test -s "$BUNDLE"
MARKERS='FREEDOM_NATIVE_PIPELINE_V1|AUTOMATION_BRIDGE|BENCH_RUN_MATRIX|IAP_FAKE_STORE|memory-snapshot-label|bench-runner-screen-status|IAP_API_BASE_OVERRIDE|PLUS_SHIP_OVERRIDE|PLUS_GATE_PROBE'
case "$MODE" in
  release)
    if LC_ALL=C grep -aqE "$MARKERS" "$BUNDLE"; then
      echo "FAIL: automation found in release bundle"; exit 1
    fi
    ;;
  e2e)
    LC_ALL=C grep -aqF 'FREEDOM_NATIVE_PIPELINE_V1' "$BUNDLE" || {
      echo "FAIL: native smoke marker absent from E2E bundle"; exit 1
    }
    ;;
  *) echo "Unknown mode: $MODE"; exit 2 ;;
esac
echo "PASS $MODE automation marker contract (static bundle only)"
