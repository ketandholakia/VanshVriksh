# Data-Layer Audit — VanshVriksh (Flutter + drift)

**Scope:** `lib/data/**` — `database/tables/*`, `database/app_database.dart`, `database/daos/*` (excluding `.g.dart`), `database/app_database_open_connection*.dart`, `repositories/*`, `providers/*`.
**Method:** full read of every file in scope, cross-checked against the generated schema (`app_database.g.dart`, 25k lines) and against the resolved drift source (`drift 2.34.2`, `pubspec.yaml` declares `drift: ^2.33.0`). No file in scope was modified; this report is the only artifact written.
**Legend:** `[BUG]` = confirmed defect reproducible from code/framework semantics. `[RISK]` = design/invariant gap, not a crash today.

---

## 0. Executive summary

| # | Sev | Finding | File:line |
|---|-----|---------|-----------|
| C1 | Critical | `[BUG]` Every person update throws `InvalidDataException` — `update().replace()` with a companion lacking the NOT-NULL `uuid` | `daos/genealogy_person_dao.dart:22`, `repositories/genealogy_repository.dart:140` |
| C2 | High | `[BUG]` Hard `deletePerson` violates FK constraints (no cascade, no child cleanup, `PRAGMA foreign_keys=ON`) | `repositories/genealogy_repository.dart:181`, `database/app_database.dart:140` |
| C3 | High | `[BUG]` `deleteRelationship` on a family that has children throws FK error (children never re-attached) | `repositories/relationship_repository.dart:118` |
| H1 | High | `[BUG]` Legacy `spouse` relationships silently lost in v10 migration (only `'marriage'` handled) | `database/app_database.dart:153` |
| H2 | High | `[BUG]` Migration crashes on `getSingleOrNull()` when a person has >1 family → upgrade aborts | `database/app_database.dart:204,223` |
| H3 | High | Fresh installs get **no** `idx_*` indexes and **do** get the dropped `persons`/`relationships` tables (schema divergence) | `database/app_database.dart:63,103,131` |
| H4 | High | `mergePeople` is a 10+ step mutation with **no transaction** (no transaction anywhere in `lib/data`) | `repositories/genealogy_repository.dart:266` |
| H5 | High | `deleteFamilyTree` orphans every person/family/event/media of the tree | `daos/family_tree_dao.dart:40`, `tables/genealogy_persons_table.dart:43` |
| M1–M10 | Medium | Unique-constraint crash on duplicate child link; unenforced invariants (cycles, 2 fathers, self-parent); merge misses `todos`/`citation_links`; `getDuplicateMarkers` ignores tree; dead tables (`todos`/`citations`/`persons`/`relationships`); `sync_change_log` never written; mixed date storage; N+1 queries | see §3–§6 |
| L1–L5 | Low | DB never closed by provider; deprecated web API; dead ternary in migration; gender free-text; no migration tests/schema dumps | see §3–§6 |

---

## 1. Schema quality

### 1.1 Table inventory (15 declared, 13/15 live)

`app_database.dart:35-45` declares:

```
FamilyTrees, GenealogyPersons, SurnameEvents, FamiliesV2, FamilyChildrenV2,
Persons, Relationships, MediaItems, Events, DuplicateMarkers, Citations,
CitationLinks, ResearchNotes, Todos, SyncChangeLog
```

**D1 — `[BUG]` Overlapping legacy/v2 models are half-retired; both paths are still "live" in the schema.**
- `Persons` (`tables/persons_table.dart`) and `Relationships` (`tables/relationships_table.dart`) are still declared in `@DriftDatabase`, so `onCreate` → `m.createAll()` (`app_database.dart:63-65`) **creates them on every fresh install**, while upgraded databases **drop** them (`app_database.dart:130-131`: `DROP TABLE IF EXISTS persons` / `DROP TABLE IF EXISTS relationships`).
- Impact: two different live schemas. Any query touching `persons` (e.g. `PersonDao.getPeopleByTree`, `daos/person_dao.dart:36`) works on a fresh install and throws `no such table: persons` on an upgraded install. Today no app code calls `PersonDao` (grep: only `app_database.dart` + `person_dao.dart` itself reference it) — so this is a latent trap, not a current crash.
- Fix: delete `Persons`, `Relationships`, `PersonDao` from the schema and files; or, if legacy DBs still need reading, keep them out of `@DriftDatabase` and migrate via `customStatement`.

