# VanshVriksh — Phase 0 Baseline & Characterization Report

**Scope of this phase:** establish a reproducible baseline only. No production code, schema,
migration version, or existing test was modified. Only tests and documentation were added.

---

## Baseline

| Item | Value |
|---|---|
| Repository | `https://github.com/ketandholakia/VanshVriksh` |
| Branch | `main` |
| HEAD at baseline | `0e583ba0f3bcc71920abae3b5d97fe6bc36bfc73` (`docs: data-layer audit v2 with executed verification`) |
| Flutter | 3.44.0 • channel stable • framework revision `559ffa3f75` (2026-05-15) |
| Engine | `fcf463a2242790d1fdcd9d044f533080f5022e18` |
| Dart | 3.12.0 (stable) |
| Test framework | `flutter_test` (dev dependency). No `integration_test`, no `mockito`/`mocktail`, no golden utilities |
| Test command | `flutter test` |
| Characterization subset command | `flutter test test/data/characterization` |
| Platform | Windows 10.0.26100 (x64), Node not involved; database tested via `NativeDatabase` |

### Test counts

| Run | Total | Passed | Failed | Skipped |
|---|---|---|---|---|
| **Pre-existing suite only** (before this phase) | **9** | 9 | 0 | 0 |
| **Full suite after this phase** | **39** | 39 | 0 | 0 |
| New characterization subset | 30 | 30 | 0 | 0 |

Pre-existing tests:

```
test/widget_test.dart                                  1 test
test/features/duplicates/merge_test.dart               5 tests
test/features/gedcom/gedcom_importer_test.dart         1 test
test/features/gedcom/gedcom_parser_test.dart           2 tests
                                                       ─────────
                                                       9 tests
```

### Analyzer result

`flutter analyze --no-pub` → **84 issues** (exit code 1).

| Location | Issues | Notes |
|---|---|---|
| `lib/` | 20 | **0 errors** — 8 warnings, 12 infos (unused imports, deprecated drift web API, `rxdart` not declared, dead code) |
| `test/` | **0** | the added characterization tests are lint-clean |
| `scratch/new_canvas.dart` | 64 | includes **all ~59 hard errors**; this single abandoned file is what makes `flutter analyze` exit non-zero at the repo root |

The baseline is unchanged from before this phase: 84 issues, and **0 issues introduced** by the
work in this phase.

### Build status

`flutter build web --debug` → **success** (`√ Built build\web`), 138.1 s to compile `lib\main.dart`.

Informational only: the wasm dry-run reports `dart:ffi unsupported without --enable-experimental-ffi`
for `package:sqlite3` / `package:ffi`. That is expected — the drift/sqlite3 native path cannot
target wasm, so the web build falls back to the JS target with the deprecated drift web backend.
No Android/iOS toolchain check was performed (not required for a baseline).

---

## Relevant existing tests

Coverage of the findings under remediation, before this phase:

| Finding | Existing coverage |
|---|---|
| **C1** `GenealogyPersonDao.updatePerson()` | **None.** No test anywhere calls `updatePerson`. `merge_test.dart` only uses `addPerson`, `mergePeople` and the relationship helpers |
| **C2** person deletion / FK dependencies | **None.** `deletePerson` is never called by any test |
| **C3** relationship deletion | **None.** `deleteRelationship` is never called by any test |
| **H1** legacy `spouse` migration | **None.** No test opens a database with a pre-existing schema version |
| **H2** ambiguous `getSingleOrNull()` in migration | **None** |
| **H3** fresh vs migrated schema/index divergence | **None.** Every test uses `AppDatabase.forTesting(NativeDatabase.memory())`, which only ever exercises `onCreate`/`createAll()` |
| **H4** `mergePeople` transaction safety | **Partial.** 5 tests in `merge_test.dart` cover happy paths (field merge, `secondary` source preference, parent-child reassignment, spouse reassignment, self-merge rejection) plus `getMergePreview` counts. No rollback, no injected-failure, no `UNIQUE(family_id, child_id)` collision path |
| **H5** tree deletion | **None** |
| Related: person creation | Indirect — every test creates people through `GenealogyRepository.addPerson` |
| Related: family creation | Indirect — `merge_test.dart` exercises `addSpouseRelationship` and `addParentChildRelationship` |
| Related: GEDCOM import | 3 tests: `GedcomParser` (basic INDI, CONC/CONT) and `GedcomImporter` (2 persons + 1 family) |
| Related: app shell | 1 widget smoke test asserting the startup `CircularProgressIndicator` |

