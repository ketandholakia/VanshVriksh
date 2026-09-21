# VanshVriksh — Canonical Genealogy Model (schema v12)

**Phase:** core data-model redesign. Pre-production, so breaking internal APIs and the physical
schema were both allowed and used.

This phase completes three items that earlier phases deferred: the schema-ownership work, the
permanent-index requirement, and the migration hardening that the redesign forced (the legacy
absorption code had to be rewritten anyway, so the `'spouse'` literal defect and the ambiguous
lookup were fixed here rather than in a separate pass).

---

## 1. The canonical model

```
FamilyTree  (family_trees)
│   id, tree_name, description, root_person_id (optional pointer), created_at, updated_at
│
├── Person            genealogy_persons   .tree_id ──FK──► family_trees.id   NOT NULL, RESTRICT
│     id (immutable DB identity), uuid (stable external identity),
│     name parts, gender, birth/death date + qualifier + place + lat/lng,
│     is_living, profile_photo_path, biography/notes/occupation/religion/ethnicity,
│     is_private, privacy_level, is_deleted (soft delete),
│     merged_into_id ──FK(self)──► genealogy_persons.id   SET NULL,
│     created_at, updated_at
│
└── Family            families_v2         .tree_id ──FK──► family_trees.id   NOT NULL, RESTRICT
      id, tree_id, husband_id / wife_id ──FK──► genealogy_persons.id  RESTRICT,
      marriage/divorce date + qualifier + place, surname-change flags,
      relationship_type, is_primary_marriage, notes/private_notes,
      is_deleted, created_at, updated_at
      UNIQUE(husband_id, wife_id)
      │
      └── Child      family_children_v2   .family_id ──FK──► families_v2.id       RESTRICT
                                          .child_id  ──FK──► genealogy_persons.id RESTRICT
            birth_order, relationship_type (biological/adopted/foster/step),
            child_surname_at_birth, paternal/maternal_relationship, notes,
            is_deleted, created_at, updated_at
            UNIQUE(family_id, child_id)

Person-scoped (owner: person_id ──FK──► genealogy_persons.id, RESTRICT)
    events · media_items · research_notes · todos · surname_events
    surname_events.related_person_id ──FK──► genealogy_persons.id  SET NULL
    surname_events.related_event_id  ──FK──► events.id             SET NULL

Pair-scoped
    duplicate_markers .person_a_id / .person_b_id ──FK──► genealogy_persons.id  CASCADE
                      UNIQUE(person_a_id, person_b_id), pair stored in canonical order
```

**Removed from the model:** `persons`, `relationships` (legacy, migration-only from now on),
`sync_change_log`, and the `sync_status` / `version` / `last_synced_at` columns on all four v2
tables.

### Ownership rules
| Entity | Owner | Enforced by |
|---|---|---|
| Person | tree | `genealogy_persons.tree_id` NOT NULL + FK (RESTRICT) |
| Family | tree | `families_v2.tree_id` NOT NULL + FK (RESTRICT) |
| Child link | family (→ tree) | `family_children_v2.family_id` NOT NULL + FK |
| Event / media / note / to-do / surname event | person (→ tree) | `person_id` FK |
| Duplicate marker | the pair of people | the two person FKs |

Nothing is owned indirectly through a nullable or unenforced path.

### Delete actions, chosen per case (no blanket CASCADE)
| Reference | Action | Why |
|---|---|---|
| `*.tree_id → family_trees` | **RESTRICT** | a tree holding people can never be deleted into an orphaned state |
| `families_v2.husband_id / wife_id → persons` | **RESTRICT** | a person who is still a partner must not be hard-deleted |
| `family_children_v2.family_id → families_v2` | **RESTRICT** | a family that still claims children must be dissolved explicitly |
| `family_children_v2.child_id → persons` | **RESTRICT** | parentage is not silently destroyed |
| `events/media_items/research_notes/todos/surname_events.person_id` | **RESTRICT** | same |
| `surname_events.related_person_id / related_event_id` | **SET NULL** | auxiliary pointers; losing the target must not destroy the record |
| `genealogy_persons.merged_into_id → persons` | **SET NULL** | a merge pointer is metadata |
| `duplicate_markers.person_a_id / person_b_id` | **CASCADE** | the marker describes the pair and is meaningless without it |

### Uniqueness
- `family_children_v2`: `UNIQUE(family_id, child_id)` — a child appears once per family.
- `families_v2`: `UNIQUE(husband_id, wife_id)` — the same couple is one row. (SQLite treats NULLs as
  distinct, so *single-parent* family duplication is prevented in `RelationshipRepository`, which
  always reuses an existing family; drift 2.33 cannot declare a partial index.)