**D2 — `[BUG]` Dead tables with zero data-layer access: `Todos`, `Citations`, `CitationLinks`.**
- Grep over `lib` (excluding `.g.dart`) shows only `app_database.dart` and the table files themselves referencing `Todos`/`todos`, `Citations`/`citation(s)`, `CitationLinks`. There is no DAO, no repository and no reader/writer.
- Impact: schema weight, migration cost, and a false impression that citations/tasks are supported. `todos.person_id`/`research_notes` FKs participate in the delete-FK failure (C2) for no benefit.
- Fix: remove, or implement `TodosDao`/`CitationsRepository` if the features are intended.

**D3 — `[BUG]` `isDeleted` soft-delete flags are decorative.**
- Declared on `genealogy_persons_table.dart:47`, `families_v2_table.dart:42`, `family_children_v2_table.dart:22` with `isDeleted.equals(false)` filters in DAOs (`daos/genealogy_person_dao.dart:58,65,79,107,121,134,146`).
- But every delete path is a **hard** delete: `genealogy_repository.dart:181 deletePerson`, `relationship_repository.dart:118 deleteRelationship`, `daos/events_dao.dart:21 deleteEvent`, `daos/media_dao.dart:18 deleteMediaItem`, `daos/research_notes_dao.dart:22 deleteResearchNote`, `daos/family_tree_dao.dart:40 deleteFamilyTree`. The only `isDeleted: const Value(true)` write in the whole codebase is the merge path (`genealogy_repository.dart:442`).
- Impact: no tombstones ⇒ no undo, no recycle bin, and no sync-delete propagation even if sync were implemented (`sync_change_log` would need delete markers).
- Fix: route deletes through a `softDelete` that sets `isDeleted`/`updatedAt` and filters every read on `isDeleted = false`.

**D4 — `[RISK]` `families_v2` / `family_children_v2` have no `tree_id`.**
- `families_v2_table.dart` has no tree column; `family_children_v2_table.dart:5-25` likewise. Consequently `RelationshipRepository.watchRelationshipsByTree` (`relationship_repository.dart:163-180`) must select **all** families and all links of the database and filter in Dart via `_familiesInTree` (`:186-201`). Every relationship change in any tree invalidates every relationship stream.
- Fix: add `tree_id` (FK → `family_trees`) to both tables, index it, and scope queries in SQL.

**D5 — `[RISK]` Nullability looser than the domain.**
- `families_v2_table.dart:8-17`: `husbandId` and `wifeId` are both `nullable()`, so a "family" can exist with **zero** partners, and nothing prevents `husband_id == wife_id` (self-marriage). The only guard is in `RelationshipRepository.addSpouseRelationship` (`relationship_repository.dart:67`), i.e. a code-level guard on one of several write paths (`GenealogyRepository.createFamily`, `app_database.dart` migration inserts, GEDCOM importer all bypass it).
- `families_v2` relationshipType is free text with default `'marriage'` (`:36`) — `'spouse'`, `'marriage'`, `'partnership'` can coexist.
- Fix: `CHECK (husband_id IS NOT NULL OR wife_id IS NOT NULL)`, `CHECK (husband_id IS NULL OR husband_id <> wife_id)`, and a `CHECK`/lookup table for `relationship_type`.

**D6 — `[RISK]` Inconsistent date storage.** Three representations coexist:
- `DateTimeColumn` (drift stores epoch INTEGER): `genealogy_persons.birth_date/death_date`, `families_v2.marriage_date/divorce_date`, `events.created_at`.
- REAL sort keys duplicating the above: `events.date_sort`, `research_notes.note_date_sort` (`events_table.dart:11`, `research_notes_table.dart:15`).
- TEXT dates: `surname_events.start_date/end_date` (`tables/surname_events_table.dart:10-13`), `todos.due_date` (`tables/todos_table.dart:12`).
- Plus a qualifier/display string per date column (`birth_date_qualifier`, `note_date_display`, …) duplicated across tables.
- Impact: no single source of truth for chronological sorting; the REAL sort keys are computed ad hoc in repositories (`events_repository.dart:33`, `research_notes_repository.dart:30`) and can drift out of sync with the DateTime column. `date_sort` is never recomputed when `updateEvent` is called without `eventDate` (it is explicitly set to `Value(null)` — `events_repository.dart:95`), silently erasing the sort key.
- Fix: one canonical representation (prefer `DateTimeColumn` + an explicit `qualifier`/`displayText`), and derive sort keys in SQL or in one place.

