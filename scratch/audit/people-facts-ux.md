# Audit - People & Facts UX / State (VanshVriksh Flutter app)

Scope audited (read in full):
`lib/features/people/**` (person_form_page.dart, person_profile_page.dart, people_list_page.dart, people_page.dart, people_providers.dart, person_relationship_models.dart),
`lib/features/person_facts/**`, `lib/features/relationships/add_relationship_page.dart`,
`lib/features/media/**`, `lib/features/genealogy/**` (+ `lib/app/genealogy_tree_page.dart` as a `part` of the router),
plus the supporting layers needed to prove behaviour: `lib/app/app_router.dart`, `main_shell_page.dart`, `app_shell.dart`, `data/repositories/{genealogy,relationship,events,research_notes,media}_repository.dart`,
`data/database/daos/*`, `data/database/tables/*`, `app_database.dart`, `services/{image,media}_storage_service.dart`, `app_settings_provider`, `display_formatters.dart`.

No file was modified except this report.

Legend: **C**ritical / **H**igh / **M**edium / **L**ow. Every finding cites `file:line` + quoted code + impact + fix.

---

## 0. Live vs dead code paths (evidence-based)

| Path | Status | Evidence |
|---|---|---|
| `people_list_page.dart`, `person_profile_page.dart`, `person_form_page.dart`, `add_relationship_page.dart`, `person_media_gallery_page.dart`, `person_facts/*` | **LIVE** | Routes `/people`, `/people/:id`, `/people/add`, `/people/:id/edit`, `/people/:id/add-relationship`, `/people/:id/media`, `/people/:id/facts` in `app_router.dart:53-176`; bottom-nav tab 1 → `/people` (`main_shell_page.dart:26,42`). |
| `features/genealogy/**` (v2 list/form/profile/link) + `app/genealogy_tree_page.dart` | **DEAD / unreachable island** | Reachable only via `/v2/people/:id`, `/v2/tree/:id`. The only in-repo links into `/v2/*` are `genealogy_tree_page.dart:74,353,397` and `genealogy_person_profile_page.dart` itself. Nothing in `main_shell_page.dart`, `dashboard_page.dart`, `people_list_page.dart` or `settings_page.dart` links to `/v2/*` (`rg "v2/" lib` → only those 3 hits). The whole v2 cluster can only be opened by hand-typing a URL. |
| `features/people/people_page.dart` (`PeoplePage`) | **DEAD** | `rg "PeoplePage" lib` → definition only. Not imported by the router; not referenced anywhere. Its FAB targets a nonexistent route and would silently open a *profile* for the literal id `profile`: `onPressed: () => context.go('/people/profile')` (`people_page.dart:31`), matching `/people/:id`. |
| `features/shell/app_shell.dart` (`AppShell`) | **DEAD** | `rg "AppShell"` → definition only; the router uses `MainShellPage` (`app_router.dart:40`). Also navigates to `'/dashboard'` (`app_shell.dart:20`) which is **not** a registered route (the dashboard route is `/`). |
| `features/tree/tree_page.dart` (`TreePage`) | **DEAD** | `rg "TreePage"` → definition only; router uses `FamilyTreePage` (`app_router.dart:67`). |
| `RelationshipRepository.deleteRelationship` | **DEAD (never called)** | `rg "deleteRelationship" lib` → only `relationship_repository.dart:118` + a comment. |
| `PersonRelationItem.canRemove` | **DEAD (never read)** | `person_relationship_models.dart:18`. |
| `Citations` / `CitationLinks` tables | **DEAD (no code at all)** | `rg -l "citation" lib` → only `tables/citations_table.dart`, `tables/citation_links_table.dart`, `app_database.dart`. No DAO, no repository, no UI. `Todos` table likewise unused. |

Consequence: the app ships **two divergent implementations of the same feature set** and the newer one (`genealogy/*`, with `customDisplayName`, `displayNameFormat`, surname-history view, v2 tree) is unreachable while the older one silently destroys data written by the newer one (see C2).

---

## 1. BUGS