- `duplicate_markers`: `UNIQUE(person_a_id, person_b_id)` plus canonical ordering in the repository,
  so marking a pair in either argument order is one marker.
- `genealogy_persons.uuid`, `families_v2.uuid`, `family_children_v2.uuid`, `surname_events.uuid`.

### Indexes
Declared on the tables with `@TableIndex` (13 indexes), so `createAll()` and the upgrade path both
produce them. Verified by test on **both** a fresh database and an upgraded one — the fresh/upgraded
divergence that the audit flagged is gone.

`idx_family_trees_root_person` · `idx_genealogy_persons_tree_id` ·
`idx_genealogy_persons_merged_into` · `idx_families_v2_tree_id` · `idx_families_v2_husband_id` ·
`idx_families_v2_wife_id` · `idx_family_children_v2_child_id` · `idx_events_person_id` ·
`idx_media_items_person_id` · `idx_research_notes_person_id` · `idx_todos_person_id` ·
`idx_surname_events_person_id` · `idx_duplicate_markers_person_b`

---

## 2. Repository API: the ambiguity is gone

| Before | After |
|---|---|
| `deleteRelationship(String id)` — id could be a family **or** a child link | `removeParentChildLink(String linkId)`, `dissolveFamily(String familyId, {removeChildLinks})` |
| `Relationship` — one type whose `id` and `relationshipType` decided what it meant | `ParentChildRelationship` {linkId, familyId, parentId, childId, relationshipType, birthOrder} and `Partnership` {familyId, treeId, husbandId, wifeId, marriageDate, isPrimary} |
| `watchRelationshipsByTree` / `getRelationshipsByTree` | `watchParentChildRelationships(treeId)` / `getParentChildRelationships(treeId)` and `watchPartnerships(treeId)` / `getPartnerships(treeId)` |
| `watchRelationshipsForPerson` typed `Stream<void>` | `Stream<List<FamiliesV2Data>>` (the rows it actually carries) |
| `markAsDuplicate` inserted whatever order it was given | normalises the pair, validates both people exist and share the tree |
| `createFamily` / `addSpouseRelationship` / single-parent creation | all take `treeId`; families cannot be created without an owner |

New file: `lib/data/models/relationship_edges.dart` (the two edge types).

---

## 3. Migration v11 → v12

`_upgradeToCanonicalSchema`:
1. absorb any lingering legacy tables (raw SQL, no model classes);
2. ensure the default tree row exists, then repair data the new constraints would reject
   (duplicate couples/families, partner slots pointing at missing people, orphan child links,
   bad tree ids, self/duplicate markers, stale root pointers);
3. `alterTable` each changed table — this drops the removed columns, adds the foreign keys and
   re-creates the schema-declared indexes;
4. backfill the new mandatory `families_v2.tree_id` through a `columnTransformer`;
5. `DROP TABLE` for `persons`, `relationships`, `sync_change_log`.

`lib/data/database/app_database.dart` no longer has any drift table class for the legacy tables:
the absorption code is raw SQL guarded by `_tableExists`, so a database that never had them is
untouched.

### Two long-standing migration defects resolved here
- **Legacy partner rows are migrated.** The old filter matched only `'marriage'` while the legacy
  vocabulary was `'spouse'`, so every marriage was silently dropped and then the source table was
  deleted. Both literals are accepted now (test: `'spouse'` and `'marriage'` both produce the
  couple).
- **Ambiguous parentage no longer aborts the upgrade.** The single-parent lookup used
  `getSingleOrNull()` and threw `StateError` as soon as a parent had two families — with drift *not*
  wrapping `onUpgrade` in a transaction, that left committed partial work behind and a retry that
  silently finished incompletely. The resolution is now explicit: exact couple match, else an
  existing single-parent family, else create. The test seeds exactly that ambiguous shape and asserts
  every child keeps its link and `user_version` reaches 12.

---

## 4. Files changed

**Schema (12 files)** — `family_trees_table.dart`, `genealogy_persons_table.dart`,
`families_v2_table.dart`, `family_children_v2_table.dart`, `events_table.dart`,
`media_items_table.dart`, `research_notes_table.dart`, `todos_table.dart`,
`surname_events_table.dart`, `duplicate_markers_table.dart`, `app_database.dart`,
`app_database.g.dart` (regenerated).

