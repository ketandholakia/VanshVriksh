# VanshVriksh — Definitive Delete Semantics

**Phase:** canonical deletion model. Every destructive operation is now explicitly classified and
enforced, and a dedicated deletion-matrix suite proves the behaviour.

## 0. One premise correction

The brief lists `isDeleted`, `version`, `syncStatus` and `mergedIntoId` as the schema's soft-delete
signals. `version` and `syncStatus` **no longer exist**: they were removed in the canonical-model
phase because nothing read them (no sync engine exists), so they were write-only fields that implied
a capability the app does not have. The surviving soft-delete signals are `isDeleted`, `mergedIntoId`
and the timestamp columns — and they do indicate soft deletion, which is what this phase implements.

---

## 1. The deletion model at a glance

| Entity | Mechanism | What it touches | Reversible |
|---|---|---|---|
| **Person** | **soft delete** | flags `genealogy_persons.is_deleted`; clears the person's partner slot in each family they belonged to. All other rows referencing them are left intact | **yes** — `restorePerson` |
| **Family (partnership)** | **soft delete** ("dissolve") | flags `families_v2.is_deleted`; only touches child links when the caller explicitly says so | **yes**, by re-adding |
| **Child link** | **relationship removal** (soft delete) | flags `family_children_v2.is_deleted`; nothing else | **yes** — re-adding the link restores the same row |
| **Tree, empty** | **hard delete** | the `family_trees` row | no (nothing else exists) |
| **Tree, populated** | **refuse**, or **purge** (hard delete, explicit) | the tree row plus every owned record, in one transaction | **no** — this is the only destructive operation |
| **Merge** | **archival** | flags the duplicate `is_deleted` and records `merged_into_id` | no (un-merge unsupported) |

Not used anywhere: silent cascade. `CASCADE` exists only on `duplicate_markers`, where the marker is
metadata about a pair and is meaningless without it. Every other reference is `RESTRICT`, so an
accidental hard delete fails loudly instead of destroying lineage.

---

## 2. Person deletion

**Decision: a person is normally soft-deleted.** `deletePerson` runs in one transaction and:

1. flags the person;
2. clears their slot in each family they were a partner of, and when a family is left with **no**
   partner — meaning it existed only for that person — the family *and its child links* are flagged
   too.

Nothing is hard-deleted, and rows that merely reference the person (child links where they are the
child, events, media, research notes, to-dos, surname events) are **not** touched, so a delete does
not cascade at all.

**Why clear the slot instead of keeping it.** Keeping a deleted person in a family's partner slot is
a trap: the family is still "live" for the surviving spouse, so the next child added to that parent
would silently acquire the deleted person as a parent. Clearing the slot means the surviving spouse
keeps the family (their marriage and their children keep their place) and new children attach to a
family that only names living people.

**Read visibility.** A deleted person must not appear in normal genealogy queries, which is enforced
in two layers:
- the DAO filters `is_deleted = false` on people, families and child links;
- a query *anchored* on a deleted person returns nothing at all, because the person is not in the
  tree any more;
- the tree-scoped read models (`getPartnerships`, `getParentChildRelationships`) additionally drop
  anything whose person is no longer live, so a partnership or edge can never surface a removed
  person.

**Coherence with history and merges.**
- A merged person is flagged deleted *and* points at the survivor. Deleting or restoring them is
  refused with a message naming the survivor: un-merging is a separate operation with its own
  integrity rules, and inventing one here would silently split a merged identity back apart.
- Deleting the survivor leaves the merge record intact (`mergedIntoId` still points at it).
- Deleting an already-deleted person is a no-op; an unknown id is an `ArgumentError`.

**Restore.** `restorePerson` flags the person back in. Partner slots cleared by the delete are *not*
rebuilt — nothing records whether a membership was removed by a delete or deliberately, and guessing
would invent relationships. Restoring is therefore "the person is back in the tree", not "the person
is back exactly as before".

---

## 3. Family deletion

`dissolveFamily(familyId, {removeChildLinks = false})`, always transactional:

| Case | Behaviour |
|---|---|
| **No children** | soft-deleted. The partnership ends; people are untouched |
| **Has children** | **refused** with a `StateError` naming the child count. Parentage is never deleted by accident |
| **Has children, `removeChildLinks: true`** | the child links are flagged first, then the family. The people themselves are never touched |
| **One spouse** | it is a single-parent family; exactly the rules above. (A single-parent family is retired automatically only when its last partner is deleted — see §2) |
| **Two spouses** | dissolving removes the partnership for both; it does not remove either person, and it does not remove their children unless told to |
| **Other relationship members** | **not applicable** — the model has exactly two partner slots and child links. There is no third membership type, so there is nothing to define |

Dissolving twice is idempotent (second call returns 0). An unknown family is an `ArgumentError`.

---

## 4. Child-link deletion

`removeParentChildLink(linkId)` flags that one row. It never touches the child, the parent or the
family — verified by asserting the family row and every person remain live, and that the link row
itself is only flagged, not deleted. Removing twice returns 0; an unknown id returns 0. Re-adding the
same parent-child relationship un-flags the existing row rather than creating a duplicate, so
`UNIQUE(family_id, child_id)` is never violated.

