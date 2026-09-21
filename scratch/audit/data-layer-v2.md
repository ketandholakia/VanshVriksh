# VanshVriksh — Data-Layer Audit v2

**Scope:** `lib/data/**` (schema, migrations, DAOs, repositories, providers) plus the database lifecycle paths that touch it.
**Codebase:** `ketandholakia/VanshVriksh`, branch `main`, commit `87875fe` (schema version **11**).
**Method:** static reading of every non-generated file in scope + **executed** verification against real SQLite databases (`AppDatabase.forTesting(NativeDatabase.memory())`). Findings marked ✅ **Verified by execution** were reproduced, not inferred.
**Repro artifacts:**
- `scratch/audit/verify_data_layer_v2_test.dart` — schema introspection, FK graph, relationship-delete, tree-delete
- `scratch/audit/verify_update_test.dart` — person update + person delete failures

```
flutter test scratch/audit/verify_data_layer_v2_test.dart
flutter test scratch/audit/verify_update_test.dart
```

---

## 0. Status of the v1 findings

| ID | Finding | v2 status | How it was checked |
|---|---|---|---|
| C1 | `updatePerson` uses `replace()` with an incomplete companion → every edit throws | 🔴 **CONFIRMED** ✅ | Executed: `InvalidDataException: uuid: This value was required, but isn't present` |
| C2 | Person hard-delete conflicts with FK-enforced child rows | 🔴 **CONFIRMED** ✅ | Executed: `SqliteException(787) FOREIGN KEY constraint failed` |
| C3 | Deleting a family that has children violates FK | 🔴 **CONFIRMED** ✅ | Executed: `DELETE FROM families_v2` → FK 787 |
| H1 | Legacy spouse rows are not migrated (filter looks for `marriage`, legacy value is `spouse`) | 🔴 **CONFIRMED** (strong inference, see §2.1) | Constant + table contract, no remaining `marriage` writer |
| H2 | Migration uses `getSingleOrNull()` on a multi-row match | 🔴 **CONFIRMED** (code path) | Drift 2.33.0 `selectable.dart:111-119` — throws when >1 row |
| H3 | Fresh DB and upgraded DB have different physical schemas | 🔴 **CONFIRMED, worse than reported** ✅ | Executed introspection: 20 indexes, **all** `sqlite_autoindex_*`, **zero** named indexes |
| H4 | `mergePeople` lacks a transaction | 🔴 Still open | Code: 10+ sequential writes, no `transaction()` |
| H5 | Tree deletion orphans data | 🔴 **CONFIRMED, silent** ✅ | Executed: tree row deleted, person still points at the deleted tree |
| D4 | `families_v2` has no `tree_id` | 🟠 Confirmed design risk ✅ | Schema dump |
| D7 | `genealogy_persons.tree_id` is not a FK | 🟠 Confirmed ✅ | `PRAGMA foreign_key_list(genealogy_persons)` → **0 rows** |
| D8 | Domain invariants unenforced | 🟠 Confirmed | FK graph + absence of write-time validation |
| — | Sync schema is declared but unused | 🟠 Confirmed | `sync_change_log` has 0 references outside `data/database/` |
| — | `databaseProvider` never disposes the database | 🟠 Confirmed | `lib/data/providers/database_provider.dart` |
| — | Deprecated drift web backend | 🟠 Confirmed by analyzer | `deprecated_member_use` on `app_database_open_connection_web.dart:2` |

**Verdict: the v1 severity assignment survives re-verification.** Nothing in the current `main` mitigates C1–C3. This is not a historical report.

---

## 1. 🔴 C1 — Person update is broken (verified by execution)

```
lib/data/database/daos/genealogy_person_dao.dart:22-24
  Future<bool> updatePerson(GenealogyPersonsCompanion person) {
    return update(genealogyPersons).replace(person);
  }
```

`replace()` is not a partial update. In drift 2.33.0 it validates the entity as an **insert**:

```
drift-2.33.0/lib/src/runtime/query_builder/statements/update.dart:126-132
  Future<bool> replace(Insertable<D> entity, ...) async {
    final columns = entity.toColumns(false);      // nulls are NOT dropped
    _sourceTable.validateIntegrity(entity, isInserting: true).throwIfInvalid(entity);
```

