# Freedom native voice lab

This is a sanitized PocketPal source snapshot with a small MIT lab-character
patch and E2E-only component smoke. Keep `LICENSE` and `NOTICE-FREEDOM.md`.
The snapshot pin is in `UPSTREAM-FREEDOM.md`. This is not an official release.

Only **Freedom iOS** runs on pushes to `main`; it uses standard public-repository
Linux/macOS runners. Do not enable paid/larger runners or unrelated upstream CI.
**Freedom TestFlight** is manual, dormant without Apple configuration, and
requires explicit upload confirmation. No workflow file certifies a passed build.

The free verification workflow does not upload artifacts or save caches: public
standard-runner compute is free, but artifact storage can be metered separately.
Build hashes and smoke JSON are recorded in the workflow logs/summary. Build
binaries remain temporary until free storage or another retention method is
explicitly approved. This does not modify any account billing settings.

The simulator smoke uses Qwen3.5 2B Q4_K_M with a 2,048-token context on CPU,
Whisper base and Kokoro `af_heart`. It reads licensed human LibriSpeech speech from a
PCM fixture. It is **not** a microphone, real hands-free loop, streaming-audio,
speaker-quality, phone-memory or physical-device performance test. Models are
downloaded, not committed. Check each workflow's actual run and artifacts.

For physical testing, start with the 2B configuration, not an assumed 4B fit.
Both speech engines remain resident in the real call implementation. Measure
memory headroom/peak footprint on device, ten exchanges and a 30-minute offline
session, interruption, mute, teardown and automatic return to listening.
An unsigned `.app` cannot be installed as a normal signed iPhone app.

Read-only Apple preflight confirms matching app/bundle records only. API access
does not prove signing certificates, capabilities or provisioning. The owner's
bundle ID must replace the upstream identity including its keychain group.
Never commit Apple keys or service credentials.

## Recorded free verification — 26 November 2026

- [Unsigned iPhone build and payload checks passed](https://github.com/jcobb1141/freedom-voice-lab/actions/runs/45753789900)
  at source `c1363de570ca8a3e097fcf11b9dee78d0d5a8828`.
- [Simulator build, actual native component flow and four Swift tests passed](https://github.com/jcobb1141/freedom-voice-lab/actions/runs/45761664682)
  at source `1cb33a4ad3a32738b74ecade8261a0e4e41ad212`.
  Whisper returned “A golden fortune and a happy life.” The local model
  generated a response with Freedom's prompt; Kokoro emitted one native
  playback-start and one playback-finish event. Adapter elapsed time was
  96.565 seconds, including speech-asset downloads, on the simulator host.
- The latter run also passed 463 automated suites, 9,920 tests, two skipped,
  310 snapshots and both real release/E2E Hermes marker checks.

The original voice check timed out without usable engine/startup diagnostics.
The successful retry used a build-gated local request handshake, startup and
per-engine receipts, and failure diagnostics instead of a fixed-delay deep link.
These results do not prove microphone capture, the real hands-free controller,
streaming overlap, physical audibility, phone memory/latency or offline
long-session behavior. No signed installation or TestFlight upload occurred.