### C1 - Editing a person resets `isLiving` to `true`: deceased people come back to life (Critical)
`person_form_page.dart:633-652`:
```dart
await repository.updatePerson(
  id: existingPerson.id,
  treeId: existingPerson.treeId,
  firstName: ...,
  ...
  isPrivate: _isPrivate,
  profilePhotoPath: photoPath,
);   // no isLiving: passed
```
`genealogy_repository.dart:125,166`:
```dart
bool isLiving = true,
...
isLiving: Value(isLiving),
```
The add path does pass it (`person_form_page.dart:673: isLiving: _deathDate == null`), the edit path does **not**, so the default `true` is written on **every edit**, even for a person who has a `deathDate`.
Impact: open a deceased ancestor → Save → they are now "Living": profile pill flips to "Living", `_ageText` prints an age (`person_profile_page.dart:268`), `hideYearsForLiving` starts hiding years, the "Deceased People" filter (`people_list_page.dart:236`) and dashboard living/deceased stats (`dashboard_providers.dart:33-36`) become wrong, GEDCOM-imported ancestors included.
Fix: pass `isLiving: _deathDate == null` (or derive it inside `updatePerson` when `deathDate != null`), and make `isLiving` non-defaulted/required so callers cannot forget it.

### C2 - Editing a person silently nulls every field the form doesn't expose (Critical, data loss)
Same call (`person_form_page.dart:633-652`) passes no `occupation`, `religion`, `ethnicity`, `privacyLevel`, `displayNameFormat`, `customDisplayName`, `birthDateQualifier`, `deathDateQualifier`, `deathPlace`, `birthPlaceLat/Lng`, `deathPlaceLat/Lng`, `mergedIntoId`. The repository always writes a value:
`genealogy_repository.dart:139-166`, e.g.
```dart
occupation: Value(occupation?.trim()),
privacyLevel: Value(privacyLevel),
displayNameFormat: Value(displayNameFormat),   // default 'birth_married'
customDisplayName: Value(customDisplayName?.trim()),
birthDateQualifier: Value(birthDateQualifier?.trim()),
```
and the DAO does a full-row write: `genealogy_person_dao.dart:22-24` → `update(genealogyPersons).replace(person)`.
Impact: GEDCOM import sets exactly those columns (`gedcom_importer.dart:83-88`: `birthDateQualifier`, `deathDateQualifier`, `deathPlace`), the v2 form sets `customDisplayName`/`displayNameFormat` (`genealogy_person_form_page.dart:99-118`), the legacy migration sets `customDisplayName` (`app_database.dart:333`), and `privacyLevel`/`occupation` have no UI at all - so **one tap on Save in the live edit form erases them with no confirmation and no undo**.
Fix: read-modify-write - load the existing row and only override the fields the form owns (`copyWith`-style companion built from `existingPerson`), or make the repository parameters required and add the missing fields to the form.

### C3 - "Delete Person" fails with a FOREIGN KEY error for any connected person (Critical)
`person_profile_page.dart:220-231`:
```dart
final repository = ref.read(genealogyRepositoryProvider);
await repository.deletePerson(personId);
```
`genealogy_repository.dart:171-173` → hard delete of the row. But the schema references the person from every side table with **no ON DELETE CASCADE**: `family_children_v2.child_id` (`family_children_v2_table.dart:11-15`), `families_v2.husband_id/wife_id` (`families_v2_table.dart:7-15`), `events.person_id` (`events_table.dart:7`), `media_items.person_id` (`media_items_table.dart:9`), `research_notes.person_id` (`research_notes_table.dart:8`), and FKs are enforced on every connection: `app_database.dart` `beforeOpen` → `PRAGMA foreign_keys = ON`.
Impact: deleting anyone who has a relationship, an event, a note or media throws `SqliteException(787) FOREIGN KEY constraint failed` → the user only sees "Failed to delete person: ..." (`person_profile_page.dart:236-241`) while the dialog promised "This will delete this person profile and all family relationship links connected to this person" (line 194-198). Only fully isolated persons can be deleted. Also, no cleanup of the profile photo file is done on delete.
Fix: delete in a transaction, removing `family_children_v2` links, then orphan `families_v2` rows for this person, then events/media/notes/citation links, then the person; or declare `ON DELETE CASCADE`; and delete the photo file from disk.

### C4 - Merged (soft-deleted) people still appear in parent/child/spouse lists (High)
`relationship_dao.dart:18-33` (`getParentPersonsOfChild`) selects `genealogy_persons` by id **without** `isDeleted = false`; same in `getChildPersonsOfParent`, `getSpousePersonsOf`, `getSiblingPersonsOf`, and in the `*PersonItems` variants. `mergePeople` only soft-deletes (`genealogy_repository.dart:443-451: isDeleted: true, mergedIntoId: survivorId`).
Impact: after a merge, the duplicate keeps showing up as an extra parent/spouse/child on other people's profiles and can be tapped into a ghost profile. Fix: add `& t.isDeleted.equals(false)` (and follow `mergedIntoId`) to every such select, or filter in the repository.

