# VanshVriksh — Data-Layer Baseline & Architecture Map

**Phase:** baseline / mapping only. **No production code and no schema was modified in this phase.**
**Baseline commit:** `273fba0095c2cc10b9030f38b36449b97f8193f2` on `main` (Phase 1 landed in `fa0c90a`, Phase 0 baseline in `0aa3216`).

> Note: this baseline describes the data layer **as it currently stands, including Phase 0 and
> Phase 1**. Two of the defects an earlier audit listed as open (C1 person update, C2 person delete,
> C3 relationship delete, H4 untransacted merge) are already fixed on `main`; the schema, migrations
> and the remaining defects are untouched. Where a finding is already resolved, it is marked
> **[fixed in Phase 1]** so the map is not mistaken for the pre-Phase-1 state.

**Method:** read every non-generated file under `lib/data/**`, the migration code in `AppDatabase`,
the tree/person/family consumers, all tests; the physical schema and foreign-key graph were dumped
from a live database (see `test/data/characterization/schema_shape_characterization_test.dart`);
generated Drift code was read only for understanding. Toolchain re-run on this commit
(`flutter test`, `flutter analyze`, `flutter build web --debug`).

---

## 1. Entity map

| # | Concept | Lives in | Shape / notes |
|---|---|---|---|
| 1 | **Person model** | `genealogy_persons` (43 cols) — table def `lib/data/database/tables/genealogy_persons_table.dart` | Id, name parts incl. `birth_surname`/`married_surname`, `display_name_format`, `custom_display_name`, gender, birth/death date + **qualifier** + place + lat/lng, current place, `is_living`, `profile_photo_path`, biography/notes/occupation/religion/ethnicity, privacy (`is_private`, `privacy_level`), `tree_id`, and the bookkeeping block `uuid`, `sync_status`, `is_deleted`, `created_at`, `updated_at`, `last_synced_at`, `version`, `merged_into_id`. Legacy twin: `persons` (27 cols) |
| 2 | **Family model** | `families_v2` — `tables/families_v2_table.dart` | Two nullable partner slots `husband_id` / `wife_id` (both FK → `genealogy_persons`), marriage date+qualifier+place+lat/lng, divorce date+qualifier+place, surname-change flags (`wife_took_husband_name`, `husband_took_wife_name`, `hyphenated_surname`, `no_name_change`, `custom_surname_change`, `wife_married_surname`, `wife_name_change_type`, `husband_married_surname`, `husband_name_change_type`, reverts), `relationship_type` (default `'marriage'`), `is_primary_marriage`, notes/private notes, bookkeeping block. **No `tree_id`** |
| 3 | **Family-child relationship** | `family_children_v2` — `tables/family_children_v2_table.dart` | `family_id` FK → `families_v2`, `child_id` FK → `genealogy_persons`, `UNIQUE(family_id, child_id)`, `birth_order`, `relationship_type` (`'biological'`), `child_surname_at_birth`, `paternal_relationship`, `maternal_relationship`, notes, bookkeeping block |
| 4 | **Spouse / partner relationship** | A `families_v2` **row**, not an edge table | There is no separate spouse table. A couple *is* a family. Gender decides which slot each partner occupies; same-sex or unknown-gender pairs are written `husband=a, wife=b` in argument order. The renderer distinguishes "husband"/"wife" purely from the slot |
| 5 | **Tree ownership** | `family_trees.id` ← `genealogy_persons.tree_id` | `tree_id` is an **unconstrained TEXT column with no foreign key**. `families_v2`, `family_children_v2`, `events`, `media_items`, `research_notes` have no tree column at all — a family's tree is *derived* from the people in it (`RelationshipRepository._familiesInTree`) |
| 6 | **Tree root** | `family_trees.root_person_id` | Written by `FamilyTreeRepository.updateFamilyTree`, **read by nothing**. The app's actual root is a runtime selection: `selectedRootPersonIdProvider` → persisted optionally as `lastRootPersonIdProvider` (prefs). Effective root defaults to the first person alphabetically (`firstPersonProvider`) |
| 7 | **Person deletion** | `GenealogyRepository.deletePerson` — `genealogy_repository.dart:185-228` **[fixed in Phase 1]** | Transactional soft delete: person + their child links flagged `is_deleted`; a family with no other partner is soft-deleted with its links; a shared family survives. `restorePerson` reverts the person row only |
| 8 | **Family deletion** | `RelationshipRepository.dissolveFamily` **[fixed in Phase 1]**; `FamilyTreeRepository.deleteFamilyTree` (a *tree*, not a family) | `dissolveFamily` soft-deletes, refusing while live child links exist unless `removeChildLinks: true`. `deleteFamilyTree` is a bare `DELETE FROM family_trees` (`family_tree_dao.dart:40-42`) — succeeds silently and orphans every person in the tree, because nothing references `family_trees` |
| 9 | **Relationship deletion** | `RelationshipRepository.removeParentChildLink` / `dissolveFamily` — `relationship_repository.dart:131-186` **[fixed in Phase 1]** | Soft delete, typed. The earlier single `deleteRelationship(String)` that accepted either a family id or a link id is gone |
| 10 | **Person merge** | `GenealogyRepository.mergePeople` — `genealogy_repository.dart:296-520` **[fixed in Phase 1]** | One transaction, five steps: (1) move the duplicate's partner slots, (2) move/collapse child links, (3) repoint surname events (person **and** related person), events, media, notes, citation links, (4) merge person fields including the previously dropped ones, (5) retire the duplicate with `merged_into_id` and clear markers |
| 11 | **Duplicate markers** | `duplicate_markers` — `tables/duplicate_markers_table.dart` | `tree_id`, `person_a_id`, `person_b_id`, `reason`, `created_at`. **No foreign keys on either person column**, no `is_deleted`. Read paths now filter out markers whose people are deleted (`getDuplicateMarkers`) |
| 12 | **Sync / version fields** | `uuid`, `sync_status`, `is_deleted`, `created_at`, `updated_at`, `last_synced_at`, `version`, `merged_into_id` on the four v2 tables, plus the `sync_change_log` table | Only `uuid` (identity), `is_deleted`, `created_at`/`updated_at` and `merged_into_id` are actually used. `sync_status` is written as `'pending'` at insert and never read or advanced; `version` is always `1`; `last_synced_at` is never written; `sync_change_log` (`source_table_name`, `record_uuid`, `change_type`, `change_data`, `sync_status`, `device_id`) has **zero** producers and zero consumers |
| 13 | **Legacy structures** | `persons`, `relationships` (tables/modelled in `tables/persons_table.dart`, `tables/relationships_table.dart`) + `PersonDao` | Created by `createAll()` on a fresh install, **dropped** by the v10 migration on upgrade, read only by `_migrateLegacyPersonsToGenealogy` / `_migrateLegacyRelationshipsToFamilies`. `relationships` has real FKs into `persons` — the v2 model replaced them with no equivalent. `RelationshipTypes.spouse = 'spouse'` documents the old vocabulary while the migration looks for `'marriage'` |
| 14 | **Migration history** | `AppDatabase.migration` — `app_database.dart:58-141`, `schemaVersion = 11` | `onCreate`: `createAll()` only. `onUpgrade`: `from<3` creates events/citations/citation_links/research_notes/todos/sync_change_log; `from<4` adds `note_date_sort`/`note_date_display`; `from<5` duplicate_markers; `from<6` adds `birth_surname`/`married_surname` to persons; `from<7` creates genealogy_persons/surname_events/families_v2/family_children_v2; `from<8` copies persons → genealogy_persons (and synthesises surname events); `from<9` creates the 18 named `idx_*` indexes; `from<10` migrates legacy relationships into families_v2, alters events/media/notes/todos, **drops persons + relationships**; `from<11` alters genealogy_persons (adds `profile_photo_path`). `beforeOpen` sets `PRAGMA foreign_keys = ON` |
| 15 | **Database lifecycle / providers** | `lib/data/providers/*` | `databaseProvider` returns `AppDatabase()` with **no `ref.onDispose`** — the handle is never closed. Seven derived providers (`genealogyRepository`, `relationshipRepository`, `familyTreeRepository`, `eventsRepository`, `mediaRepository`, `researchNotesRepository`, service providers for image/media/backup storage) are trivial `Provider`s over it. Reads are drift `watch()` streams; `personRelationshipsProvider` (`people_providers.dart:26-30`) is the cache-invalidation stream, and it only watches `families_v2` |

