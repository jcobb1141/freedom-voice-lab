#!/usr/bin/env python3
"""Prepare one licensed human recording; never a microphone or phone test."""
import argparse
import hashlib
import json
import subprocess
import tarfile
from pathlib import Path

URL = "https://openslr.trmal.net/resources/12/test-clean.tar.gz"
ARCHIVE_SHA256 = "39fde525e59672dc6d1551919b1478f724438a95aa55f874b576be21967e6c23"
AUDIO_SHA256 = "8676316e531d8c0e496e3677811ed2bf63e5aaf0a12446cde70416fd490b1792"
UTTERANCE = "61-70968-0002"
TRANSCRIPT = "A GOLDEN FORTUNE AND A HAPPY LIFE"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output")
    parser.add_argument("--archive", type=Path)
    args = parser.parse_args()
    out = Path(args.output)
    out.mkdir(parents=True, exist_ok=True)
    archive = args.archive or out / "test-clean.tar.gz"
    if not args.archive:
        subprocess.run([
            "curl", "--fail", "--location", "--retry", "2", "--max-time", "300",
            URL, "-o", str(archive),
        ], check=True)
    checksum = hashlib.sha256()
    with archive.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            checksum.update(chunk)
    if checksum.hexdigest() != ARCHIVE_SHA256:
        raise SystemExit("Human-speech archive checksum mismatch")
    # Read fixed members, never extract arbitrary paths from an archive.
    with tarfile.open(archive) as corpus:
        audio = corpus.extractfile(
            f"LibriSpeech/test-clean/61/70968/{UTTERANCE}.flac",
        ).read()
        transcript = corpus.extractfile(
            "LibriSpeech/test-clean/61/70968/61-70968.trans.txt",
        ).read().decode()
        license_text = corpus.extractfile("LibriSpeech/LICENSE.TXT").read()
    if hashlib.sha256(audio).hexdigest() != AUDIO_SHA256:
        raise SystemExit("Human-speech utterance checksum mismatch")
    if f"{UTTERANCE} {TRANSCRIPT}" not in transcript.splitlines():
        raise SystemExit("Human-speech reference transcript mismatch")
    (out / "question.flac").write_bytes(audio)
    (out / "SPEECH-LICENSE.txt").write_bytes(license_text)
    metadata = {
        "kind": "human-recorded",
        "dataset": "LibriSpeech test-clean",
        "utteranceId": UTTERANCE,
        "referenceTranscript": TRANSCRIPT,
        "expectedWords": ["golden", "fortune", "happy"],
        "sourceUrl": URL,
        "primarySource": "https://www.openslr.org/12/",
        "license": "CC BY 4.0",
        "licenseUrl": "https://creativecommons.org/licenses/by/4.0/",
        "attribution": "LibriSpeech (c) 2014 by Vassil Panayotov",
        "archiveSha256": ARCHIVE_SHA256,
        "audioSha256": AUDIO_SHA256,
        "changes": "Selected utterance; CI converts FLAC to mono 16 kHz PCM16",
    }
    (out / "fixture.json").write_text(json.dumps(metadata, indent=2) + "\n")
    print(json.dumps(metadata))


if __name__ == "__main__":
    main()