### H1 - `setState()` called during build on the Edit-Person screen (High, debug-crash)
`person_form_page.dart:870` runs the loader **inside `build()`** (inside the `AsyncValue.when(data:)` callback):
```dart
_loadPersonIntoForm(person);
```
Inside it, line 118 assigns `_fullNameController.text = person.fullName;` **before** first/middle/surname are filled. That fires the listener registered at line 93 → `_handleFullNameChange()` (line 446):
```dart
final composed = _composeFullName();       // null: first/middle/birthSurname still empty
final current = _fullNameController.text.trim();
if (current.isEmpty || composed == current) { ... return; }
if (!_fullNameManuallyEdited) {
  if (mounted) { setState(() { _fullNameManuallyEdited = true; }); }   // setState during build
```
Impact: `setState() or markNeedsBuild() called during build` is thrown from `Element.markNeedsBuild` in debug/profile mode → opening *Edit Person* for any named person fails the build (ErrorWidget) and `_hasLoadedPerson` stays `false`, so the partially-loaded state retries and can fail again. In release the assert is stripped, so the bug is invisible there - exactly the kind of defect that only shows up in QA builds. Fix: do the load in `initState`/`ref.listen` (or a `didChangeDependencies` guard) instead of in `build`, and set controller text without triggering the compose listener (e.g. set `_isUpdatingFullNameProgrammatically = true` around the whole load).

### H2 - Relationship mutations don't invalidate the relation providers → stale profiles (High)
`people_providers.dart:37-41`:
```dart
final personRelationshipsProvider = StreamProvider.family<void, String>((ref, personId) {
  return repository.watchRelationshipsForPerson(personId);
});
```
`relationship_repository.dart:130-133`: `watchRelationshipsForPerson` = `_personDao.watchFamiliesForPerson(personId)` - i.e. it ticks on `families_v2` changes **only**.
Impact: "+ Add Child" on a married person adds a `family_children_v2` row to their existing family (`relationship_repository.dart:34-38` picks `families.first`) → no `families_v2` write → the parent's profile providers are never invalidated; the new child does not appear until the app is restarted. Symmetrically, adding a "Father" to X writes a family for the *father*, not for X, so X's "Parents" row stays "Not added" right after a success snackbar (`add_relationship_page.dart:100-103`). There is no `ref.invalidate` anywhere in this feature (`rg "ref.invalidate" lib` → only duplicates/dashboard pages).
Fix: make the tick stream watch both tables (`Rx.combineLatest([watchFamiliesForPerson, watchChildLinksForPerson])`), or explicitly `ref.invalidate(parentItemsProvider(...), ...)` after each mutation; also invalidate `peopleListProvider`/`personByIdProvider` where relevant.

### H3 - Relationships cannot be removed at all (High, feature gap + dead code)
`PersonRelationItem.canRemove` (`person_relationship_models.dart:16-18`) and `RelationshipRepository.deleteRelationship` (`relationship_repository.dart:118`) exist but are never called by any widget. The profile rows (`person_profile_page.dart:915-1005`) only render pills that navigate.
Impact: a mis-added spouse/parent/child can only be fixed by deleting a person (which currently fails, C3) or by editing the DB. Fix: add a long-press/overflow "Remove relation" on each relation pill calling `deleteRelationship(item.relationshipId)` (disable when `!canRemove`), then invalidate the relation providers.

### H4 - Filter chips push a new page every tap (High)
`people_list_page.dart:90-97`:
```dart
final target = filter == PersonListFilter.all ? '/people' : '/people?filter=${filter.queryValue}';
context.push(target);
```
Impact: every chip tap (and every dashboard shortcut, `dashboard_page.dart:259-280`) pushes another `/people` page, each with a Back button; the back stack becomes `All → With photos → Living → ...`. Fix: `context.go(target)` (or keep the filter in local state and drop the query-string round-trip).

### H5 - Fact form swallows all errors (High, no error state)
`person_fact_form_page.dart:91-152`:
```dart
try {
  ...
} finally {
  if (mounted) setState(() => _isSaving = false);
}
```
There is **no `catch`**: validation errors, DB failures and duplicate-key errors escape as an unhandled exception, the spinner just stops, nothing is shown, and on success the page silently `context.go`s back. Fix: add a `catch (e)` with a SnackBar and keep the form open.

### H6 - GEDCOM-imported deceased people are marked living (High)
`gedcom_importer.dart:76-90` sets `deathDate`/`deathPlace` but never sets `isLiving`; the column defaults to `true` (`genealogy_persons_table.dart:30`). Import is live (`settings_page.dart:114,1220-1226`).
Impact: after importing a GEDCOM file, every ancestor with a `DEAT` tag still counts as living → wrong dashboard stats, wrong "Deceased" filter, ages printed for dead people. Fix: `isLiving: Value(deatDate.date == null)` in the imported companion.