---

## 2. Architecture diagram

### Physical schema and references (current, post-Phase-1)

```
                            family_trees (id, tree_name, description, root_person_id*, ...)
                                  *
                                  │  (no FK exists to this table from the v2 model)
                                  │
        ┌─────────────────────────┴───────────────────────────────────────────┐
        │  LEGACY PAIR — created by createAll(), DROPPED by the v10 migration │
        │                                                                     │
        │   persons ──────────FK──────┐                                       │
        │      ▲                      │                                       │
        │      │ FK                   │                                       │
        │   relationships (person_id, related_person_id, relationship_type)  │
        └─────────────────────────────────────────────────────────────────────┘

     genealogy_persons  (uuid, tree_id†, is_living, is_deleted, sync_status, version, ...)
            ▲    ▲
            │    │  FK  (ON DELETE NO ACTION — no cascade anywhere)
            │    └─────────────────────────────┐
            │                                  │
      families_v2                        family_children_v2
      (husband_id, wife_id,              (family_id ──FK──► families_v2,
       marriage/divorce, surname flags,   child_id  ──FK──► genealogy_persons,
       is_deleted, bookkeeping)           birth_order, relationship_type,
      ‡ no tree_id                        UNIQUE(family_id, child_id), is_deleted)

    person-scoped children of genealogy_persons (all FK, all ON DELETE NO ACTION,
    none of them has is_deleted):
        events, media_items, research_notes, todos, surname_events

    unrelated / weakly linked:
        citations ──FK──► media_items
        citation_links (citation_id, entity_type, entity_id)  ← polymorphic, no FK
        duplicate_markers (person_a_id*, person_b_id*)        ← * no FK
        sync_change_log (record_uuid*)                        ← * no FK, unused

    † genealogy_persons.tree_id has NO foreign key (the legacy persons.tree_id did)
    ‡ families_v2 has NO tree ownership column at all
```

