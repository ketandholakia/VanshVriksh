# VanshVriksh — The Merge Contract

**Phase:** person merging rebuilt as a first-class domain operation with an explicit contract,
returning what it did, and covered by a dedicated suite.

---

## 1. The contract

`GenealogyRepository.mergePeople({survivorId, duplicateId, preferred*Source})` → `MergeResult`.

### Survivor identity
The **caller** chooses the survivor; the operation never picks one. The survivor keeps its `id`,
`uuid`, `tree_id` and `created_at`. The duplicate is **retired, not erased**.

### UUID behaviour
The survivor's `uuid` is untouched. The duplicate's row keeps its own `uuid` — so an external
reference to that identity can still be resolved — and gains `merged_into_id = survivorId`. Nothing
merges or regenerates a UUID.

### Preconditions (all validated before anything is written)
different people · both exist · neither is deleted or already retired · **both in the same tree**.
The cross-tree rule is new: merging across trees would silently move person-scoped rows and families
between two ownership roots.

### Field conflict resolution
| Rule | Applies to |
|---|---|
| The survivor's value wins unless it is absent; then the duplicate's is taken | every optional text/date/place field, `profile_photo_path`, name parts, `custom_display_name` |
| A caller can override per field (`preferredBirthDateSource`, `preferredDeathDateSource`, `preferredBirthPlaceSource`, `preferredCurrentPlaceSource`, `preferredBioSource`, `preferredNotesSource`) | dates, places, biography, notes |
| Coordinates are filled from whichever record has them | lat/lng pairs |
| A non-default value beats the schema default | `display_name_format` (new) |
| Derived, not inherited | `is_living` = merged death date is null |
| Union, and the stricter level wins | `is_private` (OR), `privacy_level` (max) |
| Survivor's own | `id`, `uuid`, `tree_id`, `created_at`, `is_deleted = false`, `merged_into_id = null`, `updated_at = now` |

### Partnerships
The duplicate's partner slots move to the survivor, with three cases:
1. **Their own family** (both slots hold the two people being merged) — **retired**, because a family
   with the same person in both slots is not a relationship. Its children are re-homed onto a
   single-parent family of the survivor **only if it had children**.
2. **An overlapping partnership** (the survivor already has a family with the same other partner) —
   the redundant family is retired and its children move onto the surviving family, so no duplicate
   couple can exist afterwards.
3. **Otherwise** the duplicate's slot is reassigned to the survivor (the survivor inherits the
   marriage).

### Child relationships
The duplicate's child links move to the survivor. A link that already exists for the pair is
collapsed onto the existing row — `UNIQUE(family_id, child_id)` counts soft-deleted rows, so the
check considers them and un-deletes rather than colliding. After the structural work, a **new
normalisation step** removes surplus links: moving a *family* onto the survivor (rather than a link)
can leave one child linked through two of the survivor's families, which would record the same parent
twice. The child keeps one link, preferring the family that records a partner (more informative).

### Duplicate markers
A marker naming **both** people is resolved and removed. A marker naming the duplicate and a **third
person** is **rewritten onto the survivor** (canonically ordered, idempotent) rather than discarded —
the suspicion is information. Markers that never mentioned the duplicate are **left untouched**
(previously they were deleted whenever the survivor appeared in them).

### References from other tables
Repointed: surname events (as subject **and** as related person), events, media items, research
notes, **to-dos (new — they were left on a retired person, i.e. orphaned)**, citation links (handling
the composite primary key), and **a tree root that pointed at the duplicate (new)**.

### Deleted / merged state
Duplicate: `is_deleted = true`, `merged_into_id = survivorId`, `updated_at = now`.
Survivor: unchanged except the merged fields, `updated_at = now`.

### Sync / version behaviour
None exists: no sync engine, and since schema v12 no `sync_status` / `version` / `last_synced_at`
columns. A merge writes no sync state. This is stated rather than implemented, because the columns
were deliberately removed in the canonical-model phase.

### Atomicity
One transaction for the whole operation. Any failure rolls everything back — no partial merge, no
orphaned rows, no invalid references. **Proven by fault injection**: a SQLite trigger aborts the
`events` update, which is the *third* step, after the partnership and child-link steps have already
written; the test asserts that those earlier writes were undone and that the same merge succeeds once
the trigger is dropped.