### H7 - v2 `StreamProvider.autoDispose(...)` created inside `build` (High, leak)
`genealogy_person_profile_page.dart:40-42`:
```dart
final personAsync = StreamProvider.autoDispose((ref) => repo.watchPersonById(personId));
final historyAsync = StreamProvider.autoDispose((ref) => repo.watchSurnameHistory(personId));
final familiesAsync = StreamProvider.autoDispose((ref) => repo.watchFamiliesForPerson(personId));
```
and `genealogy_tree_page.dart:33-35`. Declaring providers inside a widget `build` creates a brand-new provider instance on every rebuild, so each rebuild opens a new DB subscription and the previous one leaks/keeps a container entry.
Impact: unbounded provider growth + flicker while the v2 pages are used. Fix: top-level `StreamProvider.autoDispose.family(..., (ref, id) => ...)` providers (as done for v1 in `people_providers.dart`).

### H8 - "Add Father/Mother" ignores the linked person's gender (High, consistency)
`add_relationship_page.dart:66-73`:
```dart
case 'father':
case 'mother':
  await repository.addParentChildRelationship(
    treeId: AppConstants.defaultTreeId,
    parentId: relatedPersonId,
    childId: currentPerson.id,
  );
  break;
```
Both labels take the identical path; the selected person's `gender` is never validated. The profile then relabels them by gender anyway (`person_profile_page.dart:1000-1004`).
Impact: a female person can be recorded as "Father"; data integrity is silently broken and the tree renderer prints "Father". Fix: reject/repair when `_selectedRelation == 'father' && person.gender != 'male'`, or offer gender-neutral "Add Parent" and derive the label from the person's gender.

### M1 - Missing `mounted` checks after `await` (Medium)
- `person_form_page.dart:532-544` `_pickProfilePhoto`: `await picker.pickImage(...)` → `setState(...)` with no `mounted` check.
- `person_form_page.dart:558-568` `_pickBirthDate` / `575-585` `_pickDeathDate`: `await showDatePicker(...)` → `setState(...)` with no `mounted` check.
- `person_media_gallery_page.dart:28-44` `_addMedia`: `await FilePicker...` → `setState(() { _isWorking = true; })` with no `mounted` check.
Impact: "setState() called after dispose()" when the route is popped while the picker/dialog is open (backgrounded app + task-kill recovery, deep-link back, double Back). Fix: `if (!mounted) return;` immediately after each await before touching state.

### M2 - Un-debounced geocoding: one HTTP request per keystroke (Medium)
`person_form_page.dart:1129-1131`:
```dart
onChanged: (value) { unawaited(_searchBirthPlaces(value)); },
```
`_searchRemotePlaces` calls `nominatim.openstreetmap.org/search` (line 208-216) on every keystroke. The token guard only discards stale *results*, it does not prevent the requests. Nominatim's usage policy forbids this rate; the app can be blocked and the UI issues several parallel requests.
Impact: wasted bandwidth, possible 403/rate-limit, flicker. Fix: 300-500 ms `Timer` debounce (there is currently no debounce anywhere in the app: `rg "debounce|Timer\(" lib` → only `splash_page.dart:23`), plus a minimum query length.

### M3 - Event/note deletes have no error handling and use `ref` after an async gap (Medium)
`person_facts_page.dart:360-362`:
```dart
final repository = ref.read(eventsRepositoryProvider);
await repository.deleteEvent(eventId);
```
(and `:396-398` for notes). No `try/catch` → a DB failure is an unhandled exception with no feedback; `ref.read` after `await showDialog` can also throw if the page was disposed while the dialog was open. Fix: capture the repository before the dialog, wrap the delete, and show an error SnackBar on failure.

### M4 - Editing an event wipes its coordinates (Medium, data loss)
`person_fact_form_page.dart:99-110` calls `updateEvent(...)` without `latitude`/`longitude`, but `events_repository.dart:66-84` writes `latitude: Value(latitude)` from its parameters (null default) into a full-row companion (`events_dao.dart:19-21` → `replace`). Any lat/lng stored on the event (geocoding/import/future features - the column exists for it) is nulled on every edit. Fix: pass through the loaded event's values.