### Write paths

```
UI (person_form_page / person_profile_page / genealogy_*)
   │  builds partial companions for updates
   ▼
GenealogyRepository ──────────────► GenealogyPersonDao ──► genealogy_persons / families_v2 /
   │  deletePerson  : 1 transaction (person + links + orphan-only family)   family_children_v2
   │  mergePeople   : 1 transaction (5 steps)
   │  addPerson/createFamily/addChildToFamily : 1 statement each
   ▼
RelationshipRepository ───────────► GenealogyPersonDao + RelationshipDao (reads)
   │  addParentChildRelationship / addSpouseRelationship : 1 transaction each
   │  removeParentChildLink / dissolveFamily             : 1 transaction each
   ▼
EventsRepository / ResearchNotesRepository / MediaRepository ──► single statements, no transaction
   (a UI flow such as "save person + link relationships" spans SEVERAL of these transactions)
```

---

## 3. Identified issues, by requested category

### 3.1 Duplicated concepts
1. **Two person tables.** `persons` (legacy) vs `genealogy_persons` (live). Both exist on a fresh install; only the legacy one is dropped on upgrade.
2. **Two relationship models.** `relationships` (legacy edge list with real FKs) vs `families_v2` + `family_children_v2` (live). `RelationshipRepository._buildRelationships` re-derives legacy `Relationship` objects at read time so dashboard/integrity code can keep running.
3. **Two DAOs for one concept family.** `PersonDao` (legacy table, no live callers) and `GenealogyPersonDao` (live).
4. **Fact storage split.** `events` (with `date_sort`/`date_display`/place/description) and `research_notes` (with `note_date_sort`/`note_date_display`) overlap in "dated person-scoped fact".
5. **Parent-role redundancy.** `family_children_v2.relationship_type` (`'biological'`) plus `paternal_relationship` / `maternal_relationship` express the same idea twice.
6. **Surname duplication.** `genealogy_persons.birth_surname` / `married_surname` vs the `surname_events` history table (the v8 migration writes both).
7. **Two feature trees in the UI over one data layer.** `/people` (live) and `/v2/people` (unreachable route, but its pages are the only writers of `custom_display_name`).