**Test organization:** feature-mirrored directories under `test/` (`test/features/<feature>/`).
There is no `test/helpers/`, no fixtures directory, and no shared database-test harness — each
database test constructs its own `AppDatabase.forTesting(NativeDatabase.memory())` in `setUp`.
There is also no CI configuration in the repository, so nothing runs these tests automatically.

---

## Missing characterization tests (added)

Four files added under `test/data/characterization/`, all explicitly commented as documenting
**current, incorrect** behaviour that will need updating when the fixes land.

### 1. `person_write_characterization_test.dart` — C1, C1b, C2 (8 tests)
- update of an existing person throws `InvalidDataException` mentioning `uuid`
- the failed update leaves the stored person completely unchanged (including `updatedAt`)
- **C1b:** `replace()` with an otherwise-valid companion resets every defaulted column the caller
  omitted — demonstrates `is_living` → `true`, `display_name_format` → `birth_married`, `version` → `1`
- delete of a person who is a family partner fails with an FK violation
- delete of a person who is a child fails with an FK violation
- a failed delete removes nothing (no partial cascade)
- delete of an isolated person succeeds
- delete of a person who only has an `events` row also fails

### 2. `relationship_delete_characterization_test.dart` — C3 (6 tests)
- deleting the family of a couple **with children** fails with an FK violation
- the failed family delete leaves the family and its child link intact
- deleting a child link by its own id succeeds
- deleting a family **without** children succeeds
- the same method and String parameter delete two different entity types, with different outcomes
- deleting an unknown id is a silent no-op returning 0

### 3. `schema_shape_characterization_test.dart` — H3, D4, D7, C2, H5 (10 tests)
- fresh database contains all 15 tables, **including** `persons` and `relationships`, which the
  v10 migration drops
- no named query indexes exist — every index is an implicit `sqlite_autoindex_*`
- the `idx_*` indexes the migration would create are absent (spot-checked on 5 of them)
- `families_v2` has no `tree_id` column
- `genealogy_persons` has **zero** foreign keys
- `genealogy_persons.tree_id` is an unconstrained `TEXT NOT NULL` column
- the legacy schema **did** declare `persons.tree_id` and `relationships.tree_id` as referencing
  `family_trees` — an explicit regression assertion
- every person-referencing FK is `ON DELETE NO ACTION` (events, media_items, research_notes,
  surname_events, todos, families_v2, family_children_v2)
- child tables have no `is_deleted` column while the v2 person/relationship tables do
- deleting a tree succeeds and silently orphans its people

### 4. `migration_characterization_test.dart` — H1, H2 (6 tests)
Builds a real file-backed database, seeds the legacy `persons`/`relationships` tables, rewinds
`PRAGMA user_version` to 9, then opens it so `onUpgrade(9, 11)` runs.
- legacy `'spouse'` rows are not migrated and the table is dropped
- **A/B proof:** the identical fixture with `'marriage'` *does* migrate → the filter literal in
  `app_database.dart:153` is the defect
- `parent_child` rows migrate correctly (control case)
- a parent with two families aborts the migration (`StateError: Too many elements`)
- the aborted migration has **already committed** the families and links it created
- the next open "succeeds" via the `familyTotal > 0` guard and silently finishes the migration with
  the unresolved links lost

