# VanshVriksh — Final Data Layer Audit

**Date:** 2026-09-21 · **Schema version:** 14 · **Branch:** `main`
**Method:** every claim below was re-read from the repository and re-verified by running the code —
nothing is carried over from the original audit. The machine-checked evidence is the test suite; the
toolchain was run in full (formatter, analyzer, tests, build).

---

## 1. Final architecture

```
FamilyTree  (family_trees)                       ← the ownership root
│   id · tree_name · description · root_person_id* · created_at · updated_at
│                                                     * optional pointer to a person
│
├── Person                      genealogy_persons
│     id (immutable row identity) · uuid (stable identity beyond the row)
│     names (first/middle/last/birth/married/prefix/suffix/nickname, display-name format)
│     gender · birth date+qualifier+place+lat/lng · death date+qualifier+place+lat/lng
│     is_living (derived from death date) · profile_photo_path
│     biography · notes · occupation · religion · ethnicity
│     is_private · privacy_level
│     tree_id ──FK──► family_trees        NOT NULL, RESTRICT
│     merged_into_id ──FK──► persons      SET NULL   (retired duplicate → survivor)
│     is_deleted (soft delete) · created_at · updated_at
│
├── Family                      families_v2
│     id · tree_id ──FK──► family_trees   NOT NULL, RESTRICT
│     ├── Partners
│     │     husband_id ──FK──► persons    RESTRICT        ┐ UNIQUE(husband_id, wife_id)
│     │     wife_id    ──FK──► persons    RESTRICT        ┘ (the couple exists once)
│     ├── Children              family_children_v2
│     │     family_id ──FK──► families_v2      RESTRICT   ┐ UNIQUE(family_id, child_id)
│     │     child_id  ──FK──► genealogy_persons RESTRICT  ┘ (a child appears once)
│     │     birth_order · relationship_type (biological/adopted/foster/step)
│     │     child_surname_at_birth · paternal/maternal_relationship · notes
│     │     is_deleted · created_at · updated_at
│     └── marriage/divorce date+qualifier+place · surname-change flags · is_primary_marriage
│         relationship_type · notes · private_notes · is_deleted · created_at · updated_at
│
└── Other tree-owned entities   (ownership path in brackets)
      Events          events            [person_id → persons, RESTRICT]
      Media items     media_items       [person_id → persons, RESTRICT]
      Research notes  research_notes    [person_id → persons, RESTRICT, nullable]
      Surname history surname_events    [person_id → persons, RESTRICT]
      Duplicate marks duplicate_markers [person_a_id / person_b_id → persons, CASCADE]

  Removed from the model (and dropped by the migration if a database still has them):
      persons, relationships (pre-v10 legacy), sync_change_log, citations, citation_links, todos
```

**Nine tables**, sixteen foreign keys, fourteen indexes. There is no generic "relationship" table:
a partnership *is* a family row, and parentage *is* a child link.

---

## 2. Final integrity matrix

Read from a live database (`PRAGMA foreign_key_list` plus column/index/constraint introspection):

| Table → Table | Column | Delete | Update | Nullable? | Unique? | Indexed? |
|---|---|---|---|---|---|---|
| `genealogy_persons → family_trees` | `tree_id` | **RESTRICT** | NO ACTION | NOT NULL | – | ✔ |
| `genealogy_persons → genealogy_persons` | `merged_into_id` | **SET NULL** | NO ACTION | nullable | – | ✔ |
| `family_trees → genealogy_persons` | `root_person_id` | **SET NULL** | NO ACTION | nullable | – | ✔ |
| `families_v2 → family_trees` | `tree_id` | **RESTRICT** | NO ACTION | NOT NULL | – | ✔ |
| `families_v2 → genealogy_persons` | `husband_id` | **RESTRICT** | NO ACTION | nullable | ✔ with `wife_id` | ✔ |
| `families_v2 → genealogy_persons` | `wife_id` | **RESTRICT** | NO ACTION | nullable | ✔ with `husband_id` | ✔ |
| `family_children_v2 → families_v2` | `family_id` | **RESTRICT** | NO ACTION | NOT NULL | ✔ with `child_id` | ✔ (unique prefix) |
| `family_children_v2 → genealogy_persons` | `child_id` | **RESTRICT** | NO ACTION | NOT NULL | ✔ with `family_id` | ✔ |
| `events → genealogy_persons` | `person_id` | **RESTRICT** | NO ACTION | NOT NULL | – | ✔ |
| `media_items → genealogy_persons` | `person_id` | **RESTRICT** | NO ACTION | NOT NULL | – | ✔ |
| `research_notes → genealogy_persons` | `person_id` | **RESTRICT** | NO ACTION | nullable | – | ✔ |
| `surname_events → genealogy_persons` | `person_id` | **RESTRICT** | NO ACTION | NOT NULL | – | ✔ |
| `surname_events → genealogy_persons` | `related_person_id` | **SET NULL** | NO ACTION | nullable | – | ✔ |
| `surname_events → events` | `related_event_id` | **SET NULL** | NO ACTION | nullable | – | ✔ |
| `duplicate_markers → genealogy_persons` | `person_a_id` | **CASCADE** | NO ACTION | NOT NULL | ✔ with `person_b_id` | ✔ (unique prefix) |
| `duplicate_markers → genealogy_persons` | `person_b_id` | **CASCADE** | NO ACTION | NOT NULL | ✔ with `person_a_id` | ✔ |