### `MergeResult`
`(partnershipsMoved, partnershipsCollapsed, childLinksMoved, childLinksCollapsed,
duplicateMarkersRewritten, duplicateMarkersRemoved)` — the operation reports what it did instead of
returning `void`.

---

## 2. What was wrong before

| Defect | Fix |
|---|---|
| A family containing both people became a **self-relationship** with a cleared slot, or a meaningless leftover family | the own-family case is now recognised and retired, with its children re-homed |
| Overlapping partnerships (**same other partner**) hit `UNIQUE(husband_id, wife_id)` and failed the merge | detected and collapsed: children move, the redundant family is retired |
| **To-dos** were not repointed → orphaned on a retired person | repointed |
| A tree **root** pointing at the duplicate kept pointing at a retired person | repointed to the survivor |
| Markers between the survivor and an unrelated third person were **deleted** | left untouched |
| A marker between the duplicate and a third person was **deleted** | rewritten onto the survivor |
| `display_name_format` was never merged | non-default value wins |
| Cross-tree merges were allowed, moving rows between ownership roots | refused |
| A single parent's child could be **marked redundant and removed** mid-merge (the parentage existed in the family being retired) | the source family is retired *before* re-homing, so the check no longer sees it |
| A new empty single-parent family was created even with no children | created only when there are children to re-home |

---

## 3. Tests

New `test/data/merge_contract_test.dart` — **23 tests**:

| Group | Covers |
|---|---|
| Survivor identity / UUID | simple merge; survivor id/uuid/tree/created_at untouched; duplicate retired with its UUID retained; nothing hard-deleted |
| Field conflicts | survivor wins; gaps filled; caller override; life status from the merged death date; privacy union + stricter level; display-name format |
| Partnerships | different partnerships inherited; overlapping collapsed; own family retired with no self-relationship left |
| Children | children follow; duplicate parentage collapsed; children of the couple survive the retirement |
| Duplicate markers | pair resolved and third-party marker kept; unrelated marker untouched |
| Other references | events/media/notes/to-dos/surname events follow; tree root repointed |
| **Failure midway** | injected trigger aborts step 3; steps 1–2 rolled back; the merge succeeds afterwards |
| Repeated / invalid | second merge refused; retired survivor refused; self-merge refused; unknown person refused; cross-tree refused with nothing changed |

The existing `test/data/merge_transaction_test.dart` (10 tests) and
`test/features/duplicates/merge_test.dart` (5) still pass unchanged — they cover adjacent facets
(merge preview, source preference, link reassignment) and were not weakened or removed.

---

## 4. Phase report

- **Files changed:** `lib/data/repositories/genealogy_repository.dart` (merge rewritten: contract,
  `MergeResult`, three partnership cases, parentage collapse, marker rework, to-do/root repointing,
  hints), `test/data/merge_contract_test.dart` (new), plus this document.
- **Schema changes:** none. **Generated code:** untouched.
- **API changes:** `mergePeople` returns `MergeResult` instead of `void` (callers that `await` it are
  unaffected); new cross-tree precondition; new exported `MergeResult` and `defaultDisplayNameFormat`.
- **Tests added/changed:** 23 added; one expectation in the new suite corrected after the
  implementation bugs it exposed were fixed.
- **Test count:** **148 passing / 0 failing / 0 skipped** (was 125).
- **Analyzer:** 18 issues, 0 errors (unchanged, all pre-existing).
- **Build:** `flutter build web --debug` → **success** (`√ Built build\web`, 54.7 s).
- **Remaining risks:**
  1. Merging is still a *manual* decision: nothing prevents a user from merging two genuinely
     different people, and there is no un-merge (by design — see the delete-semantics document).
  2. The merge moves the duplicate's marriage to the survivor even when that marriage conflicts with
     the survivor's own current marriage; the result (two partnerships) is valid but only one can be
     "primary", and nothing enforces exactly one primary partnership.
  3. `MergeResult` is not surfaced in the UI yet: the duplicate screens still just refresh.
  4. `citation_links` is a dead feature, so its repointing is correctness-only and untested through
     any UI path.
- **Commit hash:** see the commit carrying this file.