**Fixture caveat (important):** the migration fixture is created by the *current* schema and then has
its `user_version` forced back to 9, so only the migration logic is exercised. It is a migration-path
harness, not a byte-accurate v9 database — a real v9 file has older column sets in
`events`/`media_items`/`research_notes`/`todos`. The tables H1/H2 actually depend on
(`relationships`, `persons`, `genealogy_persons`, `families_v2`, `family_children_v2`) use their real
shapes.

---

## Findings (current behaviour — nothing fixed)

### C1 — person update is broken
`GenealogyPersonDao.updatePerson()` calls `update(genealogyPersons).replace(person)`
(`genealogy_person_dao.dart:22-24`). Drift's `replace()` validates the entity as an insert
(`drift 2.33.0`, `update.dart:126-132`), and the generated validator requires `uuid`
(`app_database.g.dart:1196-1203`), which `GenealogyRepository.updatePerson` never sets. Observed:
`InvalidDataException: ... • uuid: This value was required, but isn't present`, and the row is
unchanged. Both UI call sites are affected: `person_form_page.dart:633` (every edit) and
`person_form_page.dart:684` (attaching a photo right after creating a person).

**C1b (the trap):** `replace()` writes the whole row and applies defaults for omitted columns, so
fixing only the `uuid` defect would make every edit reset `is_living` to `true` (deceased people
become living) and rewrite `display_name_format`/`version`.

### C2 — person deletion is unsafe
`deletePerson()` hard-deletes (`genealogy_person_dao.dart:27-29`) while seven tables reference
`genealogy_persons` with `ON DELETE NO ACTION`, and `beforeOpen` enables foreign keys. Observed:
`SqliteException(787) FOREIGN KEY constraint failed` for a family partner, for a child, and for a
person who merely has an `events` row. Only people with no relationships at all can be deleted. The
confirmation dialog (`person_profile_page.dart:196-200`) promises to delete all connected links;
that cascade does not exist. The schema has `is_deleted` on the v2 person/relationship tables but not
on the child tables, so a soft-delete policy cannot be applied uniformly without a migration.

### C3 — relationship deletion is broken in the common case
`deleteRelationship(id)` tries `family_children_v2` first, then `families_v2`
(`relationship_repository.dart:113-127`). Deleting a couple's family that has children fails with FK
787 because `family_children_v2.family_id → families_v2.id` is `NO ACTION`. The child-link path
works. The API also accepts two different entity types through one opaque String, and silently
returns 0 for unknown ids.

### H1 — legacy spouse relationships are lost during migration (data loss)
`_migrateLegacyRelationshipsToFamilies()` filters `relationshipType == 'marriage'`
(`app_database.dart:153`), but the legacy contract is `parent_child | spouse`
(`relationship_types.dart:2-3`, and the doc comment in `relationships_table.dart`). Demonstrated as
an A/B on identical fixtures: `'spouse'` → **0** families created and the `relationships` table is
then dropped (`app_database.dart:130-135`); `'marriage'` → 1 family created. So a v9 → v11 upgrade
discards every marriage, and the source table is gone.

### H2 — ambiguous lookup aborts the migration, then silently completes with loss
The single-parent branch looks up `husbandId = p1 OR wifeId = p1` and calls `getSingleOrNull()`
(`app_database.dart:190-200`), which throws `StateError: Too many elements` when a parent has two
families (drift `selectable.dart:111-119`, `query.dart:248-255`). Measured sequence on one fixture:

| Step | `user_version` | `families_v2` | `family_children_v2` | `relationships` | `persons` |
|---|---|---|---|---|---|
| before any open | 9 | 0 | 0 | 4 | 5 |
| after 1st open (throws `StateError`) | **9** | **2** | **2** | 4 | 5 |
| after 2nd open (no error) | **11** | 2 | 2 | **dropped** | **dropped** |

Two facts make this worse than a crash:
1. **`onUpgrade` is not atomic.** Drift's `GeneratedDatabase.beforeOpen` calls
   `_resolvedMigration.onUpgrade(...)` directly, without wrapping it in a transaction
   (`drift 2.33.0`, `lib/src/runtime/api/db_base.dart:116-142`). The families and links created
   before the throw remain committed, while the schema version is only written afterwards — so it
   stays at 9.