**D7 — `[RISK]` `genealogy_persons.treeId` has no foreign key.**
- `genealogy_persons_table.dart:43`: `TextColumn get treeId => text()();` — no `.references(FamilyTrees, #id)`, unlike `persons_table.dart:9` which does declare it.
- Impact: `GenealogyRepository.addPerson` (`genealogy_repository.dart:25-101`) accepts any string; a person can reference a non-existent tree. Combined with H5 every tree deletion silently orphans people.
- Fix: `text().references(FamilyTrees, #id)()` + `PRAGMA foreign_keys` (already on) and/or an `ON DELETE CASCADE`/`SET NULL` policy.

**D8 — `[RISK]` No uniqueness on semantic keys.**
- `duplicate_markers_table.dart` has no `UNIQUE(tree_id, person_a_id, person_b_id)` and no FK on `personAId`/`personBId` → the same pair can be marked repeatedly, and markers survive a person hard-delete as dangling ids.
- `families_v2` has no `UNIQUE(husband_id, wife_id)` → duplicate couple families are possible from concurrent/dup writes.
- `family_children_v2` **does** have `UNIQUE(family_id, child_id)` (`family_children_v2_table.dart:28-32`, honoured at runtime by drift via `dslTable.customConstraints`, `drift/.../migration.dart:373`), but no `birth_order` uniqueness/integrity.
- Fix: add the missing UNIQUE constraints + FKs (with cascade) on `duplicate_markers`.

### 1.2 Indexes

- Only the from&lt;9 upgrade branch creates indexes (`app_database.dart:103-122`, 19 `CREATE INDEX IF NOT EXISTS` statements).
- **`[BUG]` H3** — `onCreate: (m) async { await m.createAll(); }` (`:63-65`) does **not** run any of them. A fresh v11 install has no index on `genealogy_persons.tree_id`, `family_children_v2.family_id`, etc., whereas an upgraded install does. Same app, different query plans; all list/search queries do full table scans on fresh installs.
- There is no index on `families_v2(husband_id, wife_id)` composite, none on `research_notes(resolved)`/`todos(completed)`, and no FTS for `searchPeople`, which uses `LIKE '%…%'` (`daos/genealogy_person_dao.dart:69-86`, `daos/person_dao.dart:44-60`) — unindexable by design.
- Fix: declare indexes with `@TableIndex` on the table classes (so `createAll` emits them), or run the same DDL in `onCreate` before `createAll`, and keep the v9 block for upgraders. Drift docs recommend `@TableIndex` for exactly this reason.

---

## 2. Migration correctness (`app_database.dart`)

`schemaVersion = 11` (`:59`); drift 2.34.2 resolved; no `drift_schemas/` directory, no `build.yaml`, no migration test anywhere (`test/` has only 4 files: widget_test, merge_test, gedcom_importer_test, gedcom_parser_test) — so **nothing verifies any of the paths below** (L5).

Structure is the correct cumulative `if (from < N)` ladder (`:67-136`), and `beforeOpen` re-enables FKs on every connection (`:138-141`), which is good practice.

**M-A — C1-adjacent, but schema-side:** fresh DBs have `persons`+`relationships`, upgraded DBs do not (H3) → the declared schema and the migrated schema **diverge permanently**. `AppDatabase.forTesting` + `m.createAll()` in tests only ever exercises the *fresh* variant, so the divergence is invisible to CI.

