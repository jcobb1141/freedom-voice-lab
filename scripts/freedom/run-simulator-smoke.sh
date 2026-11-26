#!/usr/bin/env bash
# Requires the workflow's booted simulator, built E2E app, model and PCM.
# Does not drive the real hands-free hook, microphone or audio hardware.
set -euo pipefail
: "${E2E_DEVICE_UDID:?}" "${E2E_APP_PATH:?}" "${FREEDOM_MODEL_PATH:?}" "${FREEDOM_INPUT_PCM:?}"
: "${FREEDOM_INPUT_METADATA:?}"
"$(dirname "$0")/verify-bundle.sh" "$E2E_APP_PATH/main.jsbundle" e2e
xcrun simctl install "$E2E_DEVICE_UDID" "$E2E_APP_PATH"
CONTAINER="$(xcrun simctl get_app_container "$E2E_DEVICE_UDID" ai.pocketpal data)"
mkdir -p "$CONTAINER/Documents" out
collect_failure() {
  rc=$?
  if [ "$rc" -ne 0 ]; then
    python3 "$(dirname "$0")/collect-simulator-diagnostics.py" \
      "$E2E_DEVICE_UDID" "$CONTAINER/Documents/freedom-result.json" || true
  fi
  exit "$rc"
}
trap collect_failure EXIT
cp "$FREEDOM_MODEL_PATH" "$CONTAINER/Documents/freedom-model.gguf"
cp "$FREEDOM_INPUT_PCM" "$CONTAINER/Documents/freedom-question.pcm"
cp "$FREEDOM_INPUT_METADATA" "$CONTAINER/Documents/freedom-fixture.json"
rm -f "$CONTAINER/Documents/freedom-result.json"
printf '%s\n' '{"marker":"FREEDOM_NATIVE_REQUEST_V1"}' > "$CONTAINER/Documents/freedom-request.json"
xcrun simctl launch "$E2E_DEVICE_UDID" ai.pocketpal
python3 - "$CONTAINER/Documents/freedom-result.json" <<'PY'
import json, pathlib, sys, time
p = pathlib.Path(sys.argv[1])
deadline = time.monotonic() + 1200
startup_deadline = time.monotonic() + 120
last_stage = None
seen_startup = False
while time.monotonic() < deadline:
    try:
        data = json.loads(p.read_text())
    except (OSError, ValueError):
        if not seen_startup and time.monotonic() >= startup_deadline:
            raise SystemExit("No E2E startup receipt within 120 seconds; inspect app crash and initialization logs")
        time.sleep(2)
        continue
    seen_startup = True
    stage = (data.get("state"), data.get("stage"))
    if stage != last_stage:
        print(json.dumps(data), flush=True)
        last_stage = stage
    if data.get("state") in {"error", "done"}:
        pathlib.Path("out/freedom-result.json").write_text(json.dumps(data, indent=2))
        print(json.dumps(data, indent=2))
        if data["state"] != "done":
            raise SystemExit(1)
        break
    time.sleep(2)
else:
    raise SystemExit("No completed native smoke result within 20 minutes")
PY