### M5 - Hard-coded `dd-MM-yyyy` in facts/media ignores the user's date setting (Medium)
`person_fact_form_page.dart:172-177` (`_formatDate`) and `person_media_gallery_page.dart:306-312` (`_formatDate`) both build `'$day-$month-$year'`, while the rest of the app honours `dateDisplayFormatProvider` via `display_formatters.dart:18-23`. Impact: a user who chose "MMM yyyy" or "year only" sees a different format on the facts page and while editing a fact - and an unparseable display string can be written back (`_parseDisplayDate` only understands `dd-MM-yyyy`, `person_fact_form_page.dart:180-192`). Fix: route through `formatDateForDisplay` and make `dateSort`/`dateDisplay` the single source of truth.

### M6 - Silent `catch` blocks hide real failures (Medium)
`person_form_page.dart:182-185` (`} catch (_) { // Keep the local suggestions... }`), `:748-752` and `:796-800` (`} catch (_) { // Ignore duplicates ... }`). In the relationship cases the catch swallows *every* error (FK failures, DB errors), not just the intended duplicate case - the app reports success while links are missing. Fix: narrow the expected failure (check existence first) and surface unexpected errors.

### M7 - Post-save / post-delete navigation is inconsistent and can throw (Medium)
- Edit save: `context.go('/people/${widget.personId}')` (`person_form_page.dart:837`) replaces the stack, so the profile has no back entry.
- Profile delete on a `go`-built stack: `context.pop()` (`person_profile_page.dart:231`) - with no previous route go_router raises "There is nothing to pop"; the same `pop()` is used from `add_relationship_page.dart:109,396`.
- Fact save: `context.go('/people/$id/facts')` (`person_fact_form_page.dart:145`) discards the previous page (`context.push`ed from the profile), so Back from the facts page goes somewhere unexpected.
Fix: pick one convention (`go` for canonical destinations, `pop` only for pushed sheets/dialogs) and use `context.pop()` only when `context.canPop()`.

### M8 - Person creation isn't atomic with the photo (Medium)
`person_form_page.dart:684-720`: `addPerson(...)` then, if a photo was picked, `getPersonById` + a full `updatePerson(...)`. If the second write fails, the catch reports "Failed to save person" although the person now exists → the user retries and creates a duplicate. Fix: insert with `profilePhotoPath` in one write (save the file first, using the freshly generated id), or reconcile in the catch.

### M9 - `_applyRelationshipPrefill` can run concurrently and after dispose (Medium)
`person_form_page.dart:902-905`:
```dart
data: (linkedPerson) {
  if (linkedPerson != null) { unawaited(_applyRelationshipPrefill(linkedPerson)); }
```
The `_hasAppliedRelationshipPrefill` flag is only set at the *end* of the async body (line 382), and the method `ref.read`s providers and mutates controllers after `await`s (`:269-300`) without `mounted`/flag re-checks. Two rebuilds before completion start two prefill runs that race on the same controllers. Fix: set the flag at entry (before the first await) and bail out if unmounted.

### M10 - No unsaved-changes guard (Medium)
Neither `person_form_page.dart` nor `person_fact_form_page.dart` uses `PopScope`; the only `PopScope` in the app is the shell's (`main_shell_page.dart:57`). Back / gesture / Cancel (`person_form_page.dart:1219-1224`, `person_fact_form_page.dart:305-309`) discards every typed field without warning. Fix: `PopScope(canPop: false, onPopInvokedWithResult: ...)` when a controller is dirty or a date/photo changed, with a confirm dialog.

### L1 - State mutated during build (Low)
`people_list_page.dart:40-42`:
```dart
final nextFilter = PersonListFilter.fromQuery(uri.queryParameters['filter']);
if (nextFilter != _filter) { _filter = nextFilter; }
```
and `person_form_page.dart:1276` (`_selectedSiblingParentId = parents.first.id;` in `_relationshipSiblingNotice`). Both write state without `setState` during build. It works only because the value is read later in the same build; it is fragile and un-analysable by the linter. Fix: move to `didChangeDependencies` / `updateShouldNotify`-style logic or an explicit provider.

### L2 - Dead leftovers (Low)
- `person_form_page.dart:60,102,129` `_lastNameController`: no UI field, is never saved (the form writes `_birthSurnameController.text` for both `lastName` and `birthSurname`), yet is created and disposed.
- `person_profile_page.dart:1306-1310` `_RelationAction.son` / `.daughter` are never constructed; only mapped in switches (`_showRelationChoiceSheet`).
- `person_profile_page.dart:1314-1320`: `_RelationAction.sibling => 'child'` in the `relationKind` switch is unreachable (siblings are handled in the dedicated branch).

### L3 - `replace()` can resurrect a deleted row (Low)
`genealogy_person_dao.dart:22-24` uses `update(...).replace(companion)`, which is an upsert. An in-flight Save on a person deleted in another view can re-insert them. Fix: `write()` + `if (updated == 0) throw`.