**Deleted (5)** — `tables/persons_table.dart`, `tables/relationships_table.dart`,
`tables/sync_change_log_table.dart`, `daos/person_dao.dart`, `daos/person_dao.g.dart`.
Also removed as hygiene: `scratch/new_canvas.dart` (the abandoned file that produced 64 of the
analyzer's issues) and `scratch/audit/diagnose_migration_partial_test.dart` (the H2 diagnostic,
whose defect is now fixed).

**Added** — `lib/data/models/relationship_edges.dart`, `test/support/test_database.dart`,
`test/data/schema_test.dart`, `test/data/migration_test.dart`.

**Modified (9)** — `genealogy_repository.dart`, `relationship_repository.dart`,
`dashboard_providers.dart`, `integrity_check_providers.dart`, `gedcom_importer.dart`,
and the four remaining test files.

**Regenerated** — `app_database.g.dart` and the three DAO `.g.dart` files via
`dart run build_runner build --delete-conflicting-outputs`. No generated file was edited by hand.

---

## 5. Tests

| File | Tests | Notes |
|---|---|---|
| `test/data/schema_test.dart` | 21 | **new** — physical table set, ownership FKs, delete actions, semantic uniqueness, indexes |
| `test/data/migration_test.dart` | 10 | **new** — real v11 file upgraded to v12, legacy absorption, index parity |
| `test/data/person_write_test.dart` | 15 | updated (tree fixture; `version` assertion removed with the column) |
| `test/data/relationship_delete_test.dart` | 15 | updated (tree fixture) |
| `test/data/merge_transaction_test.dart` | 10 | updated (tree fixture) |
| `test/features/duplicates/merge_test.dart` | 5 | updated to the explicit relationship API |
| `test/features/gedcom/gedcom_importer_test.dart` | 1 | updated (tree fixture) |
| `test/features/gedcom/gedcom_parser_test.dart` | 2 | unchanged |
| `test/widget_test.dart` | 1 | unchanged |

**Removed:** `schema_shape_characterization_test.dart` (10) and
`migration_characterization_test.dart` (6) — both documented the pre-redesign schema and migration,
which no longer exist; their subject matter is now covered by the two new suites asserting the
intended behaviour.

---

## 6. Phase report

- **Files changed:** see §4 — 12 schema files (1 regenerated), 3 deletions, 4 additions, 9 modifications.
- **Schema changes:** `schemaVersion` 11 → **12**. Legacy tables and `sync_change_log` dropped; sync
  columns dropped from the v2 tables; mandatory tree ownership on people and families; foreign keys
  and delete actions throughout; `UNIQUE(husband_id, wife_id)` and
  `UNIQUE(person_a_id, person_b_id)` added; 13 schema-declared indexes.
- **API changes:** see §2 — the ambiguous relationship API is replaced by typed operations and two
  edge types; `createFamily`/`addSpouseRelationship`/`addParentChildRelationship` are tree-aware;
  `markAsDuplicate` normalises and validates.
- **Tests added/changed:** 2 new suites (31 tests), 5 updated, 2 characterization suites removed.
- **Test count:** **80 passing / 0 failing / 0 skipped** (`flutter test`), up from 65.
- **Analyzer:** **18 issues**, all pre-existing and all non-error (deprecated drift web API, `rxdart`
  not declared, GEDCOM string interpolation, dead code in three files, unused imports, one
  `BuildContext` across an async gap). Down from 83 — the drop is mostly the deleted
  `scratch/new_canvas.dart`. **0 errors in `lib/` and `test/`.**
- **Build:** `flutter build web --debug` → **success** (`√ Built build\web`, 64.3 s).
- **Remaining risks:**
  1. `families_v2.tree_id` is backfilled with the default tree id on upgrade. Correct for every
     database this app has produced (one tree only), and a wrong value fails loudly through the FK
     rather than silently — but a real multi-tree database would need a mapping step.
  2. Duplicate *single-parent* families are prevented in the repository, not by the database
     (drift 2.33 cannot declare a partial unique index). Documented in the table.
  3. `family_trees.root_person_id` is not a foreign key: it would close a table-level cycle with
     `genealogy_persons.tree_id`, which drift resolves by dropping one constraint — silently removing
     the mandatory ownership key. Ownership won; the root pointer is validated in the repository and
     cleaned up during migration.
  4. `citations` / `citation_links` were left as they are: a polymorphic, currently unused feature
     with no producers or consumers, and out of scope for this phase.
  5. `restorePerson` still restores only the person row (links removed by the cascade are not
     rebuilt) — unchanged from Phase 1, still needs an audit trail.
  6. `rxdart` is still used without being declared in `pubspec.yaml`.
  7. No sync engine, as instructed: the related columns and table were removed rather than faked.
- **Commit hash:** see the commit that carries this file.
