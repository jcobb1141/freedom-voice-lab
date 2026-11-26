#!/usr/bin/env bash
# Requires the workflow's booted simulator, built E2E app, model and PCM.
# Does not drive the real hands-free hook, microphone or audio hardware.
set -euo pipefail
: "${E2E_DEVICE_UDID:?}" "${E2E_APP_PATH:?}" "${FREEDOM_MODEL_PATH:?}" "${FREEDOM_INPUT_PCM:?}"
: "${FREEDOM_INPUT_METADATA:?}"
xcrun simctl install "$E2E_DEVICE_UDID" "$E2E_APP_PATH"
CONTAINER="$(xcrun simctl get_app_container "$E2E_DEVICE_UDID" ai.pocketpal data)"
mkdir -p "$CONTAINER/Documents" out
cp "$FREEDOM_MODEL_PATH" "$CONTAINER/Documents/freedom-model.gguf"
cp "$FREEDOM_INPUT_PCM" "$CONTAINER/Documents/freedom-question.pcm"
cp "$FREEDOM_INPUT_METADATA" "$CONTAINER/Documents/freedom-fixture.json"
rm -f "$CONTAINER/Documents/freedom-result.json"
xcrun simctl launch "$E2E_DEVICE_UDID" ai.pocketpal
sleep 20
xcrun simctl openurl "$E2E_DEVICE_UDID" 'pocketpal://freedom-smoke'
python3 - "$CONTAINER/Documents/freedom-result.json" <<'PY'
import json, pathlib, sys, time
p = pathlib.Path(sys.argv[1])
deadline = time.monotonic() + 1200
while time.monotonic() < deadline:
    try:
        data = json.loads(p.read_text())
    except (OSError, ValueError):
        time.sleep(2)
        continue
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
