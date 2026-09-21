# VanshVriksh — Phase 1: Stop Active Data Corruption

**Scope executed:** C1 (person update), C2 (person delete), C3 (relationship delete),
H4 (merge transaction boundary) — the four defects that make ordinary use of the app corrupt
or refuse to persist data. Migration defects (H1/H2/H3) and tree deletion (H5) are **not** in
this phase: they need schema work and are explicitly deferred to Phase 2/3.

**Global rules honoured:** no compatibility shims were added for the old internal APIs; callers
were updated; DAOs were reduced to primitives; no Drift table changed, so no code generation was
needed and generated files were not edited; no unrelated code was refactored.

---

## Files changed

### Modified — production code (7)
| File | Change |
|---|---|
| `lib/data/database/daos/genealogy_person_dao.dart` | `replace()`-based writes replaced by keyed partial updates; soft-delete / restore primitives; added lookup helpers |
| `lib/data/database/daos/relationship_dao.dart` | all reads filter `is_deleted`; queries anchored on a deleted person return empty; removed unused import; collapsed an N+1 spouse query |
| `lib/data/repositories/genealogy_repository.dart` | `updatePerson` is now a keyed partial update; `deletePerson` is a transactional soft delete with explicit cascade rules; new `restorePerson`; merge wrapped in a transaction and extended; duplicate markers filtered |
| `lib/data/repositories/relationship_repository.dart` | `deleteRelationship` removed; `removeParentChildLink` + `dissolveFamily` added; both `add*` operations are transactional and validated |
| `lib/features/people/person_form_page.dart` | builds partial companions; `is_living` derived from the death date; photo attach touches one column |
| `lib/features/genealogy/genealogy_person_form_page.dart` | same partial-companion conversion |
| `lib/features/people/person_profile_page.dart` | destructive dialog now describes what the operation actually does |

### Added — tests (3)
- `test/data/person_write_test.dart` (15 tests)
- `test/data/relationship_delete_test.dart` (15 tests)
- `test/data/merge_transaction_test.dart` (10 tests)

### Added — documentation (1)
- `scratch/audit/phase1-data-layer.md` (this report)

### Removed (4)
- `test/data/characterization/person_write_characterization_test.dart` (8 tests documenting the old broken behaviour — superseded by `person_write_test.dart`)
- `test/data/characterization/relationship_delete_characterization_test.dart` (6 tests — superseded by `relationship_delete_test.dart`)
- `scratch/audit/verify_update_test.dart`, `scratch/audit/verify_data_layer_v2_test.dart` (pre-fix evidence scripts whose findings are now fixed; kept in git history)

---

## Schema changes

**None.** `schemaVersion` remains **11**. No table, column, index, foreign key or migration step
was added or modified. `lib/data/database/app_database.dart` and all `*.g.dart` files are untouched.

The soft-delete work reuses the `is_deleted` / `updated_at` columns the model already had on
`genealogy_persons`, `families_v2`, `family_children_v2` and `surname_events`.

---

## API changes

### `GenealogyPersonDao`
| Before | After |
|---|---|
| `updatePerson(GenealogyPersonsCompanion)` via `update().replace()` | `updatePersonFields(String id, Companion changes)` via `write()` |
| `deletePerson(String)` (hard delete) | `markPersonDeleted(String, DateTime)` / `restorePerson(String, DateTime)` |
| `updateFamily(Companion)` / `updateFamilyChild(Companion)` | `updateFamilyFields(id, changes)` / `updateFamilyChildFields(id, changes)` |
| — | `markFamilyDeleted`, `restoreFamily`, `markFamilyChildDeleted`, `restoreFamilyChild` |
| — | `getFamilyById`, `getFamilyChildLink(familyId, childId)`, `getAnyChildrenForFamily`, `removeFamilyChildLinkRow`, `getLivePeopleByIds` |

### `GenealogyRepository`
| Before | After |
|---|---|
| `updatePerson({30 named params, defaults on every nullable field})` → `Future<void>` | `updatePerson(GenealogyPersonsCompanion changes)` → `Future<bool>`; throws `ArgumentError` when the companion carries no id |
| `deletePerson(String)` → `Future<int>` (hard delete) | `deletePerson(String)` → `Future<void>`; transactional soft delete; throws `ArgumentError` for an unknown person |
| — | `restorePerson(String)` |
| `getDuplicateMarkers(treeId)` ignored its argument | filters by tree **and** excludes markers whose people are deleted |

### `RelationshipRepository`
| Before | After |
|---|---|
| `deleteRelationship(String id)` — id could be a family **or** a link | **removed** (no callers, breaking change accepted) |
| — | `removeParentChildLink(String linkId)` → `Future<int>` |
| — | `dissolveFamily(String familyId, {bool removeChildLinks = false})` → `Future<int>` |
| `addParentChildRelationship({treeId, parentId, childId})` | gained optional `familyId`; now transactional and throwing on self-link, unknown person, or an ambiguous parent |
| `addSpouseRelationship(...)` | transactional; rejects self-links, unknown people and deleted people |

### Write semantics (the core of C1)
`updatePerson` no longer accepts "the whole person"; it accepts only what changes. Fields the
caller omits are left untouched in the database, and the repository sets `updated_at` itself. This
removes both halves of the C1 defect: the missing `uuid` that made every write throw, and the
default-rewriting behaviour that made an incomplete write reset `is_living`, `display_name_format`,
`version`, and any nullable field the caller passed as explicit null.

