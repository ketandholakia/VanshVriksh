# fdroiddata merge request — description draft

Copy into the GitLab merge request when submitting the new app to
https://gitlab.com/fdroid/fdroiddata. Commit message convention: `New app: io.github.ketandholakia.vanshvriksh`

---

## New app: io.github.ketandholakia.vanshvriksh (VanshVriksh)

**What it is:** An offline, local-first family tree & genealogy app for Android.
Add people and relationships, record events, attach photos, view an interactive
tree and fan chart, import GEDCOM, detect duplicates, and create encrypted
backups — all stored on the device.

- **Source code:** https://github.com/ketandholakia/VanshVriksh
- **License:** GPL-3.0-or-later (LICENSE in repo)
- **Built with:** Flutter 3.44.0 (stable)
- **Tags:** v1.0.0

### Checklist

- [x] Public source code
- [x] Free license, `LICENSE` committed
- [x] Builds with free software only — no Google Play Services, Firebase, ads, or trackers
- [x] All data stays on device; no accounts, no telemetry
- [x] fastlane metadata committed in-repo (`fastlane/metadata/android/en-US/`)
- [x] CI (format / analyze / tests) green at the tagged commit

### Build recipe notes

- Flutter recipe follows `templates/build-flutter.yml`.
- Flutter SDK pinned via `srclibs: flutter@3.44.0` (matches the project's CI).
- `PUB_CACHE` kept inside the checkout and listed in `scandelete`.
- Only universal release APK for now; split-per-ABI can be added later.

### Testing

- `flutter build apk --release` verified locally; project CI runs
  `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test`.
- Happy to iterate on the recipe if the build server needs adjustments (Java/NDK).
