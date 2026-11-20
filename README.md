# CI/CD Demo

A small Flutter app for the mobile CI/CD seminar. It is built and signed by
GitHub Actions, published as a GitHub Release, and updates itself from that
release, with no Play Store involved.

## Pipeline

`.github/workflows/pipeline.yml`

| Trigger | Jobs |
|---|---|
| Pull request | `check`: format, analyze, test |
| Push to `main` | `check` → `build` (fills the Gradle cache, no release) |
| Tag `vX.Y.Z` | `check` → `build` (signed arm64 APK) → `release` (GitHub Release) |

- The version name comes from the tag (`v1.2.0` → `1.2.0`). The build number is
  the Actions run number, so it always goes up.
- CI passes the repo name into the app with `--dart-define=GITHUB_REPO`. Local
  builds don't set it, so they never check for updates.
- On launch, on every return to the app, and from the "Check for updates"
  button, the app calls `GET /repos/{repo}/releases/latest`. If that tag is
  newer, it offers to download the APK and hands it to Android's installer.
  Failures (offline, rate limit, no APK) show on screen instead of doing nothing.
- The release notes in the update dialog are the tagged commit's subject line.
- Self-updating like this is only allowed outside Google Play. Play's policy
  forbids apps on Play from updating themselves.

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
1. Push to `main` once so the Gradle cache exists (a tag run can only restore
   caches saved on the default branch). Then push `v1.0.0` and let it finish.
2. Install that APK on the phone (from the release page), and allow
   "install unknown apps" for the browser and for this app.
3. Change `headline` in `lib/main.dart` and commit it with a short message
   (it becomes the release notes), push to `main`, but don't tag yet.
4. Optional: open a PR that breaks a test in `test/update_test.dart` to show a
   red check.

**Phone, right before the talk**
- Mobile data, not campus Wi-Fi. GitHub allows 60 unauthenticated API
  requests per hour per IP, and a shared network can use them up.
- Force-stop the app so it starts fresh. If Play Protect asks about the
  install during the dry run, note what it shows.

**During the talk**
1. Hook: `git tag v1.1.0 && git push origin v1.1.0`. The pipeline starts.
2. At the "check" slides, show the `check` job (about 1 min).
3. At "build" and "sign", show the `build` job's log: the key restored from
   secrets, then the version flags.
4. At "distribute", show the GitHub Release with the APK.
5. Open the app on the phone. "Update v1.1.0 available", tap Update, install,
   and the new headline shows. If no dialog appears, the status line says
   why; tap "Check for updates" to retry.

**Fallback:** keep a finished run open in another tab and have a screen
recording ready.

## Local checks

```bash
tool/check.sh
```
