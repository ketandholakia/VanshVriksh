# Audit — App Shell / Core / Settings / Services / Config / Tests

**Scope:** `lib/main.dart`, `lib/app/**`, `lib/core/**`, `lib/features/shell/**`, `lib/features/splash/**`, `lib/features/settings/**`, `test/**`, `analysis_options.yaml`, `pubspec.yaml`, `README.md`, all platform folders (`android/`, `ios/`, `macos/`, `windows/`, `linux/`, `web/`), `assets/`.
**Method:** every file in scope read in full; evidence collected with `Select-String`; `flutter analyze` and `flutter test` executed on the working copy.

**Environment observed:**
- `flutter --version` → `Flutter 3.44.0 • channel stable`, `Dart 3.12.0`.
- `flutter analyze lib test` → **20 issues** (1 undeclared direct dependency, 4 unused imports, 3 dead-code/null-lint triples, 1 `use_build_context_synchronously`, deprecated Web drift API).
- `flutter analyze` (repo root) → **84 issues, exit code 1** — all from `scratch/new_canvas.dart`.
- `flutter test` → **9 tests, all pass** (4 files).

---

## 0. Summary table

| # | Severity | Area | Finding | Anchor |
|---|----------|------|---------|--------|
| 1 | **Critical** | Routing | Settings "Backup & Restore" pushes non-existent `/settings/backup` | `settings_page.dart:106` |
| 2 | **Critical** | Android config | `INTERNET` permission missing from the **release** manifest | `android/app/src/main/AndroidManifest.xml:1-8` |
| 3 | **Critical** | Android/iOS config | geolocator/geocoding used, **zero** location permission strings/permissions | `person_form_page.dart:267-290`, `AndroidManifest.xml`, `ios/Runner/Info.plist` |
| 4 | **High** | Routing | Whole `/v2` genealogy module unreachable from the app UI | `app_router.dart:194-241` |
| 5 | **High** | Security | Zip-slip path traversal in `restoreBackup` | `backup_service.dart:61-77` |
| 6 | **High** | Security | AES-CBC without MAC + hardcoded salt → silent garbage restore | `backup_service.dart:268-312` |
| 7 | **High** | Dead code | 5 orphaned pages/shells shipped in `lib/` (one with a hardcoded remote image) | `app_shell.dart`, `splash_page.dart`, `people_page.dart`, `tree_page.dart`, `backup_page.dart` |
| 8 | **High** | Perf/correctness | Provider created inside `build()` + `FutureBuilder(future: ...()` in `build()` → refetch storm | `genealogy_tree_page.dart:33, 155, 402, 457-458` |
| 9 | **High** | DX/CI | `flutter analyze` fails at repo root (84 errors from `scratch/`) | `analysis_options.yaml` |
| 10 | **High** | macOS config | No `com.apple.security.network.client` → all network features dead on macOS | `macos/Runner/Release.entitlements:4-6` |
| 11 | **Medium** | Settings | Auto Backup / Frequency / Wi-Fi Only persist but do nothing | `settings_page.dart:127-198`, `backup_restore_page.dart:340-390` |
| 12 | **Medium** | Settings UX | Two GEDCOM import entries (one working, one "Coming soon") + dead Export | `settings_page.dart:109-115` vs `261-289` |
| 13 | **Medium** | Error handling | `Navigator.pop()` in `catch` pops the Settings page when no dialog was shown | `settings_page.dart:1220-1233` |
| 14 | **Medium** | Theme | Brand logo keyed off `platformBrightness`, not resolved theme mode | `vanshvriksh_app.dart:48-53`, `dashboard_page.dart:113-117` |
| 15 | **Medium** | Settings | Date Format / Hide Living Years / photo-fit silently ignored by `/v2` pages | `lib/features/genealogy/**` (no provider watches) |
| 16 | **Medium** | Navigation | Dashboard quick actions `push()` shell routes → duplicate `MainShellPage` in stack | `dashboard_page.dart:77-98` |
| 17 | **Medium** | Navigation | `PopScope(canPop:false)` + `SystemNavigator.pop()` kills the app on first back press | `main_shell_page.dart:57-70` |
| 18 | **Medium** | Tests | `widget_test.dart` name lies; asserts only the loading spinner | `test/widget_test.dart:8-14` |
| 19 | **Medium** | Deps | `rxdart` imported directly but only a **transitive** dep | `relationship_repository.dart:3,171` |
| 20 | **Medium** | Deps | Unused deps: `cached_network_image`, `cupertino_icons`; `sqlite3_flutter_libs ^0.6.0+eol` (EOL) | `pubspec.yaml:42,49,56` |
| 21 | **Medium** | Auth | `google_sign_in` Drive flow has no OAuth config in-repo; code already expects failure | `backup_service.dart:81,259` |
| 22 | **Medium** | Web config | `manifest.json`/`index.html` still carry template branding + remote CDN script | `web/manifest.json:3-6`, `web/index.html:20` |
| 23 | **Medium** | Android config | Placeholder `applicationId` + release signed with **debug** keys | `android/app/build.gradle.kts:12-24` |
| 24 | **Medium** | iOS config | Missing `NSCameraUsageDescription` / `NSLocationWhenInUseUsageDescription` | `ios/Runner/Info.plist:4-6` |
| 25 | **Low** | Settings | `Reset Tree State` doesn't clear expand-all; keys grow unbounded | `app_settings_provider.dart:437-463` |
| 26 | **Low** | i18n | No `flutter_localizations` / `supportedLocales` / language setting | `vanshvriksh_app.dart:125-135` |
| 27 | **Low** | Quality | `settings_page.dart` 1223 lines; duplicated backup prefs UI in 2 pages | `settings_page.dart`, `backup_restore_page.dart:337-412` |
| 28 | **Low** | Quality | Hardcoded version string; stale `README.md`; `_importGedcom` blocking dialog pattern | `settings_page.dart:19`, `README.md:1-6` |

---

## 1. Architecture

### 1.1 CRITICAL — Settings → "Backup & Restore" navigates to a route that does not exist
`lib/features/settings/settings_page.dart:100-107`
```dart
ListTile(
  leading: const Icon(Icons.backup_outlined),
  title: const Text('Backup & Restore'),
  subtitle: const Text('Export or restore your family tree data.'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () => context.push('/settings/backup'),
),
```
The router defines `/backup` (`lib/app/app_router.dart:75`), never `/settings/backup`. `GoRouter` has **no `errorBuilder`, no `onException`, no `redirect`** (verified by grep over all of `lib/` — zero hits for `errorBuilder|onException|redirect`).

