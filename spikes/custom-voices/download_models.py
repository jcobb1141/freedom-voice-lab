#!/usr/bin/env python3
"""Pinned, anonymous, ungated Qwen assets only; never accepts model terms."""
import hashlib
import json
from pathlib import Path, PurePosixPath
import sys
import urllib.request


def get_json(url):
    with urllib.request.urlopen(url, timeout=60) as response:
        return json.load(response)


def selected_files(metadata):
    selected = []
    for entry in metadata["siblings"]:
        name = entry["rfilename"]
        path = PurePosixPath(name)
        if path.is_absolute() or ".." in path.parts or "\\" in name:
            raise ValueError("Unsafe upstream asset path")
        if (
            path.suffix in {".json", ".safetensors", ".model"}
            or name in {"merges.txt", "LICENSE", "LICENSE.txt"}
        ):
            selected.append(entry)
    total = sum(entry["size"] for entry in selected)
    if not selected or not 0 < total < 5_000_000_000:
        raise ValueError("Unexpected model download size")
    return selected


def download(kind, destination, pins):
    if kind not in {"qwenVoiceDesign", "qwenBase"}:
        raise ValueError("Only the ungated genuine Qwen design/Base paths are allowed")
    pin = pins["models"][kind]
    repository, revision = pin["repository"], pin["revision"]
    metadata = get_json(f"https://huggingface.co/api/models/{repository}/revision/{revision}?blobs=true")
    if metadata["sha"] != revision or metadata.get("gated") is not False:
        raise ValueError("Revision mismatch or gated model; no credentials or terms acceptance allowed")
    entries = selected_files(metadata)
    primary = next(entry for entry in entries if entry["rfilename"] == pin["file"])
    if primary.get("lfs", {}).get("sha256") != pin["sha256"] or primary["size"] != pin["bytes"]:
        raise ValueError("Primary weight pin mismatch")
    codec = next(entry for entry in entries if entry["rfilename"] == "speech_tokenizer/model.safetensors")
    if codec.get("lfs", {}).get("sha256") != pins["models"]["qwenCodec"]["sha256"]:
        raise ValueError("Codec weight mismatch")
    destination = Path(destination)
    destination.mkdir(parents=True, mode=0o700)
    records = []
    for entry in entries:
        name, size = entry["rfilename"], entry["size"]
        target = destination / name
        target.parent.mkdir(parents=True, exist_ok=True)
        sha256 = hashlib.sha256()
        git_hash = hashlib.sha1(b"blob " + str(size).encode() + b"\0")
        count = 0
        partial = target.with_name(target.name + ".partial")
        url = f"https://huggingface.co/{repository}/resolve/{revision}/{name}"
        try:
            with urllib.request.urlopen(url, timeout=120) as response, partial.open("xb") as output:
                while chunk := response.read(1024 * 1024):
                    count += len(chunk)
                    if count > size:
                        raise ValueError("Asset exceeded declared size")
                    output.write(chunk)
                    sha256.update(chunk)
                    git_hash.update(chunk)
            expected_sha = entry.get("lfs", {}).get("sha256")
            if count != size or (
                expected_sha and sha256.hexdigest() != expected_sha
            ) or (not expected_sha and git_hash.hexdigest() != entry["blobId"]):
                raise ValueError(f"Asset checksum mismatch: {name}")
            partial.chmod(0o600)
            partial.replace(target)
        finally:
            partial.unlink(missing_ok=True)
        records.append({"path": name, "bytes": count, "sha256": sha256.hexdigest()})
    config = json.loads((destination / "config.json").read_text())
    expected_variant = "voice_design" if kind == "qwenVoiceDesign" else "base"
    if config.get("tts_model_type") != expected_variant:
        raise ValueError("Wrong Qwen variant; CustomVoice is not a creation substitute")
    lock = {"repository": repository, "revision": revision, "assets": records}
    (destination / "spike-asset-lock.json").write_text(json.dumps(lock, indent=2))
    print(json.dumps({"kind": kind, "revision": revision, "bytes": sum(e["bytes"] for e in records),
                      "filesVerified": len(records), "gatedTermsAccepted": False}), flush=True)


if __name__ == "__main__":
    pin_path = Path(__file__).with_name("pins.json")
    download(sys.argv[1], sys.argv[2], json.loads(pin_path.read_text()))
