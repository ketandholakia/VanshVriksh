# VanshVriksh — Database Integrity Matrix

**Phase:** dedicated integrity pass over every table in the genealogy model, with the constraints
themselves tested by operations that deliberately try to corrupt the data.

Schema version: **12 → 13** (the constraints and indexes below are new, so the migration rebuilds the
affected tables; the consolidated upgrade path already handles any older version).

---

## 1. The integrity matrix

`PK` = primary key · `FK` = foreign key · `R` = RESTRICT · `SN` = SET NULL · `C` = CASCADE

| Child table | Column | Parent | Delete | Update | Null? | Unique | Index |
|---|---|---|---|---|---|---|---|
| `genealogy_persons` | `tree_id` | `family_trees.id` | **R** | NO ACTION | **NOT NULL** | – | `idx_genealogy_persons_tree_id` |
| `genealogy_persons` | `merged_into_id` | `genealogy_persons.id` (self) | **SN** | NO ACTION | nullable | – | `idx_genealogy_persons_merged_into` |
| `genealogy_persons` | `uuid` | – | – | – | **NOT NULL** | **UNIQUE** | (auto) |
| `family_trees` | `root_person_id` | `genealogy_persons.id` | **SN** | NO ACTION | nullable | – | `idx_family_trees_root_person` |
| `families_v2` | `tree_id` | `family_trees.id` | **R** | NO ACTION | **NOT NULL** | – | `idx_families_v2_tree_id` |
| `families_v2` | `husband_id` | `genealogy_persons.id` | **R** | NO ACTION | nullable | `UNIQUE(husband_id, wife_id)` | `idx_families_v2_husband_id` |
| `families_v2` | `wife_id` | `genealogy_persons.id` | **R** | NO ACTION | nullable | (above) | `idx_families_v2_wife_id` |
| `families_v2` | `uuid` | – | – | – | **NOT NULL** | **UNIQUE** | (auto) |
| `family_children_v2` | `family_id` | `families_v2.id` | **R** | NO ACTION | **NOT NULL** | `UNIQUE(family_id, child_id)` | (unique prefix) |
| `family_children_v2` | `child_id` | `genealogy_persons.id` | **R** | NO ACTION | **NOT NULL** | (above) | `idx_family_children_v2_child_id` |
| `family_children_v2` | `uuid` | – | – | – | **NOT NULL** | **UNIQUE** | (auto) |
| `duplicate_markers` | `person_a_id` | `genealogy_persons.id` | **C** | NO ACTION | **NOT NULL** | `UNIQUE(person_a_id, person_b_id)` | (unique prefix) |
| `duplicate_markers` | `person_b_id` | `genealogy_persons.id` | **C** | NO ACTION | **NOT NULL** | (above) | `idx_duplicate_markers_person_b` |
| `events` | `person_id` | `genealogy_persons.id` | **R** | NO ACTION | **NOT NULL** | – | `idx_events_person_id` |
| `media_items` | `person_id` | `genealogy_persons.id` | **R** | NO ACTION | **NOT NULL** | – | `idx_media_items_person_id` |
| `research_notes` | `person_id` | `genealogy_persons.id` | **R** | NO ACTION | nullable | – | `idx_research_notes_person_id` |
| `todos` | `person_id` | `genealogy_persons.id` | **R** | NO ACTION | nullable | – | `idx_todos_person_id` |
| `surname_events` | `person_id` | `genealogy_persons.id` | **R** | NO ACTION | **NOT NULL** | – | `idx_surname_events_person_id` |
| `surname_events` | `related_person_id` | `genealogy_persons.id` | **SN** | NO ACTION | nullable | – | `idx_surname_events_related_person_id` |
| `surname_events` | `related_event_id` | `events.id` | **SN** | NO ACTION | nullable | – | `idx_surname_events_related_event_id` |
| `surname_events` | `uuid` | – | – | – | **NOT NULL** | **UNIQUE** | (auto) |
| `citations` | `image_media_id` | `media_items.id` | **SN** | NO ACTION | nullable | – | `idx_citations_image_media_id` |
| `citation_links` | `citation_id` | `citations.id` | **C** | NO ACTION | **NOT NULL** | PK `(citation_id, entity_type, entity_id)` | (PK prefix) |
| `citation_links` | `entity_id` | – (polymorphic, see §4) | – | – | **NOT NULL** | (above) | `idx_citation_links_entity_id` |

### Why those actions and not others
- **RESTRICT wherever the reference *is* ownership or lineage** (a person in a tree, a family in a
  tree, a partner, a child, a person-scoped record). Deleting a parent row must never destroy or
  quietly detach lineage; the application's own deletion is a soft delete, so RESTRICT only ever fires
  on a genuine mistake.
- **SET NULL for auxiliary pointers** — the tree root, a surname event's related person/event, a
  citation's image, and the merge pointer. Losing the target must not delete the record that merely
  referred to it.
- **CASCADE only where the row is metadata about a pair that no longer exists** — duplicate markers,
  and citation links without their citation. Nothing else cascades.

---

## 2. What this pass added