---

## 2. VALIDATION GAPS

| # | Gap | Evidence | Impact / fix |
|---|---|---|---|
| V1 | **First name is not validated** while "Full Name *" is. Saving with the full-name override only stores `Unknown`. | `person_form_page.dart:1035-1039` (only the full-name field has a validator), `:632` `firstName: _firstNameController.text.trim().isEmpty ? 'Unknown' : ...` | "John Doe" typed only into *Full Name* produces a person whose stored name is `Unknown` and whose display name comes from an inconsistent source. Fix: require first name, or write the composed/overridden full name back into the structured parts. |
| V2 | **No date plausibility beyond death ≥ birth.** No max-age, no "death after birth of children", no century sanity, `firstDate: DateTime(1800)` in every picker. | `person_form_page.dart:587-591` (`if (_deathDate!.isBefore(_birthDate!))`), `:554-556`/`:569-571` (`firstDate: DateTime(1800)`), `person_fact_form_page.dart:196-200` | Birth 1800-..., age 400, "born 2024 / died 1900" after re-editing only one side are all accepted (the check only runs at save and only compares the two values). Fix: validate at pick time, warn above e.g. 125 years, allow pre-1800 (pre-1500) years for genealogy. |
| V3 | **No relationship-age validation**: a parent may be younger than the child; a spouse may be 5 years old. | `add_relationship_page.dart:66-97`, `person_form_page.dart:723-806` - only self-relationship and duplicate checks exist (`add_relationship_page.dart:56-63`) | Fix: compare dates before linking and warn/confirm. |
| V4 | **Gender/relationship mismatch allowed** (see H8) and the "Mother/Father" labels are derived from the target's gender everywhere else. | `add_relationship_page.dart:66-67`, `person_profile_page.dart:1000-1004` | Fix: validate or auto-set gender. |
| V5 | **Married surname can be saved for a non-female person.** The field is only *rendered* for `_gender == 'female'` (`person_form_page.dart:1012-1025`) but is saved unconditionally (`:648`). | `marriedSurname: _emptyToNull(_marriedSurnameController.text)` | Type a married surname, then switch gender to male → hidden text is still persisted. Fix: null it when `_gender != 'female'` (as the load path already does, `:138-143`). |
| V6 | **Duplicate/spouse-link feedback is wrong**: both `addParentChildRelationship` and `addSpouseRelationship` early-return when the link exists (`relationship_repository.dart:46-48`, `:84-88`) yet the UI always says "Relationship added successfully". | `add_relationship_page.dart:100-103`, `person_form_page.dart:746-756` | A no-op is reported as success, so the user believes a change happened (which compounds H2, since nothing changed at all). Fix: return a boolean/enum from the repository and report accordingly. |
| V7 | **No uniqueness guard on names**: two identical people can be created freely (only the separate duplicates page warns later). | `person_form_page.dart:659-680` (no pre-check) | Fix: warn on an exact match of first+birth surname+birth year before insert. |
| V8 | **Photo handling gaps**: no camera source, no size/format validation beyond `imageQuality/maxWidth` (`person_form_page.dart:534-537`), the raw exception is shown on failure, and no `errorBuilder` exists for a missing file (see M-A11). | `person_form_page.dart:534-537`, `person_avatar.dart:44-52`, `person_form_page.dart:1414-1418` (`CircleAvatar(backgroundImage: FileImage(File(photoPath!)))`) | Fix: validate the extension, add `errorBuilder`/`onBackgroundImageError` fallback to initials, offer the camera. |
| V9 | **Adoption / foster / step are impossible**: `relationshipType` is hard-coded `'biological'` in both write paths even though the column and `paternalRelationship`/`maternalRelationship` exist. | `relationship_repository.dart:59-63`, `genealogy_link_family_page.dart:88-93`, `family_children_v2_table.dart:16-20` | No UI, no model support. Fix: expose a relationship-type selector when adding a child. |

---

## 3. UX / FEATURE COMPLETENESS (vs. what a genealogy app needs)

