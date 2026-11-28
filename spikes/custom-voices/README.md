# Isolated native custom-voice experiment

This is the executable follow-on to the existing voice/group research, not a
replacement app or a second feasibility survey. No existing Companion, lab or
catalog-voice source is changed. The exact source and model revisions are in
`pins.json`. No engine is approved for production solely because this harness
compiles or emits a nonempty waveform.

## What the Qwen harness does

1. Uses the genuine **1.7B VoiceDesign bf16** model to create a deliberately
   synthetic reference. It does not use a named CustomVoice speaker.
2. Exits that process before loading genuine **0.6B Base bf16**. This avoids
   intentionally keeping both large models in the host's limited RAM.
3. Prepares native speaker/code/text conditioning, saves an engine-bound named
   profile, and deletes the reference WAV.
4. Reopens that conditioning and synthesizes two different sentences without
   re-encoding the reference audio.
5. Exits, reloads the Base model in another process, and synthesizes again from
   the saved conditioning.
6. Exercises cancellation by owning the direct native generation task, cancelling
   it and awaiting that producer's completion. A cancellation acknowledgment and
   completion within one second are required. Cancelling an async-stream
   **consumer** alone is not sufficient evidence: the SDK's stream API does not
   expose its producer-task join. Physical playback flush is a separate test.

The newer pinned MLXAudio SDK exposes reusable conditioning and cooperative
cancellation checks. The separately pinned standalone Swift Qwen port has a
different public surface: it exposes an embedding extractor and reference-audio
clone generation, but no public reusable-conditioning generation API; its
detached streaming worker has no corresponding termination/cancellation hook.
Do not assume those ports have equivalent capabilities.

## Privacy and boundaries

- CI has no microphone, owner recording, upload input, account secret, or human
  voice fixture. Only this run's synthetic reference is used.
- Model downloads are anonymous, revision-pinned and checksum-verified.
  Pickle, remote code, executable model files and entire repository snapshots
  are not accepted.
- The model repositories are several GB; downloads follow a successful native
  compile. No model, WAV or conditioning artifact is uploaded or cached.
- Source is published only on the isolated `verification/custom-voice-spike`
  branch of the existing public lab repository. Existing main and lab source
  are preserved.
- Saved JSON conditioning is sensitive. This experimental private-directory /
  file-permission store is **not** the final encrypted iOS owner vault, an import
  security boundary, or a production consent system.
- Nonempty, finite waveform checks are not an audible similarity/quality rating.
  Host RAM, timings and cancellation measurements are not iPhone measurements.
- Physical-device microphone, audio routes, speaker/echo behavior, signing and
  signed installation remain separate acceptance requirements.

## Pocket 100M Core ML path

The exact full Pocket engine exposes `cloneVoice`, `saveClonedVoice`,
`loadClonedVoice`, custom-conditioning synthesis/streaming, and a session
`cancel()` that awaits its generation task. This is **not** the smaller
Pocket catalog-only path.

The original cloning model is gated. No recorded owner acceptance of its terms
is assumed, and this experiment never accepts them. The public converted
Core ML repository is pinned for comparison, but it is not downloaded as a
way around that gate. Its very large full repository also must not be
snapshotted. Consequently native Pocket clone/reopen/cancellation execution
remains **unverified**, not failed and not implicitly approved.

## Reproduction

Requires an Apple Silicon Mac with compatible Swift 6.3, Metal and enough free
disk/RAM. The Linux workspace can run only the clearly labeled downloader-policy
tests:

```sh
python3 -m unittest discover -s native/custom-voice-spike -p 'test_*.py' -v
```

On an authorized Mac, from this workspace root:

```sh
umask 077
work="$PWD/generated-artifacts/custom-voice-spike-local"
mkdir -p "$work"
swiftc native/custom-voice-spike/HostProbe.swift -o "$work/host-probe"
"$work/host-probe" "$work/host.json"
(cd native/custom-voice-spike/qwen && \
  xcodebuild -scheme VoiceRuntime -configuration Release \
    -destination 'platform=macOS,arch=arm64' -jobs 2 \
    -derivedDataPath "$work/derived" \
    -onlyUsePackageVersionsFromResolvedFile build CODE_SIGNING_ALLOWED=NO)
bin="$work/derived/Build/Products/Release/VoiceRuntime"
"$bin" metal-smoke
python3 native/custom-voice-spike/download_models.py qwenVoiceDesign "$work/design"
python3 native/custom-voice-spike/download_models.py qwenBase "$work/base"
"$bin" design "$work/design" "$work/private"
"$bin" clone "$work/base" "$work/private"
"$bin" reopen "$work/base" "$work/private"
```

Use a fresh private output directory. Do not substitute human audio for the
generated reference or publish that directory. Delete transient synthetic
conditioning after inspection. Do not rerun already successful steps merely
to refresh a report.

The included workflow uses only standard `macos-26` runners in the existing
public repository, no larger-runner labels, paid API, billing change, persistent
artifact upload or Actions cache. It is an isolated verification workflow,
not an app deployment.

Use Xcode for this build: `swift build` can compile the Swift/C++ code but does
not build MLX's Metal shaders. That is insufficient for native execution.
