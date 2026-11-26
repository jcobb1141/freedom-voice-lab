# Inactive upstream CI fixtures

Preparation copies these three text fixtures byte-for-byte from the pinned
PocketPal snapshot before removing upstream `.github`:

- `.github/workflows/ci.yml` → `ci.yml.txt`
- `.github/workflows/release.yml` → `release.yml.txt`
- `.github/actions/setup-hexagon-sdk/action.yml` → `setup-hexagon-sdk.action.yml.txt`

They retain upstream MIT source attribution in the repository `LICENSE`.
They are data for the original regression assertions, not runnable lab workflows.
Do not move them into `.github` or invoke the Android provisioning action.
The lab's actual workflow policy has its own `freedom-workflow.test.js` tests.
