#!/usr/bin/env python3
"""Update all upstream identity references, including keychain access group."""
import os
import re
from pathlib import Path

bundle, team = os.environ["BUNDLE_ID"], os.environ["TEAM_ID"]
if not re.fullmatch(r"[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+", bundle):
    raise SystemExit("Invalid BUNDLE_ID")
if not re.fullmatch(r"[A-Z0-9]{10}", team):
    raise SystemExit("Invalid TEAM_ID")
pbx = Path("ios/PocketPal.xcodeproj/project.pbxproj")
text = pbx.read_text()
if "PRODUCT_BUNDLE_IDENTIFIER = ai.pocketpal;" not in text:
    raise SystemExit("Unexpected upstream project identity; inspect before signing")
text = text.replace("ai.pocketpal", bundle).replace("ai.PocketPalTests", bundle + ".tests")
text = text.replace("MYXGXY23Y6", team)
pbx.write_text(text)
entitlements = Path("ios/PocketPal/PocketPal.entitlements")
entitlements.write_text(entitlements.read_text().replace("ai.pocketpal", bundle))
print("Identity updated; Apple capability/profile acceptance still requires a signed archive.")