---

## 5. Tree deletion

A tree is the ownership root, so its deletion is the only place where data is destroyed — and it
cannot happen by accident:

| Case | Behaviour |
|---|---|
| **Empty tree** | `deleteFamilyTree` deletes the row |
| **Populated tree** | `deleteFamilyTree` **refuses** with a `StateError` naming people, families, child links, events and media counts. `previewTreePurge(treeId)` returns the same counts as a record for a confirmation dialog |
| **Deliberate destruction** | `purgeTree(treeId)` — one transaction, no partial state |

`purgeTree` accounts for **every** owned record, in dependency order:

1. `citation_links` rows for the tree's people — polymorphic, so no foreign key would have cleaned
   them up;
2. `citations.image_media_id` cleared where it points at the tree's media (otherwise `RESTRICT`
   would block the media delete);
3. `duplicate_markers` naming the tree's people;
4. partner slots and child links in **other** trees that point at the purged people, so no `RESTRICT`
   constraint can leave a half-applied purge;
5. child links of the tree's families, then the families themselves;
6. events, media rows, research notes, to-dos and surname events of the tree's people;
7. the people — **including soft-deleted ones**, since a purge destroys the tree, not just its living
   members;
8. the `family_trees` row.

It returns `(people, orphanedFilePaths)`: profile-photo and media **files** are deliberately not
deleted by the repository (the storage layer owns the filesystem), so the caller receives the paths
to remove. Tests assert the other tree in the database is completely untouched and that the tree id
can be reused afterwards.

---

## 6. Tests

New suite `test/data/deletion_matrix_test.dart` — **31 tests**:

| Group | Covers |
|---|---|
| Person deletion | unknown id; repeated deletion; row survives with no other row destroyed; partner detach with the family surviving for the spouse; a child hidden with its link left intact; the only parent retiring the family and its links; person-scoped rows kept and unreachable; restore; merged person refused for delete and restore; merge record surviving a survivor delete |
| Family deletion | childless dissolve; idempotence; unknown family; with children refused; with children + explicit instruction (people still untouched); single-parent family with children refused |
| Child-link deletion | touches only the link; idempotence; unknown link; re-add restores rather than duplicates |
| Tree deletion | empty tree; populated tree refused with counts; preview counts every record type; full purge with orphaned-file reporting; another tree untouched; unknown tree; id reuse after purge |
| FK integrity | hard-deleting a person with events / a tree with people / a family with children / a person who is a partner — all rejected |

The matrix requested by the brief is covered end to end: empty tree, tree with people, tree with
families, tree with children, tree with spouse relationships, deleted person, deleted family, removed
child relationship, tree deletion, repeated deletion, invalid ids, FK integrity.

**Replaced, not preserved:** `person_write_test`'s "removing a child removes only that child link"
asserted the old cascade (the child link being flagged). Under the new semantics only the person is
flagged, so the test was rewritten to assert the new, stronger property — the family and link rows
are untouched and the person is hidden from lookups.

---

## 7. Phase report

- **Files changed:** `lib/data/repositories/genealogy_repository.dart` (delete/restore rewritten),
  `lib/data/repositories/relationship_repository.dart` (live-person filtering in the tree read
  models), `lib/data/repositories/family_tree_repository.dart` (tree deletion, purge preview,
  purge), `test/data/deletion_matrix_test.dart` (new), `test/data/person_write_test.dart` (updated),
  plus this document.
- **Schema changes:** none. The model already had `is_deleted`, `merged_into_id` and the
  `RESTRICT`/`CASCADE` actions this phase relies on; no migration and no code generation were needed.
- **API changes:** `deleteFamilyTree` now refuses a populated tree; new `previewTreePurge` and
  `purgeTree` with `TreePurgePreview` / `TreePurgeResult` records; `deletePerson`/`restorePerson`
  gained merged-person guards; `getPartnerships` / `getParentChildRelationships` no longer surface
  deleted people.
- **Tests added/changed:** 31 added, 1 rewritten.
- **Test count:** **111 passing / 0 failing / 0 skipped** (was 80).
- **Analyzer:** **18 issues, 0 errors** — unchanged, all pre-existing non-errors.
- **Build:** `flutter build web --debug` → **success** (`√ Built build\web`, 64.0 s).
- **Remaining risks:**
  1. `restorePerson` restores the person only; partner slots cleared by the delete are not rebuilt
     (documented above — doing better needs an audit trail of *why* a membership was removed).
  2. Deleting a person leaves their events/media/notes/surname events in the database, unreachable.
     A "purge this person" operation would need per-person hard deletion and file cleanup, and is
     deliberately not offered yet.
  3. `purgeTree` assumes a single-tree database for cross-tree references (the app only ever has
     one). It defensively detaches cross-tree family slots and child links, but a cross-tree
     person-scoped row cannot exist in practice and is not tested.
  4. Media and profile-photo **files** are returned, not deleted: the caller must remove them.
- **Commit hash:** see the commit carrying this file.