`genealogy_persons.uuid` is `TEXT NOT NULL UNIQUE` with no default, and the generated validator demands it when inserting:

```
lib/data/database/app_database.g.dart:1196-1203
  if (data.containsKey('uuid')) { ... } else if (isInserting) { context.missing(_uuidMeta); }
```

`GenealogyRepository.updatePerson` (`lib/data/repositories/genealogy_repository.dart:139-166`) builds a 40-field companion that **never sets `uuid`**. Executed result:

```
updatePerson error: InvalidDataException: ... cannot be used for that because:
  • uuid: This value was required, but isn't present
name after update: Ashok        ← the edit never reached the database
```

### Blast radius (both call sites are reachable from the UI)
- `lib/features/people/person_form_page.dart:633` — **editing any person always fails.**
- `lib/features/people/person_form_page.dart:684` — **"add person with photo" fails after the row is already inserted**, leaving a person whose photo was saved to disk but never linked.

### The trap: fixing C1 alone activates silent data loss
`replace()` writes the **whole row**, and `person_form_page.dart:633-652` does not supply these fields:

`isLiving`, `occupation`, `religion`, `ethnicity`, `privacyLevel`, `displayNameFormat`, `customDisplayName`, `birthDateQualifier`, `deathDateQualifier`, `deathPlace`, `deathPlaceLat/Lng`.

The moment `uuid` is supplied, every save will:
- flip a deceased person back to **Living** (wrong age, wrong dashboard data), and
- erase the qualifiers and death place that **GEDCOM import** set.

C1 and this defect must be fixed **in the same change**, and C1's regression test must assert on a *deceased, GEDCOM-imported* person so it catches both.

### Correction to v1 — the `replace()` family is not uniformly broken
`updateFamilyTree` (`lib/data/database/daos/family_tree_dao.dart:19-21`) also uses `replace()`, but `FamilyTrees` has only 6 columns and the repository supplies **all** required ones, so it currently works. The real rule is: *`replace()` is only safe when the caller owns the complete row.* `updateFamily()` and `updateFamilyChild()` (`genealogy_person_dao.dart:26-32`) are latent C1s — they will fail the same way the first time a caller omits `uuid`.

**Fix direction:** make the DAO expose keyed partial updates and stop treating companions as rows.

```dart
Future<int> updatePersonById(String id, GenealogyPersonsCompanion changes) =>
    (update(genealogyPersons)..where((t) => t.id.equals(id))).write(changes);
```

Enforce it by making the companion-building path go through `person.toCompanion(true)` + `copyWith`, so a full-row replacement is impossible by construction.

---

## 2. 🔴 C2 — Person deletion is unsafe (verified by execution)

```
lib/data/database/daos/genealogy_person_dao.dart:27-29
  Future<int> deletePerson(String id) =>
      (delete(genealogyPersons)..where((tbl) => tbl.id.equals(id))).go();
```

The FK graph, straight from `PRAGMA foreign_key_list` on a real database:

| Referencing table | Column | on_delete |
|---|---|---|
| `events` | `person_id` | **NO ACTION** |
| `media_items` | `person_id` | **NO ACTION** |
| `research_notes` | `person_id` | **NO ACTION** |
| `surname_events` | `person_id` | **NO ACTION** |
| `todos` | `person_id` | **NO ACTION** |
| `families_v2` | `husband_id`, `wife_id` | **NO ACTION** |
| `family_children_v2` | `child_id` | **NO ACTION** |

`beforeOpen` sets `PRAGMA foreign_keys = ON` (`lib/data/database/app_database.dart:137-140`), so this is enforced. Executed:

```
deletePerson(connected parent) error: SqliteException(787): FOREIGN KEY constraint failed
  Causing statement: DELETE FROM "genealogy_persons" WHERE "id" = ?;
deletePerson(connected child)  error: SqliteException(787): FOREIGN KEY constraint failed
```

**Only people with zero relationships can be deleted.** The confirmation dialog promises the opposite:

> `lib/features/people/person_profile_page.dart:196-200` — *"This will delete this person profile and all family relationship links connected to this person."*

That cascade does not exist anywhere in the codebase.

