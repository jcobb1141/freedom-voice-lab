#!/usr/bin/env python3
"""Fail closed on known private paths; produce exact staged-tree inventory.

This is a mechanical guard, not a substitute for inspecting the diff and
manifest. Run from the clean fork, never from the Companion workspace.
"""
import hashlib
import json
import re
import subprocess
from pathlib import Path

PIN = "5a27b5f97d3d6b999083ade4a58caad45658f4dc"
paths = subprocess.check_output(["git", "ls-files", "-z"]).decode().split("\0")
paths = [p for p in paths if p]
blocked = []
manifest = []
for name in paths:
    path = Path(name)
    if (
        name.startswith(("artifacts/", "attached_assets/", ".agents/", ".local/", "research/"))
        or any(p.lower() in {"companion", "conference-lab", "credentials", "secrets"} for p in path.parts)
        or path.name in {"AGENTS.md", "CLAUDE.md", "profile.md", "MEMORY.md", ".env"}
        or path.suffix.lower() in {".p8", ".p12", ".pem", ".mobileprovision", ".key"}
        or (path.name.startswith(".env.") and path.name != ".env.example")
        or (name.startswith(".github/") and name not in {
            ".github/workflows/freedom-ios.yml", ".github/workflows/freedom-testflight.yml"
        })
    ):
        blocked.append(name)
    data = subprocess.check_output(["git", "show", f":{name}"])
    if re.search(rb"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}", data):
        blocked.append(name + " (credential pattern)")
    if path.is_symlink():
        blocked.append(name + " (symlink requires manual review)")
    manifest.append(f"{hashlib.sha256(data).hexdigest()}  {name}")
Path("export-manifest.sha256").write_text("\n".join(manifest) + "\n")
summary = {
    "upstream": PIN, "tracked_files": len(paths), "blocked": blocked,
    "scope": "PocketPal source snapshot plus Freedom overlay, not workspace history",
    "manual_review_required": True,
    "warning": "Pattern checks cannot certify absence of all personal information.",
}
Path("export-review.json").write_text(json.dumps(summary, indent=2) + "\n")
print(json.dumps(summary, indent=2))
raise SystemExit(1 if blocked else 0)
