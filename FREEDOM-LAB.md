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
Whisper base and Kokoro `af_heart`. It reads synthesized recorded speech from a
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