### 3.2 Missing foreign keys
| Column | Table | Consequence |
|---|---|---|
| `tree_id` | `genealogy_persons` | Any string is accepted; a deleted tree silently orphans people; the v1 `persons.tree_id` **did** have this FK |
| *(absent)* | `families_v2` | No tree ownership at all — derived from people |
| `root_person_id` | `family_trees` | No FK, and no reader |
| `person_a_id`, `person_b_id` | `duplicate_markers` | Markers can outlive the people they name |
| `entity_id` | `citation_links` | Polymorphic (`entity_type` + `entity_id`), unenforceable |
| `record_uuid` | `sync_change_log` | Points at nothing; the table is unused |
| `related_person_id`, `related_event_id` | `surname_events` | Free-text pointers |
| `profile_photo_path`, `file_path` | `genealogy_persons`, `media_items` | Filesystem paths with no integrity check; owned only by directory convention (`documents/profile_photos/`, `documents/person_media/<personId>/`) |

### 3.3 Missing ownership relationships
- Families have no tree → every tree query filters people first and then re-filters families in Dart (`_familiesInTree`), which scans **all** families.
- `family_trees.root_person_id` is a persisted root nothing reads.
- Media and profile photos are owned by directory naming, not by the database.

### 3.4 Ambiguous APIs
- **[fixed in Phase 1]** `deleteRelationship(String)` — one id, two entity types.
- **Still latent:** `EventsDao.updateEvent` (`events_dao.dart:19-21`) and `ResearchNotesDao.updateResearchNote` (`research_notes_dao.dart:19-21`) both use `update(...).replace(companion)`. They work today only because their repositories happen to supply every non-default non-nullable column; the same pattern is what broke person updates.
- `RelationshipRepository.watchRelationshipsForPerson` is declared `Stream<void>` but returns `Stream<List<FamiliesV2Data>>` (`relationship_repository.dart:236-240`) — a type lie that hides the real payload.
- `MediaDao.deleteMediaItem` / `EventsDao.deleteEvent` / `ResearchNotesDao.deleteResearchNote` hard-delete with no cleanup of the associated file or citations.

### 3.5 Unsafe deletes
- `FamilyTreeRepository.deleteFamilyTree` → bare row delete, silently orphans the whole tree (no FK to stop it, no cascade, no soft-delete column on `family_trees`).
- Hard deletes with side effects left behind: `deleteMediaItem` (file stays on disk, `citation_links.image_media_id` can still point at it), `deleteEvent`, `deleteResearchNote`.
- `removeFamilyChildLinkRow` hard-deletes a link row; only used inside merge to collapse a duplicate.

### 3.6 Incomplete transactions
- `GenealogyRepository.addPerson`, `createFamily`, `addChildToFamily` are single statements (fine in isolation), **but UI flows compose several of them**: `person_form_page._savePerson` creates a person and then creates relationships in a separate step — a failure between them leaves a person with no links, or a family with no children.
- GEDCOM import *is* transactional (`gedcom_importer.dart:148`) — the one good example.
- `AppDatabase.migration.onUpgrade` is **not** wrapped in a transaction by Drift (`GeneratedDatabase.beforeOpen` calls it directly). A throw mid-migration leaves committed partial work with `user_version` still at the old value, so the next launch retries and can silently finish incompletely.
- Aggregate rebuilds (`EventsRepository`, `MediaRepository`, `ResearchNotesRepository`) do no multi-row work, so nothing to wrap — but they also participate in the untransacted UI flows above.

### 3.7 Schema / index inconsistencies
- **Fresh ≠ upgraded.** `createAll()` builds 15 tables and zero named indexes; the 18 `idx_*` indexes exist only inside `if (from < 9)`, so a fresh install and a v9→v11 upgrade both end up unindexed, while a ≤v8 upgrade is indexed.
- Fresh installs keep the legacy `persons`/`relationships` tables that upgrades drop.
- `beforeOpen` enables foreign keys on every connection, which is what makes the missing `ON DELETE` clauses and the hard deletes fail loudly instead of silently — but only where FKs exist.