**Impact:** the first actionable row on the Settings page renders GoRouter's default "Page Not Found" screen. There is no recovery affordance and no logging.
**Fix:** `context.push('/backup')`. Additionally add `errorBuilder:` to `appRouter` so unknown URLs render an in-app 404 with a "Go home" button instead of the raw router error; add `onException` to log.

### 1.2 HIGH — Entire `/v2` genealogy module is unreachable from the app UI
Routes exist (`lib/app/app_router.dart:194-241`: `/v2/people/add`, `/v2/people`, `/v2/people/:id`, `/v2/people/:id/edit`, `/v2/people/:id/link/:type`, `/v2/tree/:id`), but a grep for `/v2` across `lib/` returns **only** the router file and the v2 pages themselves:
```
lib\features\genealogy\genealogy_people_list_page.dart:58,118
lib\features\genealogy\genealogy_person_profile_page.dart:60,108,114,119,124
lib\features\genealogy\genealogy_person_form_page.dart:191,195
lib\features\genealogy\genealogy_link_family_page.dart:130,134
lib\app\genealogy_tree_page.dart:74,353,397
```
Nothing outside the module links to it: `main_shell_page.dart:14-22` has no v2 destination, `dashboard_page.dart:63-98` has no v2 link, `settings_page.dart` has no v2 link. Deep links can't reach it either: the Android manifest has only `MAIN`/`LAUNCHER` (`AndroidManifest.xml:23-29`, no `VIEW`/`BROWSE` intent filter), iOS has no `CFBundleURLTypes` (`ios/Runner/Info.plist`), and `GoRouter(initialLocation: '/')` (`app_router.dart:34`) ignores the platform initial route.

**Impact:** `GenealogyPeopleListPage`, `GenealogyPersonProfilePage`, `GenealogyPersonFormPage`, `GenealogyLinkFamilyPage`, `GenealogyTreePage` and their supporting settings (Connector Colors, Tree Card density in the v2 tree, "Reset Tree State") are effectively dead code that nonetheless ships in the binary.
**Fix:** either surface `/v2/people` from the shell/dashboard (e.g. a nav entry or a "Genealogy v2" card), or delete the module. If it is intended as the future replacement, add a feature flag + entry point so it is testable.

### 1.3 HIGH — Five orphaned screens (dead code) still compiled into the app
| File | Symbol | Evidence it is unreachable |
|------|--------|---------------------------|
| `lib/features/shell/app_shell.dart:4` | `AppShell` | grep for `AppShell` returns only its own declaration; and it navigates to a route that does not exist: `app_shell.dart:20` `context.go('/dashboard')` (router defines `/` with `name: 'dashboard'`) |
| `lib/features/splash/splash_page.dart:10` | `SplashPage` | never imported outside itself; splash duty is done by `_StartupSplash` in `lib/app/vanshvriksh_app.dart:159-233` |
| `lib/features/people/people_page.dart:5` | `PeoplePage` | never routed; contains a hardcoded remote image: `people_page.dart:62-64` `NetworkImage('https://images.unsplash.com/photo-1500648767791-00dcc994a43e?...')`; its FAB targets another non-existent route: `people_page.dart:27` `context.go('/people/profile')` |
| `lib/features/tree/tree_page.dart:5` | `TreePage` | placeholder ("Tree view coming next"); superseded by `features/tree/family_tree_page.dart` |
| `lib/features/backup/backup_page.dart:6` | `BackupPage` | placeholder; superseded by `features/backup/backup_restore_page.dart` |

