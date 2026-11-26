#!/usr/bin/env bash
# Synthetic public CI config only. Never copy workspace config into the fork.
set -euo pipefail
python3 - "${1:?bundle ID required}" <<'PY'
import plistlib, re, sys
from pathlib import Path
bundle = sys.argv[1]
if not re.fullmatch(r"[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+", bundle):
    raise SystemExit("Invalid bundle ID")
# Validate generated paths against the actual project before costly pod/build work.
project_path = Path("ios/PocketPal.xcodeproj/project.pbxproj")
if not project_path.is_file():
    raise SystemExit("Xcode project missing; run from a prepared PocketPal fork")
project = project_path.read_text()
main = re.search(r"mainGroup = ([A-F0-9]+);", project)
group = re.search(rf"\b{main[1]}\b[^=\n]*=\s*\{{(.*?)\}};", project, re.S) if main else None
if not group:
    raise SystemExit("Cannot resolve Xcode main group")
for name, expected in (
    ("GoogleService-Info.plist", "GoogleService-Info.plist"),
    ("Env.xcconfig", "Config/Env.xcconfig"),
):
    ref = re.search(
        rf"\b([A-F0-9]+) /\* {re.escape(name)} \*/ = \{{(isa = PBXFileReference;.*?)\}};",
        project, re.S,
    )
    path = re.search(r'\bpath = (?:"([^"]+)"|([^;\s]+));', ref[2]) if ref else None
    actual = (path[1] or path[2]) if path else None
    if not ref or ref[1] not in group[1] or actual != expected or 'sourceTree = "<group>";' not in ref[2]:
        raise SystemExit(f"Unexpected Xcode config path: {name}")
config = {
    "API_KEY": "placeholder-not-a-real-api-key",
    "GOOGLE_APP_ID": "1:000000000000:ios:0000000000000000000000",
    "GCM_SENDER_ID": "000000000000",
    "PROJECT_ID": "freedom-local-placeholder",
    "BUNDLE_ID": bundle,
    "IS_ANALYTICS_ENABLED": False, "IS_ADS_ENABLED": False,
    "IS_SIGNIN_ENABLED": False, "IS_GCM_ENABLED": False,
}
Path("ios/GoogleService-Info.plist").write_bytes(plistlib.dumps(config))
Path(".env").write_text(
    "ENABLE_PALSHUB_INTEGRATION=false\nENABLE_AUTHENTICATION=false\n"
    "ENABLE_OFFLINE_MODE=true\nAPP_URL=pocketpal://app\n"
    "FIREBASE_FUNCTIONS_URL=https://invalid.invalid\nPALSHUB_API_BASE_URL=https://invalid.invalid\n"
)
# The project-level base configuration is deliberately gitignored upstream.
# Generate only synthetic values; never copy a developer's local config.
Path("ios/Config").mkdir(parents=True, exist_ok=True)
Path("ios/Config/Env.xcconfig").write_text(
    "// Synthetic Freedom CI config; cloud authentication is disabled.\n"
    "GOOGLE_WEB_CLIENT_ID = freedom-placeholder.apps.invalid\n"
    "REVERSED_GOOGLE_IOS_CLIENT_ID = com.freedom.invalid.google\n"
)
PY