### 3.8 Legacy structures still in the tree
`persons`, `relationships`, `PersonDao`, `RelationshipTypes` (its `'spouse'` constant no longer matches the migration's `'marriage'` filter), and the doc comments in `relationships_table.dart` describing a table that no longer exists on upgraded databases.

### 3.9 Fields that look like sync but are not used
`sync_status` (written once, never read), `version` (always `1`), `last_synced_at` (never written), and the whole `sync_change_log` table (`change_data`, `sync_status`, `device_id`). There is no producer, no consumer and no scheduler behind any of them.

### 3.10 Tests that encode current behaviour vs intended domain behaviour
| Test | Encodes |
|---|---|
| `test/data/person_write_test.dart` (15) | **Intended domain behaviour** (Phase 1) |
| `test/data/relationship_delete_test.dart` (15) | **Intended domain behaviour** (Phase 1) |
| `test/data/merge_transaction_test.dart` (10) | **Intended domain behaviour** (Phase 1) |
| `test/features/duplicates/merge_test.dart` (5) | Intended behaviour (pre-existing, still valid) |
| `test/features/gedcom/*` (3) | Intended behaviour for the paths they cover |
| `test/widget_test.dart` (1) | Smoke only — asserts the startup spinner, not the dashboard |
| `test/data/characterization/schema_shape_characterization_test.dart` (10) | **Current, wrong** schema shape: legacy tables on fresh install, zero named indexes, no FK on `tree_id`, `NO ACTION` everywhere, no `is_deleted` on child tables, silent tree orphaning. These must be rewritten by Phase 3 |
| `test/data/characterization/migration_characterization_test.dart` (6) | **Current, wrong** migration behaviour: H1 drops `'spouse'` rows, H2 aborts and the retry completes with data loss. Must be rewritten by Phase 2 |

**Minimal characterization tests added in this phase: none.** The two characterization files already
in the repository cover every behaviour this baseline needed to verify (schema shape, FK graph,
indexes, migration outcomes), so adding more would only duplicate them.

---

## 4. Phase report (standing format)

- **Files changed (production):** none. **Schema:** none (`schemaVersion` stays 11, no generated file touched).
- **API changes:** none.
- **Tests added:** none. **Tests changed:** none. **Test count:** 65 passing / 0 failing / 0 skipped (`flutter test`).
- **Analyzer:** `flutter analyze --no-pub` → 83 issues; `lib/` 0 errors (19 inform/warning, all pre-existing), `test/` 0, `scratch/new_canvas.dart` 64 (all the hard errors).
- **Build:** `flutter build web --debug` → **success** (`√ Built build\web`, 60.5 s) on this baseline commit.
- **Remaining risks:** unchanged from the Phase 1 report — migration H1/H2/H3, tree-deletion orphaning, `restorePerson` coverage, child tables lacking `is_deleted`, no provider invalidation, `duplicate_markers` without FKs, and the `scratch/new_canvas.dart` analyzer blocker. This phase added no new risk: it changed no code.
- **Commit hash:** this document is committed on top of `273fba0`.

---

## 5. Suggested phase split implied by this map

1. **Phase 2 — migration hardening:** H1 literal, H2 ambiguity + wrap `onUpgrade` in an explicit
   transaction, verify counts before dropping legacy tables, v1/v7/v8 fixtures.
2. **Phase 3 — schema ownership:** declare indexes via `@TableIndex` (kills the fresh/upgraded
   divergence), `families_v2.tree_id` + FK, FK on `genealogy_persons.tree_id`, decide the delete
   actions, decide the fate of the legacy tables and the unused sync columns, then delete
   `scratch/new_canvas.dart`.
3. **Phase 4 — relationship integrity:** self/cycle guards, biological-parent rules, duplicate-family
   prevention (the DB cannot express them today).
4. **Phase 5 — purge / restore semantics:** `is_deleted` on child tables, audit trail so
   `restorePerson` can rebuild links, real tree deletion.
5. **Phase 6 — lifecycle & performance:** `ref.onDispose` on the database provider, tree-scoped
   relationship queries, removal of the N+1 loops in `tree_providers` and the per-node spouse query.