### Schema contradicting itself on soft delete
`is_deleted` exists on `genealogy_persons`, `families_v2`, `family_children_v2`, `surname_events` — but **not** on `events`, `media_items`, `research_notes`, `todos`, `duplicate_markers`, `citations`. So a soft-delete policy cannot be applied consistently without a migration, while the hard-delete path is blocked by FKs. The design intent (soft delete) and the implementation (hard delete) point in opposite directions — this is the underlying defect, not the missing cascade.

**Decision required (schema-level, before code):**
- **Option A — soft delete (recommended, matches existing columns).** Add `is_deleted`/`updated_at` to the child tables; `deletePerson` becomes a transactional `UPDATE ... SET is_deleted = 1` across the person and its family links; all read paths already filter on `is_deleted` in some places but **not all** (see §5.3 — this needs a sweep).
- **Option B — hard delete with explicit cascade.** One transaction deleting child rows in dependency order.

For a genealogy app, Option A is correct: users expect to correct mistakes, and `mergedIntoId` shows the model already assumes recoverability.

---

## 3. 🔴 C3 — Relationship deletion (verified by execution)

```
lib/data/repositories/relationship_repository.dart:113-127
  Future<int> deleteRelationship(String relationshipId) async {
    final linkCount = await (delete(familyChildrenV2)..where((t) => t.id.equals(relationshipId))).go();
    if (linkCount > 0) return linkCount;
    return (delete(familiesV2)..where((t) => t.id.equals(relationshipId))).go();
  }
```

Executed against a real family (husband + wife + one child):

```
deleteRelationship(family_with_children) -> SqliteException(787): FOREIGN KEY constraint failed
  Causing statement: DELETE FROM "families_v2" WHERE "id" = ?;
deleteRelationship(child_link)           -> deleted=1, no error
```

So the parent-child path works and the spouse path fails whenever the couple has children — i.e. **the common case**.

Two structural problems, both worth more than the bug:
1. **The abstraction is ambiguous.** A "relationship id" may be a `family_children_v2.id` or a `families_v2.id` — two different domain objects with different lifecycles. One delete that guesses by "did anything get deleted?" is unsafe by design.
2. **Delete order is wrong.** `family_children_v2.family_id → families_v2.id` with NO ACTION means the family cannot be removed before its child links.

**Fix direction:** replace with explicit, typed operations, each transactional:
`deleteParentChildLink(linkId)` and `dissolveFamily(familyId)` (which first reassigns or removes child links, and decides what happens to children who had only that family).

---

## 4. Migration safety

### 4.1 🔴 H1 — Spouse rows are not migrated (data-loss migration)

The migration selects one literal:

```
lib/data/database/app_database.dart:153
  final marriages = legacyRels.where((r) => r.relationshipType == 'marriage').toList();
```

But the legacy model's contract says otherwise, in two places:

```
lib/core/constants/relationship_types.dart:2-3
  static const String parentChild = 'parent_child';
  static const String spouse = 'spouse';

lib/data/database/tables/relationships_table.dart (doc comment)
  /// Allowed values:
  ///   parent_child
  ///   spouse
```

No remaining writer of the legacy `relationships` table emits `'marriage'`; the derived-model reader emits `'spouse'` (`relationship_repository.dart:251`). Therefore the filter matches the **wrong literal** and, immediately afterwards, the v10 step drops the table:

```
app_database.dart:130-134  (from < 10)
  await _migrateLegacyRelationshipsToFamilies();
  ...
  await customStatement('DROP TABLE IF EXISTS relationships');
```

**Net effect on a v9 → v10 upgrade: every marriage is silently deleted and unrecoverable.**

Fix: accept both historical literals, and — more important — **verify counts before dropping**:

```dart
final marriages = legacyRels.where((r) =>
    r.relationshipType == 'marriage' || r.relationshipType == 'spouse').toList();
// assert migrated marriages == legacy spouse rows, else abort the migration
```

*Honesty note: the legacy writer is no longer in the codebase, so this is confirmed by contract and constant, not by replaying an old database. It should be validated with a v9 fixture (§8, Phase 0).*

### 4.2 🔴 H2 — Ambiguous lookups can abort or corrupt the migration

`_migrateLegacyRelationshipsToFamilies` uses `.getSingleOrNull()` for existing-family lookups, including:

