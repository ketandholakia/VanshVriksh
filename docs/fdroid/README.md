# Publishing VanshVriksh on F-Droid

Status: **Phase 1 complete — ready for the fdroiddata merge request** (2026-09-29). Remaining: open the fdroiddata MR (needs a GitLab account) and add screenshots. This folder holds everything needed to
submit VanshVriksh to the main F-Droid repository and to keep releases flowing afterwards.

---

## 1. How F-Droid publication works

- F-Droid does not take an APK from you. It **builds the app from source** on its own build
  server, then signs and distributes it. (Reproducible builds optionally let them verify their
  build against your own — nice-to-have, not required.)
- To get listed, you add a **build recipe** (`metadata/<applicationId>.yml`) to the
  [`fdroiddata`](https://gitlab.com/fdroid/fdroiddata) repository on GitLab and open a merge
  request. After that, releases are mostly automatic (see §4, Phase 3).
- Core requirements:
  - The app must be **free software** (an FSF/OSI-approved license, with a `LICENSE` in the repo).
  - It must be **buildable using only free software** — no proprietary dependencies such as
    Google Play Services (`com.google.android.gms`) or Firebase in the F-Droid build.
  - No ads, no tracking. No "download the real thing" shells. No secrets required to build.
  - The app must be functional and usable.

## 2. Repo audit (as of 2026-09-29)

| Requirement | Status | Notes |
|---|---|---|
| Public source repo | ✅ | https://github.com/ketandholakia/VanshVriksh |
| Buildable from source (Flutter) | ✅ | F-Droid ships an official Flutter recipe template; the Flutter SDK is pulled via `srclibs: flutter@<version>` |
| Free-software license | ✅ | `LICENSE` added (GPL-3.0-or-later) |
| No proprietary components | ✅ | Google Drive backup removed (`google_sign_in`/`googleapis` dropped) — build uses free software only |
| Real application ID | ✅ | `io.github.ketandholakia.vanshvriksh` |
| Release tags | ✅ | `v1.0.0` tagged at the release commit |
| App display name | ✅ | Manifest label set to `VanshVriksh` |
| CI gates | ✅ | `.github/workflows/ci.yml` runs format / analyze / test / web build |
| fastlane listing metadata | ➕ drafted | `fastlane/metadata/android/en-US/` (title, descriptions, changelog) |
| No ads / no tracking | ✅ | none found in the code |
| Workspace hygiene | ✅ | Assistant workspace files untracked + ignored (2026-09-29); note: older copies remain in git history |

## 3. Decisions (resolved 2026-09-29)

**Resolved:** D1 → GPL-3.0-or-later · D2 → Google Drive backup removed · D3 → `io.github.ketandholakia.vanshvriksh` · D4 → git identity (Ketan Dholakia <ketanmci@gmail.com>). Notes below kept as the decision record.

**D1 — License.** F-Droid requires an FSF/OSI-approved license.
- Recommended: **GPL-3.0-or-later** (the F-Droid default choice; copyleft keeps derivatives free).
- Alternatives: **Apache-2.0** (same family as Flutter itself) or **MIT**.
Once chosen: add `LICENSE` to the repo root, set `License:` in the recipe, and mention it in the README.

**D2 — Google Drive backup.**
F-Droid builds cannot depend on Play Services, so the Drive upload/restore paths must go.
- Recommended: **remove Google Drive backup/restore entirely.** The existing
  "create backup → share sheet" flow (`share_plus`) already lets users save the backup to
  Drive, Nextcloud, email, etc. — without any proprietary dependency.
- Not recommended: keeping Drive only in non-F-Droid builds via a separate branch
  (double maintenance on every release).
On confirmation this is a contained change: remove `google_sign_in` + `googleapis` from
`pubspec.yaml`, delete the Drive methods in `lib/services/backup_service.dart`
(`uploadBackupToGoogleDrive`, `restoreLatestFromGoogleDrive`, `_signInToGoogle`,
`_formatGoogleSignInError`, `_GoogleAuthClient`) and the cloud buttons in
`lib/features/backup/backup_restore_page.dart`, then run the CI gates.

**D3 — Application ID.** Proposed: **`io.github.ketandholakia.vanshvriksh`** (needs no domain,
stable forever). If you own a domain, `com.ketandholakia.vanshvriksh`-style is equally fine —
but decide before the first release, because F-Droid treats it as the app's permanent identity.
Files affected: `android/app/build.gradle.kts` (`namespace` + `applicationId`) and
`android/app/src/main/kotlin/**/MainActivity.kt` (package + folder move).

**D4 — Recipe contact info.** The draft uses `Ketan Dholakia <ketanmci@gmail.com>` (from git
config — it is public metadata; say the word if you want something else).

## 4. Step-by-step

### Phase 1 — Repo cleanup & first release (this repo)

1. Add `LICENSE` (D1).
2. Rename the application ID (D3).
3. Remove the Play-Services-dependent code (D2), then run the same gates as CI:

   ```bash
   flutter pub get
   dart format --output=none --set-exit-if-changed .
   flutter analyze --no-fatal-infos --no-fatal-warnings
   flutter test
   flutter build apk --release   # smoke test of the actual release build
   ```

4. Hygiene pass: make sure `memory/`, `scratch/`, `evolution-drafts/`, `.openclaw-attachments/`
   and similar assistant workspace files are not (and will not be) committed; extend
   `.gitignore` where needed. Also replace the boilerplate README text with a real one —
   F-Droid reviewers read it.
5. Commit, tag, push:

   ```bash
   git add -A
   git commit -m "chore: prepare first release for F-Droid"
   git tag v1.0.0
   git push origin main --tags
   ```

6. Optional: a GitHub release workflow that builds and attaches APKs (useful for your own
   distribution; F-Droid does not need it).

### Phase 2 — Submit to fdroiddata

1. Create a GitLab account; fork https://gitlab.com/fdroid/fdroiddata.
2. In your fork create `metadata/io.github.ketandholakia.vanshvriksh.yml` — copy
   `docs/fdroid/metadata/io.github.ketandholakia.vanshvriksh.yml`, **remove all comments**,
   double-check `AuthorEmail` and `License`.
3. Commit ("New app: io.github.ketandholakia.vanshvriksh") and open a merge request; paste the
   description from `docs/fdroid/mr-description.md`.
4. CI lints the recipe and attempts a build. First builds of Flutter apps often need one small
   recipe fix (Java / NDK / Flutter version — see §6 Troubleshooting); discuss it in the MR.
5. After merge the app appears on f-droid.org, usually within ~24 h (worst case ~a week).
6. Optional alternative/complement: [IzzyOnDroid](https://izzyondroid.org/) — a widely used
   third-party repo with faster onboarding and similar requirements; many apps list there too.

### Phase 3 — Every release after that

- Bump `version: X.Y.Z+N` in `pubspec.yaml`, commit, tag `vX.Y.Z`, push.
- F-Droid's update check (tags + pubspec mapping) proposes the new build automatically. If the
  Flutter version changed, add a new `Builds:` entry with an updated `srclibs: flutter@<version>`.
- Keep `fastlane/metadata/android/en-US/` updated; add
  `changelogs/<versionCode>.txt` for each release (≤ 500 characters).
- Optional later: reproducible-build attestation (see Sources).

## 5. The build recipe, explained

Draft: [`metadata/io.github.ketandholakia.vanshvriksh.yml`](metadata/io.github.ketandholakia.vanshvriksh.yml)

| Field | Meaning / why here |
|---|---|
| `Builds[].commit` | Tag (`v1.0.0`) or full commit SHA. The tag must exist on GitHub before the MR |
| `Builds[].output` | `build/app/outputs/flutter-apk/app-release.apk` — Flutter's release APK path |
| `srclibs: [flutter@3.44.0]` | Pins the Flutter SDK to the version this project's CI uses. `$$flutter$$` = that checkout |
| `rm:` | Deletes non-Android platform folders (`ios`, `linux`, `macos`, `web`, `windows`) before building |
| `prebuild:` | `PUB_CACHE` inside the checkout (so the scanner can review all Dart dependencies), `flutter config --no-analytics`, `pub get --enforce-lockfile` (`pubspec.lock` is committed) |
| `scandelete: [.pub-cache]` | Build-time only; must not end up in the published app |
| `build:` | `flutter build apk` (release by default) |
| `AutoUpdateMode: Version` + `UpdateCheckMode: Tags` | New release = new tag → new build entry |
| `UpdateCheckData: pubspec.yaml\|version:\s.+\+(\d+)\|.\|version:\s(.+)\+` | Maps `version: X.Y.Z+N` → versionName / versionCode |
| `CurrentVersion` / `CurrentVersionCode` | Baseline for the update check |

Notes:
- The recipe follows F-Droid's official template
  ([`templates/build-flutter.yml`](https://gitlab.com/fdroid/fdroiddata/-/blob/master/templates/build-flutter.yml))
  and the wger app's proven configuration
  ([`de.wger.flutter.yml`](https://gitlab.com/fdroid/fdroiddata/-/blob/master/metadata/de.wger.flutter.yml)).
- Alternative to hardcoding the Flutter version: `srclibs: flutter@stable` + a `prebuild` step
  that extracts the version from the repo and runs `git -C $$flutter$$ checkout -f $flutterVersion`
  (how wger does it now). Hardcoding is simpler for a first submission; switch later if you like.

## 6. Troubleshooting (F-Droid Flutter builds)

- **Java / Gradle toolchain errors** → add to the build entry (pattern from wger):

  ```yaml
      sudo:
        - apt-get update
        - apt-get install -y openjdk-17-jdk-headless
        - update-java-alternatives -a
  ```

- **Missing/incorrect NDK** → set `ndk: r2Xx` on the build entry (wger uses `ndk: r28c`).
- **`flutter@3.44.0` not found** → make sure the tag exists on `github.com/flutter/flutter`;
  otherwise pin to the nearest existing version.
- **"Google artifacts found" / GMS errors** → something still depends on Play Services; check
  the dependency cleanup from D2.
- **`pub get --enforce-lockfile` fails** → refresh `pubspec.lock` in the repo at the release commit.
- Build steps must not rely on downloading prebuilt binaries; keep the build to pub get + build.

## 7. fastlane listing metadata (app texts + images)

Drafted under `fastlane/metadata/android/en-US/` — F-Droid reads this directly from the app
repo at build time. Expected layout:

```
fastlane/metadata/android/en-US/
├── title.txt                 (≤ 30 chars)
├── short_description.txt     (≤ 80 chars)
├── full_description.txt      (≤ 4000 chars)
├── changelogs/1.txt          (≤ 500 chars, one file per versionCode)
└── images/
    ├── icon.png              (512×512, optional — the APK icon is used otherwise)
    └── phoneScreenshots/      (2–8 screenshots, PNG/JPEG, 320–3840 px)
```

Before submission: **take real screenshots** on a device/emulator (portrait, populated with
demo data) and drop them into `images/phoneScreenshots/`. Everything else is drafted.

## 8. Submission-day checklist

- [ ] `LICENSE` committed
- [ ] `google_sign_in` / `googleapis` removed, Drive code removed, CI green
- [ ] Application ID renamed everywhere; `flutter build apk --release` works
- [ ] Repo hygiene done (no assistant workspace files tracked); README updated
- [ ] `fastlane/` texts + screenshots committed
- [ ] Tag `v1.0.0` pushed
- [ ] fdroiddata fork: `metadata/<applicationId>.yml` (comments stripped, TODOs filled)
- [ ] MR opened with the description from `docs/fdroid/mr-description.md`

## 9. Sources

- Submitting to F-Droid — Quick Start Guide: https://f-droid.org/en/docs/Submitting_to_F-Droid_Quick_Start_Guide/
- Build Metadata Reference: https://f-droid.org/en/docs/Build_Metadata_Reference/
- Official Flutter build template (fdroiddata): https://gitlab.com/fdroid/fdroiddata/-/blob/master/templates/build-flutter.yml
- Real-world Flutter recipe (wger): https://gitlab.com/fdroid/fdroiddata/-/blob/master/metadata/de.wger.flutter.yml
- All About Descriptions, Graphics, and Screenshots: https://f-droid.org/en/docs/All_About_Descriptions_Graphics_and_Screenshots/
- Reproducible Builds: https://f-droid.org/en/docs/Reproducible_Builds/
- Anti-Features (NonFreeNet, NonFreeComp, …): https://f-droid.org/en/docs/Anti-Features/
