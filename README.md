# CI/CD Demo

A small Flutter app for the mobile CI/CD seminar. GitHub Actions builds and
signs it and publishes it as a GitHub Release, and the app updates itself from
that release, with no Play Store involved. Dart-only fixes then reach the
installed app over the air as Shorebird patches, with no new APK.

## Pipeline

`.github/workflows/pipeline.yml`

| Trigger | Jobs |
|---|---|
| Pull request | `check`: format, analyze, test |
| Push to `main` | `check` → `build` (fills the Gradle cache, no release) |
| Tag `vX.Y.Z` | `check` → `build` (Shorebird release, signed APK for arm64 phones and x86_64 emulators) → `release` (GitHub Release) |
| Tag `vX.Y.Z-patch.N` | `check` → `patch` (Shorebird patch for release `vX.Y.Z`) |

- The version name comes from the tag (`v1.2.0` → `1.2.0`). The build number is
  the Actions run number, so it always goes up.
- CI passes the repo name into the app with `--dart-define=GITHUB_REPO`. Local
  builds don't set it, so they never check for updates.
- CI also passes `APP_ENV` (`production` for tags, `staging` for `main`) and
  `COMMIT_SHA`. The app shows both under the version, plus the Shorebird patch
  number once a patch runs, so you can match the installed build to its commit.
- On launch, on every return to the app, and from the "Check for updates"
  button, the app calls `GET /repos/{repo}/releases/latest`. If that tag is
  newer, it offers to download the APK and hands it to Android's installer.
  Failures (offline, rate limit, no APK) show on screen instead of doing nothing.
- At the same moments it asks Shorebird for a newer patch and downloads it. A
  patch runs from the next app start, so the screen says "Patch N downloaded.
  Close and reopen the app."
- A patch job finds its release by tag: `v1.1.0-patch.1` patches the Shorebird
  release `1.1.0+<run number of the v1.1.0 run>`. Patches can only change Dart
  code. Shorebird refuses a patch with native changes.
- The release notes in the update dialog are the tagged commit's subject line.
- Self-updating like this is only allowed outside Google Play. Play's policy
  forbids apps on Play from updating themselves. Shorebird patches are allowed
  on Play, because they only change Dart code.

## One-time setup

```bash
# Public repo, so Actions minutes are free
gh repo create cicd-demo --public --source . --push

# Create the release key and store it in Actions secrets
tool/make-keystore.sh

# Shorebird: log in, register the app (writes shorebird.yaml), and give CI a key
shorebird login
shorebird init
shorebird tokens create        # opens the console; copy the API key
gh secret set SHOREBIRD_TOKEN  # paste it
```

Back up `secrets/upload.jks`. Android only installs an update when it is signed
with the same key as the installed app. `shorebird.yaml` sets
`auto_update: false`, because the app downloads patches itself so it can show
their progress.

## Demo runbook

The talk runs two arcs. The `v1.1.0` tag starts at the pipeline slide and lands
on the phone just before the OTA section. That build has a bug: the version
line shows the build number where the version should be. The OTA demo then
fixes it with a patch.

**Day before**
1. Push to `main` once so the Gradle cache exists (a tag run can only restore
   caches saved on the default branch). Then push `v1.0.0` and let it finish.
2. Install that APK on the phone (from the release page), and allow
   "install unknown apps" for the browser and for this app.
3. Make the `v1.1.0` commit: change `headline` in `lib/main.dart`, and swap the
   two fields in the version line so it has the bug:

   ```dart
   _version = '${info.buildNumber} (build ${info.version})';
   ```

   Commit with a short message (it becomes the release notes) and push to
   `main`, but don't tag yet.
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
   secrets, then `shorebird release`.
4. At "distribute", show the GitHub Release with the APK.
5. At "Demo: v1.1.0 tới điện thoại", open the app on the phone. "Update v1.1.0
   available", tap Update, install. The new headline shows, and so does the
   bug: the version reads `v<build> (build 1.1.0)`. If no dialog appears, the
   status line says why; tap "Check for updates" to retry.
6. Still on that slide, fix the line in `lib/main.dart` back to
   `'${info.version} (build ${info.buildNumber})'`, then:

   ```bash
   git commit -am "Fix the version line" && git push
   git tag v1.1.0-patch.1 && git push origin v1.1.0-patch.1
   ```

   The `patch` job takes a few minutes and runs during the OTA slides.
7. At "Demo: sửa bằng OTA", show the `patch` job, then switch to the phone and
   return to the app (or tap "Check for updates"). It says "Patch 1
   downloaded". Close it from recents and reopen it. The version line is right,
   the label says `patch 1` with the fix commit, and the version is still
   1.1.0: same APK, new Dart code.

**Fallback:** keep a finished run open in another tab and have a screen
recording ready.

## Local checks

```bash
tool/check.sh
```
