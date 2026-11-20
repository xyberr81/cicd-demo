# CI/CD Demo

A small Flutter app for the mobile CI/CD seminar. It is built and signed by
GitHub Actions, published as a GitHub Release, and updates itself from that
release, with no Play Store involved.

## Pipeline

`.github/workflows/pipeline.yml`

| Trigger | Jobs |
|---|---|
| Pull request, push to `main` | `check`: format, analyze, test |
| Tag `vX.Y.Z` | `check` → `build` (signed arm64 APK) → `release` (GitHub Release) |

- The version name comes from the tag (`v1.2.0` → `1.2.0`). The build number is
  the Actions run number, so it always goes up.
- CI passes the repo name into the app with `--dart-define=GITHUB_REPO`. Local
  builds don't set it, so they never check for updates.
- On launch the app calls `GET /repos/{repo}/releases/latest`. If that tag is
  newer, it offers to download the APK and hands it to Android's installer.

## One-time setup

```bash
# Public repo, so Actions minutes are free
gh repo create cicd-demo --public --source . --push

# Create the release key and store it in Actions secrets
tool/make-keystore.sh
```

Back up `secrets/upload.jks`. Android only installs an update when it is signed
with the same key as the installed app.

## Demo runbook

**Day before**
1. Push `v1.0.0` and let the pipeline finish. This also warms the caches.
2. Install that APK on the phone (from the release page), and allow
   "install unknown apps" for the browser and for this app.
3. Change `headline` in `lib/main.dart` and commit it, but don't tag yet.
4. Optional: open a PR that breaks a test in `test/update_test.dart` to show a
   red check.

**During the talk**
1. Hook: `git tag v1.1.0 && git push origin v1.1.0`. The pipeline starts.
2. At the "check" slides, show the `check` job (about 1 min).
3. At "build" and "sign", show the `build` job's log: the key restored from
   secrets, then the version flags.
4. At "distribute", show the GitHub Release with the APK.
5. Open the app on the phone. "Update v1.1.0 available", tap Update, install,
   and the new headline shows.

**Fallback:** keep a finished run open in another tab and have a screen
recording ready.

## Local checks

```bash
tool/check.sh
```
