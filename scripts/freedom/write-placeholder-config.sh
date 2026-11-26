#!/usr/bin/env bash
# Synthetic public CI config only. Never copy workspace config into the fork.
set -euo pipefail
python3 - "${1:?bundle ID required}" <<'PY'
import plistlib, re, sys
from pathlib import Path
bundle = sys.argv[1]
if not re.fullmatch(r"[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+", bundle):
    raise SystemExit("Invalid bundle ID")
config = {
    "API_KEY": "placeholder-not-a-real-api-key",
    "GOOGLE_APP_ID": "1:000000000000:ios:0000000000000000000000",
    "GCM_SENDER_ID": "000000000000",
    "PROJECT_ID": "freedom-local-placeholder",
    "BUNDLE_ID": bundle,
    "IS_ANALYTICS_ENABLED": False, "IS_ADS_ENABLED": False,
    "IS_SIGNIN_ENABLED": False, "IS_GCM_ENABLED": False,
}
Path("ios/PocketPal/GoogleService-Info.plist").write_bytes(plistlib.dumps(config))
Path(".env").write_text(
    "ENABLE_PALSHUB_INTEGRATION=false\nENABLE_AUTHENTICATION=false\n"
    "ENABLE_OFFLINE_MODE=true\nAPP_URL=pocketpal://app\n"
    "FIREBASE_FUNCTIONS_URL=https://invalid.invalid\nPALSHUB_API_BASE_URL=https://invalid.invalid\n"
)
PY