Note: `lib/app/genealogy_tree_page.dart` is **not** dead — it is a `part of 'app_router.dart'` (`app_router.dart:31`) and reachable at `/v2/tree/:id`. See §6.3.
**Impact:** two dead navigation targets (`/dashboard`, `/people/profile`) would crash/bounce if the dead pages were ever wired; `PeoplePage` also ships a third-party network fetch (privacy + offline failure) and Google-Font-free placeholder data ("Anand Sharma", "Born 1985").
**Fix:** delete all five files. Add `unused_element`-style review to CI (analyze won't flag unreferenced public classes, so a manual/greped check is needed).

### 1.4 Route inventory & ordering (verified correct, one latent trap)
All 25 routed pages were cross-checked against the route table:
- `/` `:40`, `/people` `:45`, `/people/duplicates` `:50`, `/integrity` `:55`, `/duplicates/marked` `:60`, `/tree` `:65`, `/fan-tree` `:70`, `/backup` `:75`, `/settings` `:80` (all inside the `ShellRoute`).
- Root-level: `/birthdays` `:87`, `/people/add` `:92`, `/people/:id/edit` `:111`, `/people/:id/add-relationship` `:119`, `/people/:id/media` `:131`, `/people/:id/facts` `:139`, `/people/:id/facts/new` `:147`, `/people/:id/facts/edit/:factId` `:158`, `/tree/:rootPersonId` `:170`, `/fan-tree/:rootPersonId` `:178`, `/people/:id` `:186`, `/v2/*` `:194-241`.
- Ordering safety: `/people/add` (`:92`) is declared before `/people/:id` (`:186`) ✔; `/people/duplicates` and `/people/:id` do not collide because the former is inside the shell (`:50`) and matched first ✔.
- **Latent trap:** root-level `/people/:id` (`:186`) will also swallow any future `/people/<literal>` path declared *after* it; `/people/profile` used by the dead `people_page.dart:27` would today render a person profile with id `profile`. Worth a comment/guard.

### 1.5 MEDIUM — Dashboard quick actions `push()` shell routes, stacking a second `MainShellPage`
`lib/features/dashboard/dashboard_page.dart:77-98`
```dart
onTap: () => context.push('/people'),
...
onTap: () => context.push('/tree'),
...
onTap: () => context.push('/backup'),
...
onTap: () => context.push('/settings'),
```
Because the bottom-nav destinations use `context.go` (`main_shell_page.dart:33-45`) while the dashboard uses `push`, imperatively pushing a route that lives inside the `ShellRoute` builds a *new* shell instance above the existing one instead of switching tabs.
**Impact:** growing back stack, two live `MainShellPage`s (duplicate nested `NavigationBar` state, duplicate provider subscriptions), and inconsistent back behaviour depending on how the user arrived. Also inconsistent with `people_list_page.dart:61` which uses `context.go('/people/duplicates')`.
**Fix:** use `context.go(...)` for all shell destinations (or move the actions out of the shell), and reserve `push` for detail routes (`/people/:id`, `/birthdays`).

### 1.6 MEDIUM — Root back press kills the app immediately
`lib/app/main_shell_page.dart:57-70`
```dart
body: PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;
    if (context.canPop()) { context.pop(); return; }
    SystemNavigator.pop();
  },
```
**Impact:** on Android, the very first back press at a root tab exits the process with no confirmation and no "press again to exit"; on web/desktop `SystemNavigator.pop()` is a no-op, so the user is stuck. Because `canPop:false` is registered on the shell, predictive-back (`android:enableOnBackInvokedCallback` is absent from the manifest) cannot work either.
**Fix:** keep `PopScope` but implement double-tap-to-exit for Android only, or drop it entirely and let the platform pop; scope the PopScope to the root location instead of the whole shell.

### 1.7 Not found: deep links, state restoration, error boundaries
- **Deep links:** no `VIEW`/`BROWSE` intent-filter (`AndroidManifest.xml:23-31`), no `CFBundleURLTypes` (`ios/Runner/Info.plist`), `initialLocation: '/'` hard-set (`app_router.dart:34`).
- **State restoration:** grep for `restorationScopeId` across `lib/` → **zero hits**; `MaterialApp.router` (`vanshvriksh_app.dart:125-138`) has none. Process-death restore relies entirely on SharedPreferences; the in-page state (tree zoom/pan, search text, draft person form) is lost.
- **Error boundaries:** see §5.1.

---

## 2. Settings: persisted vs applied

### 2.1 What actually persists AND is applied (verified consumers)
| Setting | Key | Persisted | Consumer |
|---|---|---|---|
| Theme mode | `app_theme_mode` (`app_settings_provider.dart:62`) | ✔ `:530-547` | `vanshvriksh_app.dart:52-57` → `MaterialApp.themeMode` ✔ |
| Default tree view (tree/fan) | `app_landing_view` `:46` | ✔ `:296-310` | `main_shell_page.dart:53-55, 40` ✔ |
| Date display format | `date_display_format` `:47` | ✔ `:325-341` | `people_list_page.dart:47`, `person_profile_page.dart:27`, `person_form_page.dart:843`, `family_tree_page.dart:70`, `family_fan_chart_page.dart:67` ✔ |
| Relationship label style | `relationship_label_style` `:48` | ✔ `:346-360` | `person_profile_page.dart:29`, `add_relationship_page.dart:127,161`, tree pages ✔ |
| Photo fit mode | `person_photo_fit_mode` `:50` | ✔ `:394-408` | `people_list_page.dart:49`, `person_profile_page.dart:32`, tree pages, `genealogy_people_list_page.dart:50` ✔ |
| Card spacing / density / line thickness / connector palettes | `:49,:51,:53-55` | ✔ | `family_tree_page.dart:78-83`, `family_fan_chart_page.dart:75-80`, `genealogy_tree_page.dart:45-53` ✔ |
| Hide years for living | `hide_years_for_living` `:59` | ✔ `:487-500` | `people_list_page.dart:51`, `person_profile_page.dart:35`, tree pages — **but not the `/v2` pages** (see 2.4) |
| Zoom/fit on load | `zoom_on_load` `:58` | ✔ `:469-483` | `family_tree_page.dart:83`, `family_fan_chart_page.dart:80` ✔ |
| Remember last root person | `remember_last_root_person` `:56` | ✔ `:589-601` (clears `last_root_person_id` when off — good) | `tree_providers.dart:27-33`, tree pages ✔ |
| Default root person | `default_root_person_id` `:58` | ✔ `:602-618` | `family_tree_page.dart:59`, `family_fan_chart_page.dart:56` ✔ |
| Encrypt backup | `backup_encrypt` `:64` | ✔ | `backup_restore_page.dart:67,111` ✔ |

### 2.2 MEDIUM — Dead toggles: Auto Backup / Frequency / Wi-Fi Only
`lib/features/settings/settings_page.dart:127-198` and duplicated at `lib/features/backup/backup_restore_page.dart:337-412`:
```dart
SwitchListTile(
  title: const Text('Auto Backup'),
  subtitle: const Text('Enable scheduled backups later.'),   // settings_page.dart:143
  value: selectedBackupAuto, ...
```
Naming/subtitles concede the feature does not exist ("later", `backup_restore_page.dart:346` "Use Wi-Fi when auto backup is added"). No scheduler dependency exists in `pubspec.yaml` (no `workmanager`, `background_fetch`, `flutter_background_service`), and grep shows the three providers are only ever read by the two settings UIs.
**Impact:** users can enable "Auto Backup"/"Wi-Fi Only" and reasonably believe their data is being backed up — a data-loss trust issue for a genealogy app.
**Fix:** remove the three controls until implemented, or render them disabled with an explicit "Not implemented" chip (as done for Backup Reminder).

### 2.3 MEDIUM — Duplicated GEDCOM UI: one working importer, two "Coming soon" stubs
Working:
```dart
// settings_page.dart:109-115
ListTile(
  leading: const Icon(Icons.file_upload_outlined),
  title: const Text('Import GEDCOM 5.5.1'),
  subtitle: const Text('Import genealogy records from a .ged file.'),
  onTap: () => _importGedcom(context, ref),
),
```
Stale/duplicated:
```dart
// settings_page.dart:261-272  ("GEDCOM Import" — Coming soon, snackbar "will be added later")
// settings_page.dart:275-289  ("GEDCOM Export" — Coming soon)
```
**Impact:** contradictory UX; the "Coming soon: import" card tells the user the *already working* feature is missing. `_importGedcom` is also untested (see §6).
**Fix:** delete the two stub cards (keep a single "GEDCOM Export — Soon" if desired).

### 2.4 MEDIUM — Settings silently ignored by the `/v2` module
No file under `lib/features/genealogy/` watches `dateDisplayFormatProvider`, `relationshipLabelStyleProvider`, or `hideYearsForLivingProvider` (grep results in §2.1 show consumers only in `features/people`, `features/tree`, `features/relationships`).
**Impact:** "Date Format: Year only" and "Hide Years for Living People" (a privacy control) do nothing on the genealogy profile/list/tree screens. Given the `/v2` module is itself unreachable (§1.2), this compounds the confusion.
**Fix:** thread the three providers through the genealogy pages, or (better, given §1.2) remove the module.

### 2.5 MEDIUM — `_importGedcom` pops the wrong route on failure
`lib/features/settings/settings_page.dart:1220-1233`
```dart
Future<void> _importGedcom(BuildContext context, WidgetRef ref) async {
  try {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      showDialog(context: context, barrierDismissible: false, builder: ...CircularProgressIndicator());
      await ref.read(gedcomImportProvider.notifier).importGedcomFile(file, AppConstants.defaultTreeId);
      if (context.mounted) Navigator.of(context).pop();
      ...
  } catch (e) {
    if (context.mounted) Navigator.of(context).pop();      // ← line 1231
```
If `FilePicker.platform.pickFiles` throws (plugin missing on desktop, OS error) the `catch` still calls `Navigator.pop()`, popping the **Settings page** itself. Analyzer independently flags this block: `lib\features\settings\settings_page.dart:1225:18 - use_build_context_synchronously`. The dialog also has no `mounted` guard at `showDialog` and is dismissed by a bare `Navigator.of(context).pop()` (pops whatever is on top).
**Fix:** track a `bool dialogShown` (or use `showDialog(...).then`) and only pop when it was actually shown; wrap in `if (!context.mounted) return;`; consider a `StatefulWidget` section so the dialog lifecycle is owned by state.

### 2.6 LOW — SharedPreferences key hygiene
- Keys are consistent snake_case constants (`app_settings_provider.dart:46-65`), good.
- Tree-expansion state is persisted as an unbounded `List<String>`: `app_settings_provider.dart:437-441` `prefs.getStringList(_treeExpandedBranchIdsKey)?.toSet()` and `:460` `setStringList(...)`. Only manual invalidation is the Settings "Reset Tree State" tile (`settings_page.dart:585-596` → `resetGenealogyTreeState`, `app_settings_provider.dart:465-467`), which calls `clear()` (`:462-463`) that clears **branch ids only** — `genealogy_tree_expand_all` (`:119-127`) and `last_root_person_id` are not reset, contradicting the tile's "Clear saved branch expansion state" claim.
- Settings keys are split across two files: `_fanChartAncestorGenerationsKey` lives in `fan_chart_settings_provider.dart:6` while every other key is in `app_settings_provider.dart`. Minor cohesion issue.
- Backup history is stored in SharedPreferences under `backup_history` (`backup_service.dart:24`) as JSON-encoded strings including absolute file paths (`:360-370`) — fine, but it is unencrypted metadata about the user's data.

### 2.7 LOW — Theme switching correctness
Theme switching itself is correct: `appThemeModeProvider` → `themeMode` mapping (`vanshvriksh_app.dart:52-57`) matches the enum persist mapping (`app_settings_provider.dart:530-547`). The defect is the **logo**, see §2.8.

### 2.8 MEDIUM — Brand logo follows the OS, not the selected theme
`lib/app/vanshvriksh_app.dart:45-53`
```dart
final brightness = MediaQuery.maybeOf(context)?.platformBrightness ?? Brightness.light;
final brandLogo = brightness == Brightness.dark
    ? 'assets/vanshvriksh_logo_dark.png'
    : 'assets/vanshvriksh_logo_light.png';
```
This `context` sits **above** `MaterialApp.router`, so it can only ever see the platform brightness — never the user's `AppThemeMode`. Same defect in `lib/features/dashboard/dashboard_page.dart:112-117`. The loader/error screens (`vanshvriksh_app.dart:70-155`) show the light logo on a dark system background when the app theme is Light.
**Fix:** resolve the logo *inside* the `builder` (below `MaterialApp`): `Theme.of(context).brightness == Brightness.dark ? ...`.

### 2.9 LOW — Duplicated sources of truth for backup settings
The exact same four controls (Auto / Frequency / Wi-Fi Only / Encrypt) are rendered from the same providers in `settings_page.dart:127-210` and `backup_restore_page.dart:337-412`. Two independent edit paths that must be kept in sync.
**Fix:** extract a single `BackupPreferencesSection` widget.

### 2.10 LOW — App version hardcoded
`settings_page.dart:19` `static const String appVersion = '1.0.0';` while `pubspec.yaml:19` is `version: 1.0.0+1`. The About tab can silently drift.
**Fix:** add `package_info_plus` and read `PackageInfo.fromPlatform()`.

---

## 3. Platform / config

### 3.1 CRITICAL — `INTERNET` permission missing from the release Android manifest
`android/app/src/main/AndroidManifest.xml` (full permission list):
```xml
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />     <!-- :2 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" /> <!-- :3 -->
```
`INTERNET` appears **only** in `android/app/src/debug/AndroidManifest.xml:4` and `android/app/src/profile/AndroidManifest.xml:4` (template "required for development … hot reload").
**Impact:** every network feature is dead in a release APK/AAB:
- Google Drive backup upload/restore — `backup_service.dart:70-91`, `:119-158`;
- birthplace search over HTTP — `lib/features/people/person_form_page.dart:10` (`import 'package:http/http.dart'`), plus geocoding lookups (`:290`);
- any future image loading.
**Fix:** add `<uses-permission android:name="android.permission.INTERNET"/>` to the **main** manifest (keep the debug copy).

### 3.2 CRITICAL — geolocator/geocoding used with no location permissions anywhere
Usage: `lib/features/people/person_form_page.dart`
```dart
267: final serviceEnabled = await Geolocator.isLocationServiceEnabled();
272: var permission = await Geolocator.checkPermission();
274: permission = await Geolocator.requestPermission();
285: final position = await Geolocator.getCurrentPosition(...);
290: final placemarks = await placemarkFromCoordinates(...);
```
Config:
- `android/app/src/main/AndroidManifest.xml` — **no** `ACCESS_FINE_LOCATION`, **no** `ACCESS_COARSE_LOCATION`.
- `ios/Runner/Info.plist` — **no** `NSLocationWhenInUseUsageDescription` (only `NSPhotoLibraryUsageDescription` at `:5`).

**Impact:** on Android `requestPermission()` returns `denied` immediately (permission not declared ⇒ auto-denied) and `getCurrentPosition` throws; on iOS the request terminates the app for a missing usage string in some paths. The "use current location" feature in the person form can never work.
**Fix:** declare `ACCESS_COARSE_LOCATION`/`ACCESS_FINE_LOCATION` on Android, add `NSLocationWhenInUseUsageDescription` on iOS, and handle the denied branch in the UI (feedback message + manual entry).

### 3.3 HIGH — macOS release build cannot use the network
`macos/Runner/Release.entitlements`
```xml
<key>com.apple.security.app-sandbox</key><true/>          <!-- :5 -->
```
That is the only entitlement. `DebugProfile.entitlements:9` grants `com.apple.security.network.server` (server, not client). **No `com.apple.security.network.client` in either file.**
**Impact:** on a sandboxed macOS build, Google Drive backup, geocoding and any `http` call fail. `macos/Runner/Info.plist:9` also has an empty `CFBundleIconFile`.
**Fix:** add `com.apple.security.network.client` to both entitlements files; add the app icon key.

### 3.4 MEDIUM — iOS usage strings missing for features that ship
`ios/Runner/Info.plist` declares only `NSPhotoLibraryUsageDescription` (`:5`).
Missing: `NSCameraUsageDescription` (the `image_picker` camera source used from `person_form_page.dart:9`), `NSLocationWhenInUseUsageDescription` (§3.2), `NSPhotoLibraryAddUsageDescription` (saving photos, `features/media/person_media_gallery_page.dart`).
Also inconsistent branding: `CFBundleDisplayName` = `Vanshvriksh` (`:12`) vs the constant `AppConstants.appName = 'VanshVriksh'` (`lib/core/constants/app_constants.dart:3`).

### 3.5 MEDIUM — Android app identity is still the Flutter placeholder
`android/app/build.gradle.kts:12-24`
```kotlin
// TODO: Specify your own unique Application ID ...
applicationId = "com.yourcompany.vanshvriksh"     // :13
...
signingConfig = signingConfigs.getByName("debug") // :23
```
`android/app/src/main/AndroidManifest.xml:6` `android:label="vanshvriksh"` (lowercase; the launcher label should be "VanshVriksh").
`minSdk`/`targetSdk`/`compileSdk` come from Flutter defaults (`:11,:17-18`) — acceptable for a 3.44 toolchain, but they will drift with the SDK; pin them once the target matrix is decided.
**Impact:** cannot publish to Play with `com.yourcompany.*`; release builds are debug-signed (not distributable; also blocks the Google Sign-In SHA-1 flow entirely).
**Fix:** real application id + release keystore (`key.properties`), `android:label="VanshVriksh"` (or a `strings.xml`).

### 3.6 MEDIUM — Web config still template-default in places, plus a remote CDN dependency + deprecated drift web API
- `web/manifest.json:3-6`
```json
"name": "vanshvriksh", "short_name": "vanshvriksh",
"background_color": "#0175C2", "theme_color": "#0175C2",
```
Brand cream is `#FFF8E7` (`android/app/src/main/res/values/colors.xml`, `flutter_native_splash.color` in `pubspec.yaml:76`). The PWA install prompt shows lowercase "vanshvriksh" on Flutter-blue instead of the app's identity.
- `web/index.html:20-33` loads and patches a **remote** script: `https://cdnjs.cloudflare.com/ajax/libs/sql.js/1.11.0/sql-wasm.js` with no `integrity` hash and a `locateFile` override pointing at the same CDN. The web build therefore cannot run offline and executes third-party JS at boot; the WASM fetch is additionally at the mercy of the CDN.
- `lib/data/database/app_database_open_connection_web.dart:2` uses `package:drift/web.dart` — analyzer: *"deprecated … Please consider migrating to the new web APIs"*, plus `DriftWebStorage.indexedDb` is flagged `experimental_member_use` (`:6`).
**Fix:** brand the manifest, self-host `sql-wasm.wasm`/`sql-wasm.js` under `web/` (or add SRI + a fallback), and migrate to `package:drift/wasm.dart`.

### 3.7 Verified OK (assets / icons / splash)
- `pubspec.yaml:60-62` assets: `assets/`, `assets/logo/tree_mark.svg`. All four referenced files exist and are non-empty: `assets/vanshvriksh_app_background.png` (1.59 MB), `vanshvriksh_logo_dark.png` (251 KB), `vanshvriksh_logo_light.png` (235 KB), `vanshvriksh_splash.png` (1.47 MB), `assets/logo/tree_mark.svg` (2.2 KB). `tree_mark.svg` is listed explicitly, which is *correct* because Flutter's `assets/` entry is non-recursive.
- `flutter_native_splash` / `flutter_launcher_icons` output is present: `android/app/src/main/res/drawable-*/splash.png`, `android12splash.png`, `ic_launcher_foreground.png`, `mipmap-anydpi-v26/ic_launcher.xml`, `web/splash/img/{light,dark}-1x..4x.png`, `web/icons/Icon-*`, `ios/Runner/Assets.xcassets/AppIcon.appiconset/*` (21 sizes). No missing-asset failures.
- One dead asset: `assets/vanshvriksh_splash.png` (1.47 MB, a third of the bundle's assets) is referenced by **no** Dart file or config (grep for `vanshvriksh_splash` outside `assets/` → zero hits). It ships in every build for nothing.

### 3.8 Desktop (Windows/Linux) config
`windows/runner/{main.cpp,Runner.rc,resources/app_icon.ico}` and `linux/runner/my_application.cc` are untouched templates; no platform-specific blockers found beyond the macOS entitlement gap (§3.3). Desktop is not a stated target, but note §3.3/§3.6 mean "desktop support" is nominal.

---

## 4. Security

### 4.1 HIGH — Zip-slip (path traversal) in backup restore
`lib/services/backup_service.dart:60-77`
```dart
for (final file in archive.files) {
  final outputPath = p.join(appDir.path, file.name);      // :61
  if (file.isFile) {
    final outputFile = File(outputPath);
    if (!await outputFile.parent.exists()) {
      await outputFile.parent.create(recursive: true);
    }
    await outputFile.writeAsBytes(file.content as List<int>);
```
`file.name` comes straight from the archive and is never validated. A `.zip`/`.enc` backup containing `../../…` entries escapes the app documents directory and overwrites arbitrary user-writable files. The input is user-supplied (via `file_picker` in `backup_restore_page.dart:3`) and can also be downloaded from Google Drive (`:158`), so this is a realistic phishing/social-engineering path ("restore my family tree backup").
**Fix:**
```dart
final target = p.normalize(p.absolute(p.join(appDir.path, file.name)));
final root = p.normalize(p.absolute(appDir.path));
if (!p.isWithin(root, target)) throw Exception('Unsafe path in backup: ${file.name}');
```
Also cap decompressed size to defend against zip bombs.

### 4.2 HIGH — Backup encryption: AES-CBC without MAC, hardcoded salt, silent-corruption fallback
`lib/services/backup_service.dart:267-312`
```dart
List<int> _encryptBytes(List<int> input, String password) {
  final key = encrypt.Key(_deriveKey(password));
  final iv = encrypt.IV.fromSecureRandom(16);
  final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));  // :270
  ...
}
...
Uint8List _deriveKey(String password) {
  final salt = utf8.encode('vanshvriksh_backup_salt');                               // :304
  final derivator = pc.KeyDerivator('SHA-256/HMAC/PBKDF2');
  derivator.init(pc.Pbkdf2Parameters(Uint8List.fromList(salt), 100000, 32));
```
Problems, in order of impact:
1. **No authentication tag** (`AESMode.cbc`, no HMAC). Ciphertext is malleable; the *only* wrong-password detector is PKCS#7 padding (`:272-275`), which a random wrong key has a ~1/256 chance of passing, and the field is not `try/catch`-verified against the plaintext. On a false positive the garbage is written over the live DB by `restoreBackup` (`:60-77`) — undetectable data destruction.
2. **The legacy fallback swallows the real error** (`:278-296`): `catch (e) { final legacyKey = ...; return encrypter.decryptBytes(...); }` — a genuine corruption in a new-format backup is retried with the legacy key and any resulting garbage is returned as if valid.
3. **Static, hardcoded salt** shared by all installs — defeats the purpose of a salt (cross-install rainbow tables, no per-backup uniqueness). The IV is random and prefixed (`:272`), which is the one thing done right.
4. **PBKDF2 with 100 000 iterations on the UI isolate** (`:302-308`) blocks frames for a noticeable time on large archives.
**Fix:** use AES-GCM (`AESMode.gcm`) with a 16-byte random salt **stored in the file header** (`[magic | salt | iv | tag | ciphertext]`), verify the tag before any extraction, remove the silent legacy fallback (or gate it behind an explicit "legacy backup" flag with a warning), and run KDF+encryption in `Isolate.run`.

### 4.3 MEDIUM — Restoring over an open SQLite database
`restoreBackup` (`backup_service.dart:52-77`) writes `vanshvriksh.db` in place while drift has the file open (`lib/data/providers/database_provider.dart`, `app_database_open_connection.dart`) and never closes/reopens it. Even after a successful restore the running app keeps the old pages/cache; on Windows the write may simply fail with a sharing violation.
**Fix:** close the drift connection (or write to a temp file, close, swap, then restart/reopen), and force a state reset + `ref.invalidate` after restore.

### 4.4 MEDIUM — Google Sign-In/Drive has no OAuth configuration in-repo and the code knows it
`lib/services/backup_service.dart:79-84`
```dart
final googleSignIn = GoogleSignIn(scopes: [drive.DriveApi.driveFileScope]);
```
- No `android/app/google-services.json` and no `ios/Runner/GoogleService-Info.plist` exist anywhere in the tree (recursive search returned nothing).
- `build.gradle.kts` has no `com.google.gms.google-services` plugin; the release build is debug-signed (§3.5), so no valid SHA-1 is registered.
- `backup_service.dart:257-263` contains a hand-written error mapping for exactly this situation: `if (code.contains('sign_in_failed') || message.contains('E0.d: 10')) { return 'Google sign-in failed because the Android OAuth setup is incomplete. Check the package name, SHA-1 fingerprint, and Google Cloud OAuth client for this app.'; }`
- `google_sign_in ^6.2.2` is v6 (superseded by v7) and has no desktop support, while `macos/`+`windows/` are present.
**Impact:** the entire "cloud backup" story fails at runtime with a developer-facing message. `google_sign_in` and `googleapis` are otherwise unused (grep: only `backup_service.dart`).
**Fix:** commit the OAuth client config (or move to a `clientId`/`serverClientId` constant + documented setup), migrate to `google_sign_in` v7, and gate the Drive buttons behind a capability check so users don't hit the dead path. If Drive backup is out of scope, drop both dependencies.

### 4.5 LOW — No secrets found in code or config
Grep for `api[_-]?key|secret|token|clientId|privateKey` across `lib/`, `android/app/`, `ios/`, `web/`, `macos/Runner/`, `windows/runner/`, `linux/runner/` produced only one false positive (`person_form_page.dart:74` `int _birthPlaceSearchToken = 0;`, a debounce token). No credentials committed. `.gitignore` covers `*.iml`, `.idea/`, `build/`, but **not** `android/local.properties` (present in the tree) — it holds local SDK paths (no secrets), still worth ignoring.

### 4.6 LOW — Unencrypted local storage of personal data (documented as a feature)
`settings_page.dart:1105-1125` tells the user "Your family tree data is stored locally on your device." The DB and photos are plain files in the app documents dir (`backup_service.dart:17-19`). Appropriate for a local-first app; note that "Encrypt Backup" is the only at-rest protection and it has the weaknesses in §4.2. No `flutter_secure_storage`/SQLCipher.

### 4.7 LOW — Remote third-party image in a shipped (dead) page
`lib/features/people/people_page.dart:62-64` — an Unsplash `NetworkImage`. It only loads if the dead page is ever routed (§1.3), but it is a hardcoded third-party fetch with no offline fallback.

---

## 5. Code quality

### 5.1 HIGH — No global error handling or logging anywhere
`lib/main.dart` (entire file):
```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: VanshVrikshApp()));
}
```
Grep across `lib/` for `FlutterError|runZonedGuarded|PlatformDispatcher|onError` → **zero hits**. There is:
- no `FlutterError.onError`,
- no `PlatformDispatcher.instance.onError` (so uncaught async errors are silently swallowed in release),
- no `runZonedGuarded`,
- no logging package (`logger`, `talker`, …) and no crash reporting.

The one bright spot is the app-level init guard: `vanshvriksh_app.dart:29-45` catches `ensureDefaultTree()` failure and renders a branded error card (`:62-108`) — good pattern, but `Future.microtask(_initializeApp)` (`:27`) has **no timeout**, so a hung DB init shows the splash forever.
**Fix:** `runZonedGuarded` + `FlutterError.onError` + `PlatformDispatcher.instance.onError` → a logger/crash reporter; add `.timeout(const Duration(seconds: 15))` around init with a retry action on the error card.

### 5.2 HIGH — `flutter analyze` fails at repo root; `scratch/` is not excluded
`flutter analyze` → `84 issues found`, exit code 1, all inside `scratch/new_canvas.dart` (e.g. `scratch\new_canvas.dart:7:11 - undefined_super_member`, `:60:19 - undefined_class 'Node'`). `analysis_options.yaml:10` includes only `package:flutter_lints/flutter.yaml` with no `analyzer.exclude:`.
**Impact:** the analyze gate is broken for anyone running the standard command; a stray scratch file (a half-copied `_BasicTreeCanvasState`) makes CI red forever and trains people to ignore analyzer output.
**Fix:** add
```yaml
analyzer:
  exclude:
    - scratch/**
    - build/**
```
and delete/move `scratch/new_canvas.dart`.

### 5.3 MEDIUM — `analysis_options.yaml` is untouched default (weak for this codebase)
`analysis_options.yaml:10-20` — only `include: package:flutter_lints/flutter.yaml`, all customization commented out. Given 1200+ line widgets, consider enabling: `prefer_const_constructors`, `prefer_const_literals_to_create_immutables`, `use_super_parameters`, `always_declare_return_types`, `require_trailing_commas`, `unawaited_futures`, `avoid_dynamic_calls`, `discarded_futures`, plus `analyzer.errors:` to promote `unused_import`/`dead_code` to errors.

### 5.4 Analyzer findings that must be fixed (evidence from `flutter analyze lib test`)
| File:line | Severity | Evidence |
|---|---|---|
| `lib/data/repositories/relationship_repository.dart:3` | Medium | `import 'package:rxdart/rxdart.dart';` → *"The imported package 'rxdart' isn't a dependency of the importing package"* (used at `:171` `Rx.combineLatest3`) |
| `lib/data/database/daos/relationship_dao.dart:3` | Low | unused import `core/constants/relationship_types.dart` |
| `lib/data/repositories/relationship_repository.dart:5` | Low | unused import of the same file |
| `lib/features/tree/family_tree_page.dart:1` | Low | unused import `dart:math` |
| `lib/features/tree/family_fan_chart_page.dart:8` | Low | unused import `core/widgets/person_avatar.dart` |
| `lib/features/tree/tree_providers.dart:10` | Low | unused import `core/extensions/genealogy_person_extensions.dart` |
| `lib/features/settings/settings_page.dart:1225` | Medium | `use_build_context_synchronously` (see §2.5) |
| `lib/features/integrity/integrity_check_providers.dart:111` | Medium | *dead_code* + *dead_null_aware_expression* + *unnecessary_non_null_assertion* on one line — `x!.y ?? z` where the receiver can't be null ⇒ the intended fallback is unreachable |
| `lib/features/people/people_list_page.dart:27` | Medium | same triple; unreachable fallback in the display-name builder |
| `lib/features/people/person_profile_page.dart:244` | Medium | same triple |
| `lib/features/gedcom/gedcom_parser.dart:77` | Low | `prefer_interpolation_to_compose_strings` |
| `lib/services/backup_service.dart:3` | Low | `unnecessary_import` of `dart:typed_data` |
| `lib/data/database/app_database_open_connection_web.dart:2,6` | Medium | deprecated `package:drift/web.dart`; experimental `DriftWebStorage.indexedDb` (see §3.6) |

The three "<expr> ?? <fallback>" dead-code warnings are worth a second look: they mean a defensive fallback written for a nullable value can never run, e.g. `people_list_page.dart:27` — the name-building code intended to fall back to `person.fullName` when all name parts are empty is dead, so the fallback path is untested/unreachable as written.

### 5.5 MEDIUM — `settings_page.dart` is a 1223-line monolith; the whole page rebuilds on every setting
`lib/features/settings/settings_page.dart` = 1223 lines / 55 KB, one `build` with ~25 `ref.watch` calls at the top (`:24-70`):
```dart
final fanDepthAsync = ref.watch(fanChartAncestorGenerationsProvider);
...
final selectedDefaultRootId = defaultRootAsync.value;
```
**Impact:** toggling one switch rebuilds the entire `ListView` (every card, every `DropdownButtonFormField`, the people dropdown fed by `peopleListProvider`), and the file is unreviewable.
**Fix:** split into `sections/` widgets that each `watch` only their own provider (`AppearanceSection`, `TreeDefaultsSection`, `ConnectorColorsSection`, `BackupPreferencesSection`, `AboutSection`), plus extract `_importGedcom` into a provider/controller. The same applies to `person_profile_page.dart` (1463 lines) and `person_form_page.dart` (1368 lines) — out of scope but noted.

### 5.6 HIGH — `genealogy_tree_page.dart`: providers and futures created inside `build()`, build-time mutation
`lib/app/genealogy_tree_page.dart` (a `part of 'app_router.dart'` per `app_router.dart:31` — 572 lines of feature UI living inside the router library):
```dart
33: final personAsync = StreamProvider.autoDispose(ref) => repo.watchPersonById(personId);   // inside build()
...
155: FutureBuilder<List<FamiliesV2Data>>(future: repo.getFamiliesForPerson(personId), ...
165: visitedFamilyIds.add(family.id);
...
402: FutureBuilder<List<FamiliesV2Data>>(future: widget.repo.getFamiliesForPerson(child.id), ...
452: widget.visitedFamilyIds.add(widget.family.id);        // mutation during build
457-458: return FutureBuilder<_BranchData>(future: _loadBranchData(),  // new future each build
```
Four separate defects in one page:
1. A **new `StreamProvider` instance is created on every rebuild** (`:33`) — Riverpod treats it as a different provider each time, so it re-subscribes to `watchPersonById` and can never be reused/cached.
2. `FutureBuilder(future: ...)` with an **inline future** (`:155`, `:402`, `:458`) — every rebuild (including the one caused by the provider in #1) issues fresh DB queries; the tree does N+1 queries per rebuild and can flicker back to loading.
3. `visitedFamilyIds` is a plain `Set` mutated from `build()` (`:165`, `:452`) — the recursion guard depends on widget build order, which is unspecified.
4. `if (person == null) { return ... CircularProgressIndicator(); }` (`:38-42`) — a nonexistent person id or a stream error shows an infinite spinner with no error state.
**Fix:** move `personAsync` to a top-level `StreamProvider.family`, resolve branch data in a `FutureProvider.family`, keep the visited set in local state/`ref`, and add an `.error` branch. Independently: move the page out of `app_router.dart` (no `part` needed — nothing requires the cycle) into `lib/features/genealogy/`.

### 5.7 LOW — Analysis of `lib/core/**`
Clean and minimal: `app_constants.dart` (5 constants), `relationship_types.dart` (`parentChild`, `spouse` — note `relationship_types.dart` is imported-but-unused in two files, §5.4), `id_generator.dart` (wraps `Uuid().v4()`), `empty_state.dart`, `person_avatar.dart`, `genealogy_person_extensions.dart` (`fullName`, plus `bio => biography` and `private => isPrivate` aliases that are unused). `PersonAvatar` correctly uses `Image.file` + `ClipOval` and honours `fitMode`. No `const`/key issues found; no secrets; no TODOs.

### 5.8 LOW — TODO/dead-artifact inventory
- TODOs in first-party code: `android/app/build.gradle.kts:12` (application id) and `:22` (signing). No `TODO`/`FIXME`/`HACK` left in `lib/` (the only matches are the `Todos` drift table, `lib/data/database/tables/todos_table.dart:5`, which is an unused feature table — no page, provider or repository references it).
- Dead asset: `assets/vanshvriksh_splash.png` (1.47 MB) referenced nowhere (§3.7).
- Duplicated UI: two GEDCOM blocks (§2.3), four backup-setting controls in two pages (§2.9), two shell implementations (§1.3), two splash implementations (§1.3).

### 5.9 LOW — `README.md` is the untouched template
`README.md:1-6` — "# vanshvriksh / A new Flutter project. / ## Getting Started / This project is a starting point for a Flutter application." No build instructions, no architecture map, no explanation of the `default-tree` id or the backup format. For a project with a custom DB schema, `/v2` migration-in-progress and an encrypted backup format, this is a real onboarding cost.

---

## 6. Tests

### 6.1 What exists (running result: 9 tests, all pass)
| File | Tests | Coverage |
|---|---|---|
| `test/features/duplicates/merge_test.dart` | 5 | `GenealogyRepository.mergePeople`: soft-delete + field merge, source preference, parent-child re-pointing, spouse-family re-pointing, self-merge rejection. Uses `AppDatabase.forTesting(NativeDatabase.memory())` — good pattern. |
| `test/features/gedcom/gedcom_importer_test.dart` | 1 | persons + families imported from 11 GEDCOM lines. |
| `test/features/gedcom/gedcom_parser_test.dart` | 2 | basic INDI record; CONC/CONT handling. |
| `test/widget_test.dart` | 1 | see 6.2. |

### 6.2 MEDIUM — `widget_test.dart` does not test what its name claims
`test/widget_test.dart:8-14`
```dart
testWidgets('renders the VanshVriksh dashboard shell', (WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: VanshVrikshApp()));
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```
The name promises the dashboard shell; the assertion only proves the **loading frame** rendered. There is no second `pump()`, so `_initializeApp`'s eventual `setState` (success or the `catch` at `vanshvriksh_app.dart:38-44`) is never observed. `SharedPreferences` is not mocked, `path_provider` is not stubbed (drift's native connection cannot open in the test VM), and nothing asserts the router, the shell or any page.
**Impact:** routing regressions of the kind in §1.1/§1.3 are invisible to CI; the test would keep passing if `app_router.dart` were replaced with an empty router. It is *not* the default counter template (that was already rewritten) but it is equally vacuous.
**Fix:** mock `SharedPreferences.setMockInitialValues({})`, register a fake DB (`AppDatabase.forTesting(NativeDatabase.memory())` via a provider override), `pumpAndSettle`, then assert `find.byType(NavigationBar)`, `find.text('VanshVriksh')` and each of the five `NavigationDestination` labels; add a route-table test that every path string used in the codebase resolves (see 6.3).

### 6.3 Missing critical test areas
1. **Router contract test (highest value).** Static paths are hand-written in 30+ places; one typo (`/settings/backup`, §1.1) already broke a screen. A test enumerating every `path:` in `app_router.dart` and every `context.go/push` target in `lib/` and asserting each resolves via `appRouter.configuration` would have caught §1.1 and both dead-page targets (`/dashboard`, `/people/profile`).
2. **Settings persistence round-trip.** Zero tests for the 19 `AsyncNotifier` controllers in `app_settings_provider.dart` / `fan_chart_settings_provider.dart`. Use `SharedPreferences.setMockInitialValues` + `ProviderContainer` to assert each `setX` writes the documented key and each `build()` reads it back (this also documents which keys are dead per §2.2).
3. **`BackupService` encrypt/decrypt.** No test for `createBackup`/`restoreBackup`/`_encryptBytes`/`_decryptBytes` — the highest-risk code in the repo (§4.1, §4.2). At minimum: round-trip a known password, assert a wrong password fails loudly, and assert a `../` entry is rejected.
4. **`MainShellPage` index mapping + shell navigation.** `_calculateSelectedIndex` (`main_shell_page.dart:14-23`) has no test; nor does the `push`-vs-`go` duplication (§1.5).
5. **`display_formatters.dart`.** Pure functions (age calculation, hide-year behaviour, gendered/neutral labels) — trivial to unit-test, currently untested, and consumed by every list/tree view.
6. **`GedcomImporter` via `settings_page._importGedcom`.** The UI path (§2.5) is untested; only the importer core has a test.
7. **Web/desktop variance.** `app_database_open_connection_web.dart` (deprecated API, §3.6) has no test; `kIsWeb` branches are unexercised.

### 6.4 LOW — Test infrastructure gaps
No `test/helpers/` fixtures, no `mocktail`/`mockito`, no golden tests, no coverage gate. `test/` contains 4 files for ~45 `lib/features` pages. `flutter test` runs in ~2 s, so the cost of adding the tests above is low.

---

## 7. Recommended order of work

1. **Ship-blockers (minutes):** fix `/settings/backup` → `/backup` (§1.1); add `INTERNET` to the main Android manifest (§3.1); add Android/iOS location permissions (§3.2); add `com.apple.security.network.client` (§3.3); add `analyzer.exclude: scratch/**` (§5.2).
2. **Correctness/security (days):** zip-slip guard (§4.1); AES-GCM + random salt + remove the silent fallback (§4.2); close/reopen the DB on restore (§4.3); global error handling in `main.dart` (§5.1); `genealogy_tree_page.dart` provider/future refactor (§5.6).
3. **Honesty & hygiene:** delete the 5 dead pages + their dead routes (§1.3), remove or disable the three dead backup toggles (§2.2), de-duplicate the GEDCOM cards (§2.3), fix `_importGedcom` (§2.5), decide the fate of `/v2` (§1.2), fix the logo brightness bug (§2.8).
4. **Then:** split `settings_page.dart` (§5.5), add the router contract + settings + backup tests (§6), finish platform branding (§3.4-3.6), refresh `README.md` (§5.9).