**M-B — `[BUG]` H1 data loss in `_migrateLegacyRelationshipsToFamilies` (`:144-247`).**
```dart
final marriages = legacyRels.where((r) => r.relationshipType == 'marriage').toList();   // :153
...
final parentChildRels = legacyRels.where((r) => r.relationshipType == 'parent_child').toList();  // :184
```
The legacy table's own documentation (`tables/relationships_table.dart:15-17`: `/// For spouse: /// personId = spouse 1`) and `core/constants/relationship_types.dart` (`spouse = 'spouse'`) say the type was **`spouse`**, not `'marriage'`. Any legacy `spouse` row is neither migrated nor reported, and the table is then dropped (`:131`) — silent, unrecoverable loss of every marriage. Fix: accept both (`{'marriage','spouse'}`), and assert afterwards that the count of migrated families ≥ count of distinct partner pairs, failing the migration (and keeping the legacy table) if not.

**M-C — `[BUG]` H2 migration crash via `getSingleOrNull()` (`:204` and `:223`).**
```dart
final family = await (select(familiesV2)
      ..where((f) => f.husbandId.equals(p1) | f.wifeId.equals(p1)))
  .getSingleOrNull();          // :223 (single-parent branch)
```
drift's `getSingleOrNull` returns `list.single` (drift `selectable.dart:166-173`), so **>1 row throws** `StateError: Too many elements`. In the single-parent branch this query matches *all* families of that parent: a parent with two marriages → ≥2 rows → throw. Because this runs inside `onUpgrade`, the migration aborts and the app cannot open the DB (drift rolls back and rethrows; there is no error handling and no fallback). Same pattern at `:159` (marriage dedup) and `:204` (2-parent lookup). Fix: `..limit(1)).getSingleOrNull()` or `get()` + explicit choice, plus a `try/catch` that logs and preserves the legacy tables.

**M-D — `[RISK]` Migration invents marriages.** In the 2-parent branch (`:212-219`) a family is created with `(p1,p2)` as husband/wife even when the legacy data only said "these two are the parents" (e.g. two recorded mothers, or unmarried parents). The resulting `families_v2.relationship_type` defaults to `'marriage'` and the tree renderer treats it as a couple. Fix: create the family but record a non-marital `relationship_type`/flag, or keep parent links separate from marriage.

**M-E — `[RISK] (works, but fragile)` forward FK reference in v1/v2 upgrades.** For `from < 3` (`:67-74`) `m.createTable(events|mediaItems|…|syncChangeLog)` emits the **current** DDL, i.e. `events.person_id REFERENCES genealogy_persons(id)` — a table created later at `from < 7` (`:94-99`). It works only because `PRAGMA foreign_keys` is still OFF during migrations (`beforeOpen` at `:140` runs afterwards). If the pragma were ever moved into `onCreate`/`open`, these upgrades would fail at `INSERT`. Fix: create `genealogy_persons` before `events` in the `from < 7`/`from < 3` ladder, or reorder so dependencies precede dependents.

**M-F — `[RISK]` No step for `from < 2`.** The ladder jumps 1→3; any v2-only schema change is unhandled and unverifiable here (flagged as unverifiable, not proven broken).

**M-G — `[RISK]` v10 `TableMigration`s rely on implicit column mapping (`:126-129`).** `m.alterTable(TableMigration(events|mediaItems|researchNotes|todos))` recreates each table to repoint FKs to `genealogy_persons`; drift copies columns present in both. This is correct *only* because `from < 8` preserved ids (`:101` copies `id: person.id`). It is untested — a failed copy here loses all events/media/notes/todos with no warning.

**M-H — minor:** `from < 4` uses raw `ALTER TABLE research_notes ADD COLUMN` (`:75-82`), consistent with the guarded version; `from < 9` creates indexes on `persons`/`relationships` (`:105-109`) that are dropped 20 lines later (`:130-131`) — harmless but dead work.

**M-I — `[RISK]` `_migrateLegacyPersonsToGenealogy` (`:250-346`) is only run when `genealogy_persons` is empty** (`if (legacyTotal == 0 || genealogyTotal > 0) return;` `:258-262`). If a user has one V2 person (e.g. created by an early buggy build) every legacy person is silently skipped and then the legacy table is dropped at v10 → total loss of the legacy tree. Fix: migrate per-row with `insertOnConflictIgnore` on `id`, not on whole-table emptiness.
Also dead code at `:269-273` — both branches of the ternary yield `'birth_married'` (L3); `mergedIntoId`/`version` are set without semantic use.

---

## 3. Repository / DAO correctness