| Feature | Status | Evidence |
|---|---|---|
| Add person | ✅ (many entry points: dashboard, list FAB, profile sheets) | `people_list_page.dart:191-196`, `person_profile_page.dart:1321-1490` |
| Edit person | ⚠️ works but destroys data (C1, C2) and crashes in debug (H1) | as above |
| Delete person | ❌ fails for connected people; dialog lies about cascade; no photo cleanup | C3 |
| Merge duplicates | ✅ exists but in a separate flow | `duplicate_detection_page.dart`, routed at `/people/duplicates`, linked from `people_list_page.dart:59-63` |
| Parent / spouse / child links | ⚠️ add only, wrong-family risk, no removal | H2, H3, M-B4 |
| Sibling | ⚠️ only if **both** parents exist in the profile UI, while the add-form itself supports single-parent siblings | `person_profile_page.dart:1297` (`canAddSibling = hasFather && hasMother`) vs `person_form_page.dart:1256-1290` |
| Adoption / foster / step | ❌ | V9 |
| Life events | ✅ add/edit/delete + filters | `person_facts_page.dart` |
| Sources / citations | ❌ tables only, zero code | §0 |
| Notes | ⚠️ `bio` shown, `notes` (private) never displayed anywhere | `person_profile_page.dart:171-176` + `:700-711` |
| Media gallery | ⚠️ add/open/delete only; no captions/titles editing, no dates, no tags, not surfaced on the profile card | `person_media_gallery_page.dart`, `media_repository.dart:28-33` (`description` never set) |
| Search | ✅ but client-side over the full tree, substring on a few fields, no accent/word-prefix handling | `people_list_page.dart:118-137` |
| Filter | ✅ living/deceased/with photos/missing photos | `people_list_page.dart:222-243` |
| Sort | ❌ fixed to `firstName ASC` from the DAO; no UI | `genealogy_person_dao.dart:60-64` |
| Bulk actions (delete/mark/export) | ❌ none | - |
| Unsaved-changes guard | ❌ | M10 |
| Undo / soft delete for people | ❌ hard delete (and failing) | C3 |

Additional UX defects:
- **M-B1** The centre FAB of the profile dock shows a "+" (`Icons.add`) but opens **Edit** (`person_profile_page.dart:656-680`) - a misleading affordance.
- **M-B2** The Notes card has a permanently disabled button: `OutlinedButton(onPressed: null, child: const Text('+ Add'))` (`person_profile_page.dart:703`) - dead control in the live UI.
- **M-B3** The relation picker in "Add Relationship" is a plain dropdown listing **every person in the tree** (`add_relationship_page.dart:299-317`), with no search, no type-ahead, and no exclusion of already-related people - unusable beyond a few dozen people and an easy way to create duplicate links.
- **M-B4** Adding a child attaches them to `families.first` (`relationship_repository.dart:34-38`) and `genealogy_link_family_page.dart:84-93` creates a **new** single-parent family every time - with several marriages/partnerships the child can land in the wrong family (so they appear as the child of the wrong spouse).
- **M-B5** Deleting a person doesn't remove their media/photo files from disk (`person_profile_page.dart:220-231`).
- **M-B6** The facts list is built with a `Column` of all children (`person_facts_page.dart:711-713`) instead of a lazy list - every fact card is built even when off-screen.

---

## 4. STATE-MANAGEMENT QUALITY (Riverpod)

1. **Invalidation is inferential, not explicit.** Relation providers piggyback on `watchRelationshipsForPerson` (families table only) → H2. No `ref.invalidate` in the whole people/relationship feature.
2. **Duplicate subscriptions.** `person_profile_page.dart:22-25` and `:881-884` watch the same four `*ItemsProvider`s in the parent and in the card, so any relation change rebuilds the entire profile page, and each family stream is opened several times per page.
3. **Providers created in build** in the v2 pages (H7) - a hard Riverpod anti-pattern.
4. **`ref.read` inside build** for changeable settings: `add_relationship_page.dart:127,161` (`relationshipLabelStyleProvider`) - the help text/labels never react to changing the setting.
5. **`AsyncValue` handling is inconsistent**: `.when(loading/error/data)` in the list/form (good), but `.asData?.value ?? ...` silently degrades to an empty state in `person_profile_page.dart:1025` (`_relationSubtitle`, `_relationDetails`) - a stream *error* is rendered as "Not added", hiding real failures; `genealogy_person_profile_page.dart:44-52` shows an infinite spinner on error/null.
6. **`.value ?? default` for settings** in every page (`people_list_page.dart:47-53`, `person_profile_page.dart:26-35`) causes a one-frame flash of default formatting/`cover` fit before the async setting arrives.
7. **No caching policy / autoDispose** on the v1 providers: `peopleListProvider` and all `.family` providers stay alive for the app's lifetime (fine for a local DB, but it means the stale-profile problem in H2 can never be cured by page rebuilds).
8. **Consistency between list / profile / tree**: all three read `peopleListProvider` (`family_tree_page.dart:57`, `family_fan_chart_page.dart:54`, `people_list_page.dart:45`) so person rows stay consistent; the gap is relation data (H2) and `isLiving` (C1).

