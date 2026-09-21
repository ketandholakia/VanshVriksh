# vanshvriksh

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Verification / CI

Supported toolchain: **Flutter 3.44.0 (stable) / Dart 3.12.0**.

Run the same gates locally as CI (`.github/workflows/ci.yml`):

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --debug
```

`flutter analyze` reports 0 errors; 3 diagnostics (Drift web
deprecation, Drift indexedDb experimental, one settings mounted-check) are
intentionally deferred follow-ups, not failures.