2. **The retry "succeeds".** On the next launch, `if (familyTotal > 0) return;`
   (`app_database.dart:145-148`) short-circuits the migration, the version advances to 11, and
   `persons`/`relationships` are dropped in the same run.

Net effect: the first launch after such an upgrade fails to initialise (the app shows its
database-error screen via `vanshvriksh_app.dart:_initializeApp`), and the second launch appears to
work while parent links that could not be resolved are permanently missing — with no error and no
remaining source data to recover from.

### H3 — fresh and migrated databases are physically different
`onCreate` runs only `m.createAll()`; the 18 named `idx_*` indexes exist only inside
`if (from < 9)`. Measured on a fresh database: 15 tables and 20 indexes, **all** of them
`sqlite_autoindex_*`, **zero** named indexes. Reading the control flow, a database that was at v9 and
upgraded also never receives them (the `from < 9` guard is false, and the v10 step only alters and
drops). Additionally, `createAll()` still creates the legacy `persons` and `relationships` tables
that the v10 migration deletes, so a fresh database has 15 tables where an upgraded one has 13.

### D4 / D7 — ownership and referential integrity
`families_v2` has no `tree_id`; tree membership is derived from people. `genealogy_persons` has zero
foreign keys, so `tree_id` is unconstrained — while the legacy `persons` and `relationships` tables
it replaced **did** reference `family_trees`. This regression is what makes H5 silent.

### H5 — tree deletion orphans data
`deleteFamilyTree()` is a single row delete (`family_tree_dao.dart:40-42`). Because nothing references
`family_trees` from `genealogy_persons`, the delete succeeds with no error and leaves every person,
family, event, media item and note unreachable.

### H4 — merge is still untransacted (existing tests do not cover this)
`mergePeople()` performs roughly a dozen sequential writes with no `transaction()`
(`genealogy_repository.dart:266-456`). The existing `merge_test.dart` covers only happy paths; the
`UNIQUE(family_id, child_id)` collision path (pre-check filters `isDeleted = false`, the constraint
does not) is untested, as is rollback behaviour.

---

## Files changed

**Added (tests):**
- `test/data/characterization/person_write_characterization_test.dart`
- `test/data/characterization/relationship_delete_characterization_test.dart`
- `test/data/characterization/schema_shape_characterization_test.dart`
- `test/data/characterization/migration_characterization_test.dart`

**Added (documentation / diagnostics):**
- `scratch/audit/phase0-baseline.md` (this report)
- `scratch/audit/diagnose_migration_partial_test.dart` (diagnostic that produced the H2 row-level
  evidence; run with `flutter test scratch/audit/diagnose_migration_partial_test.dart`)

**Not changed:** no file under `lib/`, no schema definition, no `schemaVersion`, no `pubspec.yaml`,
and no pre-existing test was modified, weakened or deleted.

---

## Blockers / things Phase 1 should pick up first

1. `schemaVersion` could not be exercised for the **v1/v7/v8** paths — only v9 → v11. Real v1/v7/v8
   fixtures need to be committed as binary test assets; a hand-built fixture cannot represent their
   older column sets faithfully.
2. The migration test imports `package:sqlite3` transitively (to read `user_version` without
   re-running the app's migration). Adding `sqlite3` to `dev_dependencies` would remove the
   `depend_on_referenced_packages` suppression and should be done in Phase 1.
3. `flutter analyze` cannot go green until `scratch/new_canvas.dart` is removed or `scratch/` is
   excluded in `analysis_options.yaml` — a Phase 0 hygiene item that was deliberately **not** done
   here, since it is a repository change outside the test/documentation scope of this phase.
4. There is no CI configuration, so none of these tests run automatically. Adding a workflow that
   runs `flutter test` is the natural next step once the suite reaches the Phase 1 target.