---

## 5. ACCESSIBILITY / RESPONSIVENESS

| # | Finding | Evidence | Fix |
|---|---|---|---|
| A1 | Fixed tile aspect ratio in a grid that must fit 2 lines of text → overflow at large text scale. | `person_profile_page.dart:568` `childAspectRatio: 3.15` with `maxLines: 2` (`:642-650`) | Use `SliverGridDelegateWithMaxCrossAxisExtent` + `mainAxisExtent`, or a `Wrap`/`Column` that grows with `MediaQuery.textScalerOf(context)`. |
| A2 | 9.5 px dock labels (below the 12 sp minimum) truncated to `SizedBox(width: 52)`. | `person_profile_page.dart:838-847` | Use at least `textTheme.labelSmall`, allow 2 lines, or switch to a `NavigationBar`/`BottomAppBar` with standard metrics. |
| A3 | Hard-coded colours ignore the theme (dark mode contrast): `Colors.grey.shade700` and `Colors.grey` on `surface`. | `person_profile_page.dart:1138`, `:710`, plus the hard-coded `Colors.green.shade200` badge (`:342`) | Use `colorScheme.onSurfaceVariant`/`outline`. |
| A4 | Bottom action dock is `Positioned` over the list with a hard-coded `EdgeInsets.fromLTRB(14, 12, 14, 150)` compensation; at large text scale the dock grows and covers the last cards. | `person_profile_page.dart:173-181` + `:1188` | Make the dock part of the scroll view (or use `Scaffold.bottomNavigationBar`) and let the list pad itself via a `SliverPadding`. |
| A5 | No explicit semantic labels beyond tooltips (`IconButton` has tooltips in most places - good), but the relation pills are icon+text inside `InkWell` returning a single string (`'${detail.label} : ${detail.displayName}'`) with no `Semantics(label: ...)`; the media rows expose no action semantics beyond the popup menu. | `person_profile_page.dart:1150-1205`, `person_media_gallery_page.dart:194-230` | Add `Semantics(button: true, label: ...)`. |
| A6 | No `textScaler` clamp; with the OS set to 200 % several rows (`_MiniMeta`, `_DockAction`, `_FamilyRow` compact) will overflow. | `person_profile_page.dart:390-430, 1120-1145` | Test at 1.5×/2× and prefer intrinsic sizing over fixed heights. |
| A7 | The dock's middle FAB and the dock itself have no visible focus/keyboard affordance (desktop/web builds). | `person_profile_page.dart:640-690` | Use `FocusableActionDetector`/standard Material widgets. |

---

## 6. Duplicated / legacy code paths (summary)

1. Two full person stacks: v1 (live) and v2 (`features/genealogy/**`, dead island) - v2 is the only code that writes `customDisplayName`/`displayNameFormat`, and v1 wipes them on save (C2). v2 also has the only surname-history/family-link browser and its own tree page.
2. Three copies of `_displayName` (`people_list_page.dart:26-40`, `person_profile_page.dart:255-275`, `genealogy_people_list_page.dart:27-44`) with **different surname rules** (v2 prefers `marriedSurname` unconditionally; v1 only for `gender == 'female'`, `person_profile_page.dart:277-289`) → the same person can be displayed with different surnames on different screens.
3. Confirmed dead widgets: `PeoplePage`, `AppShell`, `TreePage` (see §0).
4. Confirmed dead API: `deleteRelationship`, `canRemove`, `_RelationAction.son/daughter`, `_lastNameController`, `Citation*` tables, `Todos` table, `relationDisplayLabel` (only used by dead/other pages - no v1 caller).
5. Two relationship write paths (`RelationshipRepository` vs direct `repo.createFamily/addChildToFamily` in the v2 pages) with different correctness (v2 never reuses an existing family for a child → duplicate families; `genealogy_link_family_page.dart:84-93`).
6. Latent: `getParentPersonItemsOfChild` returns the **same** `family_children_v2` link id for both parents of a family (`relationship_dao.dart:145-155`), so the unused `deleteRelationship(link.id)` would delete the whole parent-pair link if a removal UI is ever added - fix the id semantics before wiring H3.

---

## 7. Suggested fix order

1. C1 + C2 (data destruction on every edit) - smallest diff, highest value.
2. C3 (delete person) - transaction + cascade.
3. H1 (build-time load), H2 (invalidate relation providers), H3 (remove relation UI).
4. H5/H6/M3/M4 (error handling + GEDCOM `isLiving`).
5. H4/M7 (navigation), M1/M2 (mounted + debounce), then the validation table (V1-V5) and the dead-code purge (§0/§6).