```dart
final family = await (select(familiesV2)
      ..where((f) => f.husbandId.equals(p1) | f.wifeId.equals(p1)))
    .getSingleOrNull();
```

Drift's `getSingleOrNull()` throws when the query returns more than one row (drift 2.33.0, `selectable.dart:111-119`). A person with two marriages legitimately matches two families → `StateError`, thrown **inside `onUpgrade`**, i.e. a partially applied migration.

Adding `limit(1)` is not the fix — it converts a crash into silently attaching a child to an arbitrary family. The migration must branch explicitly: exactly one → use it; zero → create; multiple → resolve deterministically or preserve the ambiguity.

### 4.3 🔴 H3 — Fresh and upgraded databases are physically different (verified, and worse than reported)

Executed introspection on a freshly created database (15 tables):

```
--- INDEXES (20) ---
sqlite_autoindex_citation_links_1, sqlite_autoindex_citations_1, sqlite_autoindex_duplicate_markers_1,
sqlite_autoindex_events_1, sqlite_autoindex_families_v2_1, sqlite_autoindex_families_v2_2,
sqlite_autoindex_family_children_v2_1..3, sqlite_autoindex_family_trees_1,
sqlite_autoindex_genealogy_persons_1..2, sqlite_autoindex_media_items_1, sqlite_autoindex_persons_1,
sqlite_autoindex_relationships_1, sqlite_autoindex_research_notes_1, sqlite_autoindex_surname_events_1..2,
sqlite_autoindex_sync_change_log_1, sqlite_autoindex_todos_1
```

Every single index is an implicit `sqlite_autoindex_*` from a PK/UNIQUE constraint. **None** of the 18 named `idx_*` indexes exist, because they are created only here:

```dart
app_database.dart:96-121   if (from < 9) { await customStatement('CREATE INDEX IF NOT EXISTS idx_...'); ... }
```

`onCreate` is just `m.createAll()`, so a fresh install never executes that block. Reading the control flow further, a database upgraded from **v9 → v10 → v11 also never gets them** (the `from < 9` guard is false at v9, and the v10 step only alters/drops). Only databases that passed through **≤ v8** end up with query indexes.

So the same app version can run a full tree scan with zero indexes on `genealogy_persons.tree_id`, `families_v2.husband_id/wife_id`, `family_children_v2.family_id`, `events.person_id`. That is a performance bug that only hits *some* users — the hardest kind to diagnose.

**Also newly found — the legacy tables survive on fresh installs.** `createAll()` builds all 15 tables, including `persons` and `relationships`, but the v10 migration **drops** them:

```
app_database.dart:130-135
  await customStatement('DROP TABLE IF EXISTS persons');
  await customStatement('DROP TABLE IF EXISTS relationships');
```

Executed introspection confirms both tables (with their own FKs to `family_trees`/`persons`) are present in a brand-new v11 database. So:
- fresh v11 = 15 tables, no query indexes;
- upgraded v11 = 13 tables, maybe indexes.

Two different schemas behind one `schemaVersion`.

**Fix direction:** declare indexes on the tables with `@TableIndex` so `createAll()` and migrations agree, and make the migration guarantee that a database at v11 — however it got there — converges to one canonical schema.

---

## 5. Schema ownership and integrity

### 5.1 🟠 D4 — `families_v2` has no tree ownership
`families_v2` has `husband_id`, `wife_id`, but no `tree_id`. Tree membership is *derived* from the people in it (`relationship_repository.dart:212-225`). That derivation breaks when a family has one parent, when a person is soft-deleted, or when a tree is deleted. Add `families_v2.tree_id → family_trees.id` and make ownership explicit.

### 5.2 🟠 D7 — the v2 schema dropped referential integrity the v1 schema had
Executed: `PRAGMA foreign_key_list(genealogy_persons)` → **0 rows**. `genealogy_persons.tree_id` is plain `TEXT NOT NULL`. Compare with the schema it replaced:

```
persons.tree_id            TEXT NOT NULL REFERENCES family_trees (id)     ← v1 had the FK
relationships.tree_id      TEXT NOT NULL REFERENCES family_trees (id)     ← v1 had the FK
genealogy_persons.tree_id  TEXT NOT NULL                                  ← v2 does not
```

