# VanshVriksh

VanshVriksh ("family tree") is an offline, local-first family tree and genealogy app for
Android, built with Flutter.

All family data stays on your device: no accounts, no ads, no analytics, no tracking.

## Features

- Interactive family tree with a generation-based layout, plus a fan chart view
- Person profiles with facts, events, relationships, photos and media
- Multiple family trees
- GEDCOM 5.5.1 import
- Upcoming-birthdays dashboard
- Duplicate detection and merging, plus data integrity checks
- Research notes
- Encrypted local backups (ZIP with optional AES encryption) that you can export, share and
  restore through any app — cloud storage, email, external storage

## Building

Requires Flutter 3.44.0 (stable) / Dart 3.12.0.

```bash
flutter pub get
flutter run                  # debug build on a device or emulator
flutter build apk --release  # release APK
```

## Verification / CI

Run the same gates as CI (`.github/workflows/ci.yml`):

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build web --debug
```

`flutter analyze` reports 0 errors; 3 diagnostics (Drift web deprecation, Drift indexedDb
experimental, one settings mounted-check) are intentionally deferred follow-ups, not failures.

## License

Copyright (C) 2026 Ketan Dholakia.

This project is licensed under the GNU General Public License v3.0 or later (GPL-3.0-or-later) —
see [LICENSE](LICENSE).

## F-Droid

Packaging and submission material for F-Droid lives in [`docs/fdroid/`](docs/fdroid/).