**Rule behind the actions:** RESTRICT wherever the reference is ownership or lineage; SET NULL for
auxiliary pointers (tree root, surname-event targets, merge pointer); CASCADE only where the row is
metadata about a pair that no longer exists (duplicate markers). No foreign key uses CASCADE for data.

**Unique constraints:** couples (`husband_id, wife_id`), child links (`family_id, child_id`), duplicate
markers (`person_a_id, person_b_id`) and `genealogy_persons.uuid`.

**Indexes (14):** one for every foreign-key column that needs it, plus the tree/merge lookups:
`idx_genealogy_persons_tree_id`, `idx_genealogy_persons_merged_into`, `idx_families_v2_tree_id`,
`idx_families_v2_husband_id`, `idx_families_v2_wife_id`, `idx_family_children_v2_child_id`,
`idx_family_trees_root_person`, `idx_events_person_id`, `idx_media_items_person_id`,
`idx_research_notes_person_id`, `idx_surname_events_person_id`,
`idx_surname_events_related_person_id`, `idx_surname_events_related_event_id`,
`idx_duplicate_markers_person_b`.

**Rules the schema cannot express** (repository-enforced, and documented rather than hidden): at most
one *primary* partnership per person; no duplicate parentage across two families; no duplicate
single-parent family (drift 2.33 has no partial unique index).

---

## 3. Final migration matrix

| Old schema | What it had | What the upgrade does | Result |
|---|---|---|---|
| v1–v9 (legacy) | `persons`, `relationships` (real FKs), plus partial event/note/media tables | creates every canonical table, extends `persons` with the columns the import reads, imports people (+ surname history) and relationships (all confirmed partner values), ensures the ownership root, repairs rows the new constraints would reject, rebuilds every canonical table, drops the legacy tables | **v14** |
| v10–v11 | canonical tables + `sync_status`, `version`, `last_synced_at`, `sync_change_log` | drops the sync columns and tables while rebuilding | **v14** |
| v12 | canonical tables, `persons`/`relationships` dropped, but `citations`, `citation_links`, `todos` still present and unused | rebuilds, then `DROP TABLE IF EXISTS` for the three unused tables | **v14** |
| v13 | v12 + integrity indexes/foreign keys; `uuid` on families, child links and surname events | rebuilds; the redundant `uuid` columns are gone | **v14** |
| v14 (current) | — | reference schema | **v14** |

The upgrade is **one deterministic routine** for every older version, wrapped in drift's migration
transaction, ending with a verification step that throws (rolling everything back) if any imported
parentage or partner row cannot be found afterwards. Fresh, migrated and *declared* schemas are proven
identical by `schema_verification_test.dart`, and the migration matrix above is what
`migration_test.dart` / `migration_parity_test.dart` exercise.

---

## 4. Final test report

```
Formatter:   dart format --output=none --set-exit-if-changed lib test
             → 120 files checked, 0 changed (clean)

Tests:       flutter test
Passed:      177
Failed:      0
Skipped:     0

Analyzer:    flutter analyze --no-pub
             18 issues, 0 errors, 0 warnings in test/
             → 8 pre-existing warnings (dead code ×3 files, unused imports ×3 files,
               drift web deprecation, rxdart not declared) + 10 infos. None introduced
               by the data-layer work.

Build:       flutter build web --debug
             → success (√ Built build\web, 69.0 s)

Schema verification:
  Fresh DB:     6/6 checks pass — tables, columns (name/nullability/PK/default),
                indexes (set equality), foreign keys (with delete actions),
                UNIQUE constraints, schema version
  Migrated DB:  4/4 pass — from v12, v11, a sparse legacy v7 and a legacy database
                carrying data; every one equals the declared schema, and their
                fingerprints equal a fresh database's
```

**Suite inventory (177 tests):**

| Suite | Tests | What it proves |
|---|---|---|
| `deletion_matrix_test` | 31 | every delete/remove/purge path and its limits |
| `integrity_constraints_test` | 28 | the constraints themselves, via raw SQL that bypasses the repositories |
| `relationship_repository_test` | 24 | partner and parentage rules |
| `merge_contract_test` | 23 | the merge contract, incl. fault injection for mid-merge failure |
| `domain_invariants_test` | 17 | 17 invariants, their detection proof, and post-operation checks |
| `person_write_test` | 15 | write semantics |
| `migration_test` | 10 | legacy import behaviour |
| `merge_transaction_test` | 9 | merge preview and adjacent facets |
| `schema_verification_test` | 6 | fresh + migrated == declared schema |
| `migration_parity_test` | 5 | ambiguity preserved, failed migration rolls back |
| `features/duplicates/merge_test` | 5 | merge at feature level |
| `features/gedcom/*` | 3 | GEDCOM parsing and import |
| `widget_test` | 1 | app-shell smoke |