### C1 — `[BUG]` **Every person update throws.** (Critical)
`daos/genealogy_person_dao.dart:22-24`:
```dart
Future<bool> updatePerson(GenealogyPersonsCompanion person) {
  return update(genealogyPersons).replace(person);
}
```
`GenealogyRepository.updatePerson` (`genealogy_repository.dart:130-176`) builds the companion **without `uuid`** (also omits `createdAt`, `version`, `syncStatus`, `isDeleted`). drift's `UpdateStatement.replace` validates as an insert (drift `.../statements/update.dart:113-121`: `validateIntegrity(entity, isInserting: true).throwIfInvalid(entity)`) and the generated validator marks missing NOT-NULL/no-default columns as errors (`app_database.g.dart:1199-1202`):
```dart
} else if (isInserting) { context.missing(_uuidMeta); }
```
`uuid` is `text().unique()()` → NOT NULL, no default → `requiredDuringInsert`. Therefore every `replace()` throws `InvalidDataException("uuid: This value was required, but isn't present")` (drift `data_verification.dart:56-75`). The extra columns that *do* have defaults (`createdAt`, `isLiving`, `syncStatus`, `isDeleted`, `version`) would additionally be **reset to their defaults on every write** even if `uuid` were supplied — e.g. `mergedIntoId`, `lastSyncedAt`, `version` silently cleared (drift docs on `replace`: absent values are "reset to null"/default).
Impact: person edit is fully broken (`features/people/person_form_page.dart:633`, and the post-create photo write at `:684`) — the user sees "Failed to save person: …". Nothing in the data layer catches it, and no test covers `updatePerson`.
Fix: use `update(genealogyPersons)..where((t) => t.id.equals(id))).write(companion)` (ignore-absent semantics) — or a `GenealogyPersonsCompanion.insert`-style full replace that includes `uuid`. Same class of bug is latent in `updateFamily`/`updateFamilyChild` (`daos/genealogy_person_dao.dart:34-44`) — currently unreferenced, but they will fail identically if wired up with partial companions.

### C2 — `[BUG]` **Hard delete of a referenced person fails.** (High)
`genealogy_repository.dart:181-183`:
```dart
Future<int> deletePerson(String personId) {
  return _personDao.deletePerson(personId);   // delete(genealogyPersons)..where(id=…)
}
```
Referencing tables and their FK DDL (all `REFERENCES genealogy_persons (id)`, **no `ON DELETE` action** — verified in `app_database.g.dart:2663,3763,3775,5579?…` i.e. lines 2663 (surname_events), 3763/3775 (events), 5593 (family_children_v2.child_id), 8360 (media_items), 10927 (research_notes), 11465 (todos)) plus `families_v2.husband_id/wife_id`. `beforeOpen` sets `PRAGMA foreign_keys = ON` (`app_database.dart:140`). `person_profile_page.dart:223` calls `deletePerson` directly.
Impact: deleting any person who has a surname event, event, media item, research note, todo, a child link or a spouse family raises `SqliteException: FOREIGN KEY constraint failed` and nothing is deleted; `duplicate_markers` and `citation_links` rows are left dangling on the paths where the FK does not exist.
Fix: either declare `onDelete: KeyAction.cascade` on all person references (drift: `.references(GenealogyPersons, #id, onDelete: KeyAction.cascade)`), or perform an explicit soft-delete plus explicit reassignment/cleanup inside a transaction.

### C3 — `[BUG]` **Deleting a spouse family that has children fails.** (High)
`relationship_repository.dart:118-126`:
```dart
final linkCount = await (_database.delete(_database.familyChildrenV2)
      ..where((t) => t.id.equals(relationshipId))).go();
if (linkCount > 0) return linkCount;
return (_database.delete(_database.familiesV2)
      ..where((t) => t.id.equals(relationshipId))).go();
```
When `relationshipId` is a `families_v2` id and any `family_children_v2` row references it (`family_children_v2_table.dart:7`: `familyId => text().references(FamiliesV2, #id)()`), the second delete violates the FK unless the family happens to have children attached under the *same* primary key (it cannot — ids are UUIDs). So "remove spouse" fails for every couple with children, and there is no code to re-parent the children to a single-parent family.
Fix: inside a transaction, either soft-delete the family (set `isDeleted`) and keep the child links, or move `family_children_v2` rows to a new single-parent family before deleting.

