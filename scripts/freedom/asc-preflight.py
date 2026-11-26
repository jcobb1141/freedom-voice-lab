#!/usr/bin/env python3
"""Read-only account preflight. Never prints the key, JWT or account responses."""
import json
import os
import time
import urllib.parse
import urllib.request
import jwt

def main():
    now = int(time.time())
    token = jwt.encode(
        {"iss": os.environ["ASC_ISSUER_ID"], "iat": now, "exp": now + 300, "aud": "appstoreconnect-v1"},
        os.environ["ASC_KEY_P8"], algorithm="ES256",
        headers={"kid": os.environ["ASC_KEY_ID"], "typ": "JWT"},
    )
    for resource, field in (("bundleIds", "identifier"), ("apps", "bundleId")):
        query = urllib.parse.urlencode({f"filter[{field}]": os.environ["BUNDLE_ID"], "limit": 2})
        req = urllib.request.Request(
            f"https://api.appstoreconnect.apple.com/v1/{resource}?{query}",
            headers={"Authorization": f"Bearer {token}"},
        )
        with urllib.request.urlopen(req, timeout=30) as response:
            data = json.load(response)
        if len(data.get("data", [])) != 1:
            raise SystemExit(f"Expected exactly one matching {resource} record; configure Apple account first")
    print("Read-only app/bundle access passed; certificate, capabilities and provisioning are NOT proven.")

if __name__ == "__main__":
    main()