**Area-by-area verification** (each area the brief listed, and what checks it):

| Area | Verified by |
|---|---|
| Schema, tables, FKs, indexes, uniqueness | `schema_verification_test` (against the declared schema) + `integrity_constraints_test` (matrix asserted per table from `PRAGMA`) |
| Migrations | `migration_test`, `migration_parity_test`, `schema_verification_test` |
| DAOs / repositories / providers | the behaviour suites above, plus the analyzer (0 errors) and the inventory in §5 |
| Transactions | `merge_contract_test` (fault injection), `deletion_matrix_test`, `domain_invariants_test` post-operation checks |
| Delete semantics | `deletion_matrix_test` (31) |
| Merge semantics | `merge_contract_test` (23) |
| Relationship semantics | `relationship_repository_test` (24) |
| Tree ownership | `integrity_constraints_test` (RESTRICT on tree deletion), `domain_invariants_test` (no orphaned tree-owned data), `schema_verification_test` |
| Database lifecycle | `database_provider` disposes the handle; every database test closes its database in `tearDown` |

---

## 5. Re-inspected inventory

```
tables (9)      duplicate_markers · events · families_v2 · family_children_v2 · family_trees
                genealogy_persons · media_items · research_notes · surname_events
daos (6)        events · family_tree · genealogy_person · media · relationship · research_notes
repositories(6) events · family_tree · genealogy · media · relationship · research_notes
providers (10)  database · backup_service · events_repository · family_tree_repository
                genealogy_repository · image_storage · media_repository · media_storage
                relationship_repository · research_notes_repository
models (2)      family_graph · relationship_edges
schemaVersion   14
```

No dead table, no DAO without a repository, no repository without a provider or a consumer, and no
unreferenced provider (each is imported where it is used — checked when the unused tables were removed
in the previous phase).

## 6. Changes made during this audit

The brief allows changes only to fix a discovered correctness issue. Two mechanical, non-architectural
changes were made:

1. **`dart format`** across `lib/` and `test/` — 68 files reformatted. This is the formatter the brief
   asked to run; the repository was not formatter-clean before (68 of 120 files), so the audit brought
   it to a state where `--set-exit-if-changed` passes.
2. **One brace fix** in `gedcom_importer.dart`: the formatter collapsed an `if` onto one line, which
   tripped `curly_braces_in_flow_control_structures`. Wrapping the statement restored the analyzer to
   its 18-issue baseline with zero errors.

No schema, API, behaviour or architecture was changed.

---

## 7. Remaining risks

1. **Migrations are import-only and one-shot.** A pre-v10 database is imported once and its legacy
   tables are dropped; a later bug in the import cannot be re-run against the original data. Back up
   such a database before opening it with this build.
2. **Four domain rules cannot be database constraints** (one primary partnership, no duplicate
   parentage across families, no duplicate single-parent family, the polymorphic citation entity id —
   the last is moot since citations were removed). They live in the repository.
3. **`genealogy_persons.uuid` is still write-only.** Kept deliberately as the identity a future export,
   cross-database import or sync would need; it is the next candidate for removal if none appears.
4. **The UI still composes several atomic repository calls** for "save this person with these
   relationships". A failure between them leaves an incomplete — not corrupt — person.
5. **Dead UI island:** `lib/features/genealogy/**` plus `lib/app/genealogy_tree_page.dart` and six
   `/v2/*` routes are unreachable and were kept only because they are the sole writer of
   `custom_display_name` / `display_name_format`. File list recorded for a future removal.
6. **No CI.** The 177 tests only run when someone runs them; a workflow that runs
   `dart format --set-exit-if-changed`, `flutter analyze` and `flutter test` would lock in the state
   this audit establishes.
7. **Pre-existing analyzer noise** (18 non-errors) would be worth clearing now that the data layer is
   quiet: three dead-code sites, three unused imports, the deprecated drift web backend and the
   undeclared `rxdart` dependency.
8. **Cloud backup ≠ sync.** Google Drive backup uploads/downloads a whole encrypted snapshot; restoring
   replaces the database file with no merge path. Documented in the sync ADR.

---

## 8. Verdict

The data layer is now internally consistent and machine-verified: one canonical nine-table schema with
sixteen enforced foreign keys, a single deterministic and atomic upgrade path, one declaration of the
schema that both fresh and migrated databases are checked against, and 177 tests that assert
behaviour, constraints and invariants rather than implementation details. The items in §7 are the
honest remainder — none of them is a correctness defect in the current, local-first, single-user
configuration.

**Commit:** see the commit carrying this file.