### N+1 / redundant queries
- `daos/relationship_dao.dart:171-188` `getSpousePersonItemsOf`: one `SELECT` **per family** in a loop (`:180`) — N+1. Should be a single `isIn(spouseIds)` query (the sibling/parent methods already do this).
- `daos/relationship_dao.dart:45-58` `getChildPersonsOfParent`: collects `childIds` without de-duplication (`:53`) so a child linked in two families of the same parent is returned twice; `getParentPersonsOfChild` (`:18-38`) correctly uses a `Set`. Inconsistent.
- `daos/relationship_dao.dart:84-92` `getSiblingPersonsOf` filters `childId.isNotValue(personId)` but does **not** filter `isDeleted = false`, unlike the rest of the DAO layer.
- `repositories/relationship_repository.dart:190-197` and `:206-211`: `getRelationshipsForPerson` loads **all** `family_children_v2` rows for every person query.
- `getRelationshipsByTree`/`watchRelationshipsByTree` (`:163-197`) do O(people+families+links) work in Dart on every emission, and (per D4) subscribe to the entire `families_v2`/`family_children_v2` tables, so any write anywhere re-runs it.

### Error handling / missing awaits / races
- **No `try`/`catch` anywhere in `lib/data/repositories/*` or `lib/data/database/daos/*`** (grep for `catch` returns zero hits). Every drift error (`SqliteException`, `InvalidDataException`, `StateError`) propagates raw to the UI. In particular M1 below converts a user error into an unhandled crash.
- All awaited DAO calls are correctly awaited; no missing `await` was found in the data layer (checked every `_personDao.*`/`_database.*` call site). The only "fire and forget" pattern is that `updatePerson`'s return value is ignored (`genealogy_repository.dart:140`) — which is how C1 hides from static analysis.
- **`[BUG]` M1 — check-then-insert race + unguarded duplicate in `addChildToFamily`:** `genealogy_repository.dart:574-601` inserts unconditionally. The `UNIQUE(family_id, child_id)` constraint (`family_children_v2_table.dart:28-32`) then fails with a raw `SqliteException`, which is unhandled (`genealogy_link_family_page.dart:97`, `genealogy_person_form_page.dart:168`). Contrast `addParentChildRelationship` (`relationship_repository.dart:41-43`) which *does* pre-check `alreadyLinked`, but that check is itself non-atomic: two concurrent calls can both pass and one then violates UNIQUE.
- **`[RISK]` duplicate single-parent families:** `addParentChildRelationship` (`:33-39`) does `families.isNotEmpty ? first : _createSingleParentFamily(...)` with no unique constraint on `families_v2` → two parallel calls create two single-parent families for the same parent and split the children between them; both then appear as separate "families" in the UI.
- **`[RISK]` `families.first` picks an arbitrary family** (`:36`): a parent with two marriages gets a new child attached to whichever family sorts first (`isPrimaryMarriage DESC, marriageDate ASC`) — there is no way for the caller to specify the co-parent. This is a modelling hole, not just a race.
- **`[RISK]` `ensureDefaultFamilyTree`** (`daos/family_tree_dao.dart:52-68`) is check-then-insert with no transaction; concurrent startup calls surface a primary-key violation.

### Unvalidated inputs (data layer)
- `addPerson`/`updatePerson` (`genealogy_repository.dart:25,102`) never validate: non-empty `firstName` (a raw empty string is stored, though the UI substitutes `'Unknown'`), `gender ∈ {M,F,U,…}` (see L4), `treeId` existence (D7), date sanity (`birthDate > deathDate` accepted), or `privacyLevel ∈ [0…]`.
- `createFamily`/`addChildToFamily`/`addSpouseRelationship` accept any id strings; non-existent family/child ids become FK errors (or orphans where no FK exists, e.g. `families_v2` referenced by nothing, `genealogy_persons.tree_id`).
- `mergePeople` validates survivor≠duplicate and existence (`:277,283`) — the only guard rails in the file.

---

## 4. Data-integrity gaps (invariants that are documented but unenforced)