This is a **regression**, not an omission: `genealogy_persons.tree_id = "does-not-exist"` is accepted by the database, and it is the direct enabler of §5.4.

### 5.3 🟠 D8 — Domain invariants have no enforcement point
`UNIQUE(family_id, child_id)` correctly stops duplicate parent pairings, but nothing stops:
- a child with three *biological* fathers (three families, each with a father);
- a person being their own parent;
- cyclic ancestry;
- a person in two `is_primary_marriage` families.

These are domain rules, not FK rules, so they need a **write-time validation boundary** (see §9). Today the UI, the repositories and the DB each assume one of the others enforces them.

### 5.4 🔴 H5 — Tree deletion silently orphans everything (verified by execution)
`deleteFamilyTree` is a single row delete:

```
lib/data/database/daos/family_tree_dao.dart:40-42
  (delete(familyTrees)..where((tbl) => tbl.id.equals(treeId))).go();
```

Because `genealogy_persons.tree_id` has no FK (§5.2), the delete **succeeds silently**:

```
tree rows deleted=1, people still pointing at deleted tree=1
```

The people, families, events, media and notes of that tree survive as unreachable rows. Note the failure mode is *worse* than an FK error: nothing surfaces to the user, and nothing is ever cleaned up.

### 5.5 🟠 H4 — `mergePeople` is not transactional
`genealogy_repository.dart:266-456` performs, in sequence: family slot rewrites → child-link moves → surname/event/media/note repointing → survivor field merge → duplicate flagging → marker cleanup. Roughly a dozen independent writes with no `transaction()`.

The `UNIQUE(family_id, child_id)` constraint makes this reachable, not theoretical: the pre-check filters `isDeleted = false`, so a soft-deleted `(family, survivor)` row passes the check and then collides on `UPDATE` — after spouse slots have already been rewritten. A half-applied merge is unrecoverable for a user.

Also missing from merge: `citation_links.entity_id`, `surname_events.related_person_id`, the duplicate's profile photo file, and `occupation`/`religion`/`ethnicity`/`customDisplayName`/`isPrivate` are never carried over.

---

## 6. Lifecycle, performance, and dead weight

1. **`databaseProvider` never disposes** (`lib/data/providers/database_provider.dart`) — no `ref.onDispose(db.close)`. Affects tests, hot restart, container replacement, and any future "replace database file" (restore) flow.
2. **Relationship reads are N+1 and tree-unscoped.** `watchRelationshipsByTree` selects **all** `families_v2` and **all** `family_children_v2` rows and filters in Dart (`relationship_repository.dart:173-186`). Every tree pays for every tree's data, and the stream re-emits on any change anywhere.
3. **Soft-delete filters are inconsistent.** `getFamiliesForPerson` filters `isDeleted`; `deleteRelationship`/`deleteDuplicateMarker` hard-delete; `getRelationshipsByTree` filters links but the write paths mix both. Before adopting Option A (§2), every read path needs an audit.
4. **Dead-but-registered tables.** `todos`, `citations`, `citation_links`, `sync_change_log` have **zero** references outside `lib/data/database/`. Their schema is real (and `citation_links` is the best-formed table in the file), but no code reads or writes them.
5. **`sync_change_log` + `uuid`/`syncStatus`/`version`/`lastSyncedAt` are declarative only.** There is no producer and no consumer. This is worth documenting loudly, because `syncStatus = 'pending'` is exactly the kind of value a future developer reads as "sync exists".
6. **Web backend is deprecated.** `package:drift/web.dart` with `DriftWebStorage.indexedDb` — analyzer reports `deprecated_member_use` and `experimental_member_use` (`app_database_open_connection_web.dart:2,6`). Migration to `drift/wasm.dart` is indicated, and this path needs platform-specific verification.
7. **`rxdart` is imported but not declared** in `pubspec.yaml` (`relationship_repository.dart:3`, analyzer `depend_on_referenced_packages`). It resolves today only through a transitive dependency — one `pub upgrade` away from breaking.
8. **Unused import** of `relationship_types.dart` in two places (`relationship_dao.dart:3`, `relationship_repository.dart:5`) — ironic, given §4.1 is exactly a wrong-literal bug.

---

## 7. Amendments to the v1 audit