| Change | Why |
|---|---|
| **`family_trees.root_person_id` is now a foreign key** (`SET NULL`) | it was left unenforced because the trees↔people cycle made drift silently drop a reference — see below |
| `genealogy_persons.tree_id` declared as a **raw table constraint** | so *both* directions of that cycle are enforced: drift only sees one reference, so it has nothing to drop |
| `citations.image_media_id` → explicit `SET NULL` | was implicit `NO ACTION`, so media removal was blocked by a dead feature |
| `citation_links.citation_id` → explicit `CASCADE` | was implicit `NO ACTION`, leaving links pointing at a deleted citation |
| 4 new indexes | `idx_surname_events_related_person_id`, `idx_surname_events_related_event_id`, `idx_citations_image_media_id`, `idx_citation_links_entity_id` — every foreign-key column now has one |
| `schemaVersion` 12 → 13 | the constraints are new, and the consolidated upgrade path rebuilds the affected tables for any older database |

### The trees ↔ people cycle, resolved properly
`family_trees.root_person_id → genealogy_persons.id` and `genealogy_persons.tree_id → family_trees.id`
point at each other. Drift resolves such a cycle by dropping one reference, and the one it dropped was
the **mandatory ownership key on people** — leaving `tree_id` unconstrained. Declaring that key as a
raw `FOREIGN KEY (tree_id) REFERENCES family_trees (id) ON DELETE RESTRICT` inside
`customConstraints` means drift only manages the other direction, so nothing is dropped. Verified by
reading the generated DDL: both references are present, and a test asserts both.

---

## 3. Uniqueness the domain requires — and what cannot be a constraint

| Rule | Enforced by |
|---|---|
| Two people cannot share a uuid | `UNIQUE(uuid)` |
| The same couple cannot be stored twice | `UNIQUE(husband_id, wife_id)` + canonical slot ordering in the repository |
| A child appears at most once per family | `UNIQUE(family_id, child_id)` |
| The same pair of people cannot be marked twice | `UNIQUE(person_a_id, person_b_id)` + canonical ordering |
| One citation per target | PK `(citation_id, entity_type, entity_id)` |
| **At most one *primary* partnership per person** | **not expressible** — it is a per-person partial rule; enforced in the repository only |
| **A child may not have the same parent twice through two families** | **not expressible** without a trigger; enforced in the repository, and normalised during a merge |
| **Single-parent family duplication** | drift 2.33 cannot declare a partial unique index (`@TableIndex` has no `WHERE`); enforced in the repository |
| **`entity_id` in `citation_links`** | polymorphic by design — cannot be a foreign key |

These four are the honest gaps. They are listed rather than hidden, and each has a repository-level
rule plus (where it matters) a test.

---

## 4. Tests

New `test/data/integrity_constraints_test.dart` — **37 tests**, all using **raw drift operations to
bypass the repositories**, so they prove the schema (not the repository) prevents corruption:

| Group | Covers |
|---|---|
| The integrity matrix | one test per table asserting the exact foreign-key map (column → parent, delete action, update action) — the matrix above, in executable form |
| Dangling references | a person in a non-existent tree; a family in a non-existent tree; a non-existent partner on insert **and** on update; a child link to a non-existent family/child; five person-scoped tables pointing at a missing person; a marker with a missing person; a merge pointer to a missing survivor; a tree root that does not exist; a citation link without its citation; a citation image that does not exist |
| Delete actions | RESTRICT: tree with people, person in a family, family with child links. SET NULL: person → tree root, event → surname event pointer, media → citation image, survivor → `merged_into_id`. CASCADE: person → duplicate markers, citation → citation links |
| Uniqueness | duplicate uuid, duplicate couple, duplicate child link, duplicate marker pair, duplicate citation link |
| Nullability | raw `INSERT`s missing `first_name`, `tree_id`, a family's tree/uuid, a child link's `child_id` |
| Indexes | every foreign-key column and query path has an index; the unique constraints are backed by auto-indexes |

Each rejection test also asserts that the **failed operation changed nothing** where that is
observable, so a rejected write cannot leave half-applied state behind.

---

## 5. Phase report

- **Files changed:** `family_trees_table.dart`, `genealogy_persons_table.dart`, `citations_table.dart`,
  `citation_links_table.dart`, `surname_events_table.dart`, `app_database.dart` (schemaVersion 13),
  `app_database.g.dart` (regenerated), `test/data/integrity_constraints_test.dart` (new),
  `test/data/schema_test.dart` and `test/data/migration_test.dart` (updated to the new reality), plus
  this document.
- **Schema changes:** schemaVersion **13**; one new foreign key (tree root), explicit actions on the
  citation tables, four new indexes. `genealogy_persons.tree_id` is unchanged physically but is now
  declared so drift cannot drop it.
- **API changes:** none.
- **Tests added/changed:** 37 added; two updated (both asserted the pre-integrity state).
- **Test count:** **185 passing / 0 failing / 0 skipped** (was 148).
- **Analyzer:** 18 issues, 0 errors (unchanged, all pre-existing).
- **Build:** `flutter build web --debug` → **success** (`√ Built build\web`, 55.0 s).
- **Remaining risks:**
  1. Four domain rules still cannot be expressed as database constraints (§3) and rely on the
     repository; a direct SQL write can violate them.
  2. `foreign_keys` is enabled per connection in `beforeOpen`, and SQLite pragmas are per-connection —
     a connection opened outside drift would have them off.
  3. `citations` / `citation_links` remain an unused feature: their constraints are correct and tested,
     but nothing in the app writes them.
  4. The four dead `NO ACTION` defaults that remain (`updated_at`/`created_at` on some tables) are
     harmless but inconsistent with the explicit style used elsewhere.
- **Commit hash:** see the commit carrying this file.
