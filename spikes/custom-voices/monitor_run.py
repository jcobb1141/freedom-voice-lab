#!/usr/bin/env python3
"""Read-only monitor; never dispatches, restarts, cancels or purchases a runner."""
import json
from pathlib import Path
import re
import subprocess
import sys
import time

REPOSITORY = "repos/jcobb1141/freedom-voice-lab"


def api(path):
    return json.loads(subprocess.check_output(["gh", "api", REPOSITORY + path]))


def main():
    run = sys.argv[1]
    if not run.isdecimal():
        raise ValueError("Expected a numeric GitHub run identifier")
    output = Path("generated-artifacts/custom-voice-spike")
    output.mkdir(parents=True, exist_ok=True)
    for _ in range(66):
        result = api(f"/actions/runs/{run}")
        if result["status"] != "completed":
            time.sleep(60)
            continue
        jobs = api(f"/actions/runs/{run}/jobs")
        for name, value in [(f"run-{run}", result), (f"jobs-{run}", jobs)]:
            (output / f"{name}.json").write_text(json.dumps(value, indent=2))
        print("Run", run, result["conclusion"], result["html_url"], flush=True)
        for job in jobs["jobs"]:
            print("Job", job["id"], job["name"], job["conclusion"], flush=True)
            if job["conclusion"] == "skipped":
                continue
            log = subprocess.check_output([
                "gh", "api", "--allow-escape-sequences",
                f"{REPOSITORY}/actions/jobs/{job['id']}/logs",
            ], text=True)
            (output / f"job-{job['id']}.log").write_text(log)
            matches = [line for line in log.splitlines() if re.search(
                r"VOICE_SPIKE_METRIC|error:|Error:|fatal|Traceback|KeyError|ValueError|AssertionError", line)]
            print("\n".join(matches[-30:]), flush=True)
        return
    raise TimeoutError("Remote run still pending; inspect it without restarting")


if __name__ == "__main__":
    main()