1. **Do not delete the legacy tables yet.** `persons` and `relationships` are migration *sources*. They must stay until the migration is redesigned and verified, and `PersonDao` (their only accessor) stays with them. Removing them while `_migrateLegacyPersonsToGenealogy` and `_migrateLegacyRelationshipsToFamilies` still reference them would break every upgrade path from ≤ v9.
2. **`updateFamilyTree` is not currently broken** — see §1's correction. Fix by construction, not by assuming all `replace()` calls are equal.
3. **The `idx_*` problem is worse than "fresh vs upgraded".** Databases upgraded from v9 to v11 also end up without indexes, so the divergence has a three-way shape, not two.
4. **The `uuid` defect and the field-preservation defect must ship together.** Treating C1 as a standalone fix will convert a hard failure into silent data loss.
5. **`duplicate_markers` is an orphan table too** — it has no FK on either person column, so markers can outlive the people they point at (relevant to `marked_duplicates_page.dart`, which reads `marker.personB`).
6. **Priority order.** The attached v2 assessment puts migration hardening in Phase 2, after the C1–C3 fixes. I agree, with one addition: **Phase 0 must include a fresh-v11 schema snapshot test**, because that single test makes H3 (§4.3) impossible to regress and cheap to prove fixed.

---

## 8. Phase 0 + Phase 1 remediation specification

### Phase 0 — Freeze the schema and establish migration safety (do first, no behavior change)
| # | Task | Acceptance criterion |
|---|---|---|
| 0.1 | Snapshot the canonical v11 schema (tables, indexes, FKs) into a checked-in fixture | `schema v11` test asserts table set = 13 (post-cleanup decision), index set = expected, and `PRAGMA foreign_key_list` per table |
| 0.2 | Build migration fixtures: v1, v7, v8, v9 legacy databases as committed test assets | Each fixture opens and upgrades to v11 without throwing |
| 0.3 | Characterization test: current `deletePerson` / `updatePerson` behavior | Reproduces `InvalidDataException` and FK 787 as **expected failures**, so the fix flips them deliberately |
| 0.4 | Decide the canonical table set (keep vs drop `persons`/`relationships`/`todos`/`citations`) and record the decision in-repo | Written decision; `onCreate` and `onUpgrade` agree |
| 0.5 | Add `integration_test`/CI entry running all of the above | `flutter test` covers every supported upgrade path |

### Phase 1 — Stop active data corruption
| # | Task | Acceptance criterion |
|---|---|---|
| 1.1 | **C1** — keyed partial update API (`updatePersonById`) + rebuild companions from `toCompanion()`/`copyWith` | Editing a person persists; regression test on a **deceased, GEDCOM-imported** person proves qualifiers, death place and `isLiving` survive |
| 1.2 | **C1** — apply the same to `updateFamily`/`updateFamilyChild`; add a lint/test that forbids `replace()` on wide tables | No `replace()` remains on `genealogy_persons`/`families_v2`/`family_children_v2` |
| 1.3 | **C2** — implement soft delete: `is_deleted` + `updated_at` on child tables, `deletePerson` = one transaction over person + family links | Deleting a connected parent succeeds and disappears from list/profile/tree/dashboard/integrity |
| 1.4 | **C2** — sweep every read path for `is_deleted` filtering | Test asserts no soft-deleted entity appears in any tree/list/dashboard query |
| 1.5 | **C3** — split into `deleteParentChildLink` / `dissolveFamily`, both transactional, with explicit child-handling policy | Deleting a couple's relationship with children succeeds; children remain reachable |
| 1.6 | **H4** — wrap `mergePeople` in `transaction()`, fix the `UNIQUE(family_id, child_id)` pre-check, repoint `citation_links` + `related_person_id`, carry the missing fields, keep the photo | Merge test asserts total row-count conservation across person-scoped tables, and no partially-applied state under an injected failure |
| 1.7 | **H5/D7** — decide `tree_id` FK + delete policy; make tree deletion transactional | Tree deletion either cascades or refuses loudly; never silently orphans |

### Then (Phase 2+, unchanged from v1)
Migration hardening (H1/H2/H3 + index declaration via `@TableIndex`) → schema ownership (`families_v2.tree_id`, `tree_id` FK, FK delete actions) → relationship integrity rules → merge/delete semantics → performance and lifecycle (N+1, tree-scoped streams, `ref.onDispose`, web DB) → deferred architecture (sync engine, citations UI, or removal).

