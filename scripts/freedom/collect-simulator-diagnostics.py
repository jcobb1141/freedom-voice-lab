#!/usr/bin/env python3
"""Retain test-runner diagnostics locally/in CI logs, not paid artifact storage."""
import json
from pathlib import Path
import subprocess
import sys

udid, result_path = sys.argv[1:]
out = Path("out")
out.mkdir(exist_ok=True)
result = Path(result_path)
if result.exists():
    text = result.read_text(errors="replace")
    (out / "freedom-result.json").write_text(text)
    print("LAST NATIVE STATUS:", text, flush=True)
else:
    print("No native status file was created.", flush=True)

command = [
    "xcrun", "simctl", "spawn", udid, "log", "show", "--style", "compact",
    "--last", "25m", "--predicate", 'process == "PocketPal"',
]
try:
    p = subprocess.run(command, capture_output=True, text=True, timeout=35)
    text = p.stdout + p.stderr
    (out / "freedom-simulator-system.log").write_text(text)
    print("APP SYSTEM LOG (last 300 lines):")
    print("\n".join(text.splitlines()[-300:]), flush=True)
except subprocess.TimeoutExpired:
    print("App system-log collection exceeded 35 seconds.", flush=True)

# Fresh hosted runner only; do not collect unrelated application reports.
reports = Path.home() / "Library/Logs/DiagnosticReports"
paths = sorted(reports.glob("PocketPal*.ips"),
               key=lambda p: p.stat().st_mtime, reverse=True)
for index, path in enumerate(paths[:2]):
    text = path.read_text(errors="replace")
    (out / f"freedom-crash-{index}.ips").write_text(text)
    print("POCKETPAL CRASH REPORT:", path.name)
    print(text[-100000:], flush=True)