The only invariant checking in the app lives in the **UI layer**, runs only on demand, and only for one hard-coded tree:
`features/integrity/integrity_check_providers.dart:23-27`:
```dart
final people = await personRepo.getPeopleByTree(AppConstants.defaultTreeId);
final relationships = await relationshipRepository.getRelationshipsByTree(AppConstants.defaultTreeId);
```
It detects (a) parent younger than child (`<0` years) and warns at `<12` years (`:41-66`), and (b) parent-child cycles via DFS (`:70-101`). Nothing prevents any of these from being created, and nothing checks them at write time or in the DB:

| Invariant | Status | Where it should be enforced | Where it is (not) |
|---|---|---|---|
| Child can have at most 2 biological parents, at most 1 per gender/role | **unenforced** | `createFamily`/`addChildToFamily`, `relationship_repository.dart:23-57` | a child can be added to any number of families, each defaulting `relationshipType='biological'` (`family_children_v2_table.dart:10`) → two "biological fathers" are representable |
| No parent-child cycles / self-parent | **unenforced** | DB `CHECK` impossible → must be a write-time ancestor walk | `addParentChildRelationship` performs **no** ancestor check (`relationship_repository.dart:23-57`); `addChildToFamily` does not even check `childId != parentId`; only the after-the-fact DFS in the integrity page finds it |
| Child ≠ one of its own parents | **unenforced** | `family_children_v2` has no such constraint | `addChildToFamily` would happily insert `childId == husbandId` |
| Spouse cycles / self-marriage | **partially** | `addSpouseRelationship:67` checks self only; no DB constraint (D5) | `createFamily` and both migrations bypass it |
| Parent age sanity (≥ ~12y older) | **unenforced** | write path | only warnings in the integrity page |
| Duplicate relationship rows | **enforced in DB** for `(family_id, child_id)`; **not** for couple families or duplicate markers | D8 | `addChildToFamily` still surfaces it as a crash (M1) |
| Referential integrity of `tree_id`, `citation_links.entity_id`, `duplicate_markers.person_[ab]_id`, `surname_events.related_person_id`, `families_v2` ↔ tree | **unenforced** (no FK) | D7, D8 | orphan records possible and, per H5, produced by normal operation |
| Gender consistency (parents' roles vs `families_v2.husband/wife`) | **unenforced** | — | `_isFemale` (`relationship_repository.dart:139-142`) and `_pickGender` (`genealogy_repository.dart:456-464`) disagree on accepted values (`'F'/'FEMALE'` vs `'M'/'F'/'MALE'/'FEMALE'/'U'/'UNKNOWN'`) |

---

## 5. Web / desktop platform support

**Desktop/mobile (`app_database_open_connection.dart`, 14 lines):**
```dart
final dbFolder = await getApplicationDocumentsDirectory();
final file = File(p.join(dbFolder.path, 'vanshvriksh.db'));
return NativeDatabase.createInBackground(file);
```
- Correct for Windows/macOS/Linux/Android/iOS; `NativeDatabase.createInBackground` keeps queries off the UI isolate. `sqlite3_flutter_libs: ^0.6.0+eol` is in `pubspec.yaml`.
- `[RISK]` No `PRAGMA journal_mode=WAL`/`synchronous` tuning and no `File.exists` check; a locked/corrupt file surfaces as a raw exception at first query. No error path if the documents directory is unwritable.

**Web (`app_database_open_connection_web.dart`, 10 lines):**
```dart
QueryExecutor openConnection() {
  return WebDatabase.withStorage(DriftWebStorage.indexedDb('vanshvriksh'));
}
```
- `[RISK] L2` — uses the **deprecated** `package:drift/web.dart` / `WebDatabase` API. drift ≥2.5 ships `drift/wasm.dart` (`WasmDatabase.open(databaseName: …)`) which supports both JS and WasmGC builds and background workers; `WebDatabase` will not survive a drift 3 upgrade and runs in the main isolate (jank on large trees).
- The conditional import key is `dart.library.html` (`app_database.dart:27-28`), which also holds for current Flutter Web targets, so this still compiles; but there is no `dart.library.js_interop`/wasm branch.
- `beforeOpen`'s `PRAGMA foreign_keys = ON` (`app_database.dart:140`) does reach the sql.js connection (drift forwards pragmas), so FK behaviour matches desktop — this is what makes C2/C3 reproducible on web too.
- Not a data-layer file, but worth flagging for the platform story: `services/backup_service.dart` zips a **filesystem** path (`getApplicationDocumentsDirectory` + `File`) and therefore cannot work on web at all; the export/backup feature is desktop/mobile-only with no web branch.
- No IndexedDB quota/eviction handling: on web, a large tree can be evicted by the browser with no warning (drift's `WebDatabase` has no persistent-storage request).

---

## 6. Missing data-layer features (substantiated)

1. **Sync is declared but not implemented.** `tables/sync_change_log_table.dart` defines the log, and `genealogy_persons`/`families_v2`/`family_children_v2`/`surname_events` all carry `uuid`, `sync_status`, `is_deleted`, `created_at`, `updated_at` — but grep over all of `lib` (excluding generated code) finds **no writer and no reader** of `syncChangeLog` (only the table file and `app_database.dart:16,45,73,122`), and `sync_status` is only ever hard-coded to `'pending'` (`genealogy_repository.dart:92`, migrations `app_database.dart:291`). `lastSyncedAt` and `version` are never updated. The `idx_sync_change_log_status` index (`app_database.dart:122`) indexes a permanently empty table.
2. **No audit trail / history.** There is no change-history table; `surname_events` is domain data, not an audit log. Combined with hard deletes (D3) there is no way to answer "who changed this and when".
3. **No undo / recycle bin.** `isDeleted` exists but is unused by deletes (D3); even merge's soft-delete has no restore path (`mergedIntoId` is written at `genealogy_repository.dart:443` and read nowhere).
4. **No entity-level export.** The only export is `BackupService`, which zips the raw `vanshvriksh.db` file (`services/backup_service.dart:_createZipBackup`) rather than serialising entities; `Citations`/`CitationLinks`/`Todos` are therefore exported only implicitly as dead tables, and there is no CSV/JSON/GEDCOM-export path in `lib/data`.
5. **No migration safety net.** No `drift_schemas/` export, no `build.yaml` with `drift_dev` schema directives, no migration test — schemaVersion went 1→11 (with a gap at 2) with zero automated verification (L5).
6. **No validation layer.** No `Validator`/`extension`/`CHECK`-based constraints anywhere in `lib/data` (see §3 "Unvalidated inputs" and §4).
7. **No `todos`/`citations` repositories**, so two declared feature tables are unreachable from code (D2).
8. **No `ref.onDispose`** on `databaseProvider` (`providers/database_provider.dart:5-7`) — the `AppDatabase` is never closed; hot-restart/tests leak connections. Also `AppDatabase.forTesting(super.e)` is the only close path.
9. **No FTS/search index**; `searchPeople` is `LIKE '%q%'` over 9 columns (`daos/genealogy_person_dao.dart:69-86`), unindexable and case-sensitive depending on collation.
10. **No concurrency control / optimistic locking** despite the `version` column; last-write-wins silently.

---

## 7. Recommended fix order

1. **C1** — switch `updatePerson`/`updateFamily`/`updateFamilyChild` to `write()` (or include `uuid`), add a regression test. *(blocks a core feature)*
2. **C2/C3** — define FK delete actions (`onDelete: KeyAction.cascade` / `SET NULL`) or implement transactional soft-delete + re-parenting; wrap deletes in `transaction()`.
3. **H1/H2** — harden the v8/v10 migrations: accept `'spouse'`, never use bare `getSingleOrNull()` in a migration, keep legacy tables until the new rows are verifiably inserted.
4. **H3** — move index creation into `@TableIndex` declarations so `createAll` and upgrades agree; remove or keep `Persons`/`Relationships` consistently.
5. **H4/H5** — wrap `mergePeople` and `deleteFamilyTree` in transactions; cascade or soft-delete tree contents; add `tree_id` FKs.
6. **M-series** — invariants at write time (cycle/self/two-parents), `getDuplicateMarkers` scoping, dedupe N+1 queries, remove dead tables.
7. **L-series** — close the DB in the provider, migrate web to `drift/wasm.dart`, add `drift_schemas` + migration tests for v1→v11.