---

## 9. Architectural recommendation

The individual bugs share one root cause: **there is no layer that owns a business operation end-to-end.** Repositories perform `read → read → insert → insert → update` while the schema enforces only FK and UNIQUE constraints, and the UI assumes both will cooperate.

Introduce a transactional **domain service boundary** that owns the transaction *and* the invariants, leaving DAOs as CRUD/query primitives:

```
PersonService.updatePerson()            RelationshipService.addParent() / removeParent()
PersonService.deletePerson()            RelationshipService.addSpouse() / dissolveFamily()
GenealogyService.mergePeople()          GenealogyService.deleteTree()
```

Each service method: validate invariants → open one transaction → write → emit the change. That closes the gap that produced C1–C3, H4 and H5, and it gives Phase 0's characterization tests a stable target to test against.

---

## 10. Verdict

The data layer is **safe for reads and for creating data; not safe for edits, deletions, merges, tree deletion, or database upgrades.**

```
        CURRENT DATA LAYER (v11, main @ 87875fe)

  Person update        🔴 BROKEN — throws on every call (verified)
  Person delete        🔴 FK 787 (verified) + no cascade + no soft-delete path
  Relationship delete  🔴 FK 787 for any couple with children (verified)
  Migration v9→v10     🔴 spouse rows dropped by a wrong literal (H1)
                       🔴 ambiguous getSingleOrNull can abort mid-upgrade (H2)
  Schema convergence   🔴 fresh ≠ upgraded, in two ways (H3, verified)
  Tree deletion        🔴 silently orphans the tree (verified)
  Ownership/FK         🟠 tree_id has no FK; families_v2 has no tree_id
  Merge                🟠 not transactional
  Lifecycle            🟠 no DB disposal; N+1 tree queries; dead sync/citation schema
```

**Recommendation: do Phase 0 + Phase 1 before any feature work or schema change.** Phase 0 is cheap, requires no behavior change, and is the only thing that makes the risky migration fixes in Phase 2 verifiable instead of hopeful.

---

## Appendix A — Verified evidence (executed)

**A.1 — `updatePerson` (C1)**
```
updatePerson error: InvalidDataException: Sorry, GenealogyPersonsCompanion(...) cannot be
that because: • uuid: This value was required, but isn't present
name after update: Ashok
```

**A.2 — `deletePerson` (C2)**
```
deletePerson(connected parent) error: SqliteException(787): FOREIGN KEY constraint failed
deletePerson(connected child)  error: SqliteException(787): FOREIGN KEY constraint failed
```

**A.3 — `deleteRelationship` (C3)**
```
deleteRelationship(family_with_children) -> SqliteException(787): FOREIGN KEY constraint failed
  Causing statement: DELETE FROM "families_v2" WHERE "id" = ?;
deleteRelationship(child_link)           -> deleted=1, error=null
```

**A.4 — foreign-key actions on person-scoped tables (C2 root cause)**
```
FK on events:         [{table: genealogy_persons, from: person_id, on_delete: NO ACTION}]
FK on media_items:    [{table: genealogy_persons, from: person_id, on_delete: NO ACTION}]
FK on research_notes: [{table: genealogy_persons, from: person_id, on_delete: NO ACTION}]
FK on surname_events: [{table: genealogy_persons, from: person_id, on_delete: NO ACTION}]
FK on todos:          [{table: genealogy_persons, from: person_id, on_delete: NO ACTION}]
FK on genealogy_persons: (0 rows — tree_id has no foreign key)
```

**A.5 — tree deletion (H5)**
```
tree rows deleted=1, people still pointing at deleted tree=1
```

**A.6 — fresh v11 schema, tables present**
```
citation_links, citations, duplicate_markers, events, families_v2, family_children_v2,
family_trees, genealogy_persons, media_items, persons, relationships, research_notes,
surname_events, sync_change_log, todos            → 15 tables (2 legacy tables still created)
```

**A.7 — fresh v11 indexes: 20 total, all implicit**
All are `sqlite_autoindex_*`. Zero named `idx_*` indexes exist (§4.3).