---

## Tests added / changed

| File | Tests | Covers |
|---|---|---|
| `test/data/person_write_test.dart` | 15 | edits persist; untouched fields survive (including `is_living` on a deceased person); explicit null clears a field; `updated_at` maintained; missing id rejected; imports keep qualifiers; partner delete keeps the family/spouse/children; single-parent delete removes its family; child delete removes only the link; deleted people vanish from list/search/parents/children/siblings/spouses; child rows return on restore; unknown-person and double delete; markers of a deleted person are hidden |
| `test/data/relationship_delete_test.dart` | 15 | link removal is soft and idempotent; re-adding restores a removed link; `dissolveFamily` refuses while children exist and works with the explicit flag; childless dissolve; idempotency; unknown ids; self-parent / self-spouse / unknown / deleted person rejected; duplicate linking is a no-op; ambiguous parent requires an explicit family |
| `test/data/merge_transaction_test.dart` | 10 | previously dropped fields carried over; life status follows the merged death date; duplicate retired with `merged_into_id`; spouse family reassigned; the `UNIQUE(family_id, child_id)` collision path; `citation_links` repointed with clashing rows dropped, not overwritten; events/media/notes follow the survivor; self-merge, unknown person and validation failures leave the database untouched |

Untouched suites: `test/features/duplicates/merge_test.dart` (5), `test/features/gedcom/*` (3),
`test/widget_test.dart` (1) — all still pass without modification.
Still characterization (unchanged, documenting unfixed defects): `schema_shape_characterization_test.dart` (10),
`migration_characterization_test.dart` (6).

---

## Test count

| Metric | Before Phase 1 | After Phase 1 |
|---|---|---|
| Total tests | 39 | **65** |
| Passed | 39 | **65** |
| Failed | 0 | **0** |
| Skipped | 0 | **0** |
| Command | `flutter test` | `flutter test` |

Net +26: 14 characterization tests removed (their subject is fixed), 40 regression tests added.

## Analyzer result

`flutter analyze --no-pub` → **83 issues** (was 84; one pre-existing unused-import warning in
`relationship_dao.dart` disappeared with the rewrite).

- `lib/`: **0 errors**, 19 inform/warning (all pre-existing: deprecated drift web backend,
  undeclared `rxdart`, dead code in settings/profile/list, unused imports in tree pages)
- `test/`: **0 issues**
- `scratch/new_canvas.dart`: 64 (all the hard errors; deleting that file or excluding `scratch/`
  is still the outstanding hygiene item)

## Build result

`flutter build web --debug` → **success** (`√ Built build\web`, 87.9 s). The wasm dry-run still
reports `dart:ffi unsupported` for `package:sqlite3` — expected for the native drift path, unchanged
by this phase.

---

## Remaining risks

1. **Migration is still dangerous (Phase 2).** H1 (legacy `'spouse'` rows are dropped), H2 (the
   ambiguous `getSingleOrNull()` aborts a non-transactional `onUpgrade` and the retry silently
   completes with the unresolved links lost) and H3 (fresh vs upgraded schema/index divergence) are
   untouched. `onUpgrade` is still not wrapped in a transaction.
2. **Tree deletion still orphans silently (Phase 3).** `deleteFamilyTree` is unchanged; fixing it
   properly needs `families_v2.tree_id` and a real foreign key — a schema change.
3. **`restorePerson` restores only the person row.** Links removed by the delete cascade are not
   restored, because nothing records why a link was removed. Proper restore/purge semantics need an
   audit trail (Phase 5).
4. **Child tables still have no `is_deleted`.** A purge of a deleted person's events/media/notes/todos
   cannot be expressed yet; they are simply unreachable while the person is deleted.
5. **Behaviour change to verify in the UI:** `addParentChildRelationship` now throws instead of
   guessing when the parent belongs to several families. `person_form_page` does not pass
   `familyId`, so the "add a child for a parent with two marriages" flow will now surface an error
   rather than attach the child to an arbitrary family. Phase 2 should let the user pick the family.
6. **No provider invalidation added.** Repositories cannot invalidate Riverpod providers; stale
   profile/tree/dashboard refresh after a mutation is still open (Phase 2/6).
7. **Merge is atomic but untested against an injected mid-transaction failure.** With the softened
   clash check and the collision handling in place, no reachable constraint violation remains inside
   the merge body, so the atomicity test exercises the validation-failure path instead. A fault
   injection seam would be needed for a stronger test.
8. **`duplicate_markers` still has no foreign keys**, so a marker row can outlive the people it
   names; it is filtered out of queries now, but the row itself lingers.
9. Untouched by this phase: GEDCOM import/export, backup/restore and its cryptography, tree layout,
   platform permissions, unused dependencies, and the `scratch/new_canvas.dart` analyzer blocker.

---

## Commit hash

Phase 1 = **`fa0c90aba62c9dfae3984694f60cd4fbbdd76e50`**
(`refactor(data): Phase 1 — keyed writes, transactional soft delete, typed relationship removal`),
on `main`, preceded by the Phase 0 baseline commit `0aa3216`.
