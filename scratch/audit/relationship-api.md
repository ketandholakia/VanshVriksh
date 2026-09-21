# VanshVriksh — Relationship API Redesign

**Phase:** relationship repository rebuilt around explicit domain operations and documented domain
rules.

## 1. The API

Every operation is named after the domain concept it acts on. No caller has to know whether an
identifier refers to a family, a family-child link or a projection — the repository resolves that
itself, and every identifier a caller passes is a **person**.

| Operation | Meaning |
|---|---|
| `addSpouseRelationship({treeId, personAId, personBId, isPrimary})` | record a partnership between two people |
| `removeSpouseRelationship({treeId, personAId, personBId, removeChildRelationships})` | end that partnership |
| `addParentChildRelationship({treeId, parentId, childId, familyId?, relationshipType})` | record a parent |
| `removeParentChildRelationship({treeId, parentId, childId, removeCoParent})` | remove a parent |
| `getSpouses(personId)` / `getParents(childId)` / `getChildren(parentId)` / `getSiblings(personId)` | people-scoped reads |
| `getFamiliesForPerson(personId)` | the live partnership rows of a person |
| `getPartnerships(treeId)` / `getParentChildRelationships(treeId)` | tree-scoped read models (`Partnership`, `ParentChildRelationship`) |

**Removed** (they exposed the underlying tables to callers):

| Removed | Replaced by |
|---|---|
| `removeParentChildLink(linkId)` — caller had to know a `family_children_v2` id | `removeParentChildRelationship(parentId, childId)` |
| `dissolveFamily(familyId, {removeChildLinks})` — caller had to know a `families_v2` id | `removeSpouseRelationship(personAId, personBId, {removeChildRelationships})` |
| the static slot helper duplicated in the repository and the migration | `canonicalPartnerSlots(...)` in `lib/data/models/relationship_edges.dart`, one shared definition |

`familyId` survives on `addParentChildRelationship` for exactly one case: a parent with **several**
families is genuinely ambiguous (a father with two marriages, adding a child), and the caller must
say which family the child belongs to rather than the repository guessing.

## 2. Partner rules

| Case | Behaviour |
|---|---|
| **One partner** | one partnership row with both slots filled |
| **Two partners** (remarriage) | **allowed** — a second partnership is a new family. Multiple families per person are part of the domain, and `getSpouses` returns all of them |
| **Same-sex couple** | **supported**. `husband`/`wife` are display slot names used by the tree views; both are filled, and nothing requires one male and one female partner |
| **Unknown gender** | **supported**. The canonical rule below decides the slots without inventing a gender |
| **Multiple families** | allowed; `addParentChildRelationship` requires an explicit `familyId` when a parent has more than one (see §3) |
| **Childless family** | ends freely |
| **Family with children** | ending it deletes its children's parentage, so it is **refused** unless the caller passes `removeChildRelationships: true` |
| **Self-partnership** | `ArgumentError` |
| **Deleted or unknown person** | `ArgumentError` |
| **Person from another tree** | `ArgumentError` |

### The canonical slot rule

```
genders differ   → the person recorded as female takes the wife slot
genders match    → the pair is ordered by id
```

`husband`/`wife` are **slot** names, not claims about people. The rule is order-independent, which
is what makes `UNIQUE(husband_id, wife_id)` mean "this couple exists once": the same two people
always map to the same pair of slots whichever order the caller passes them in. (Before this change,
`addSpouseRelationship(a, b)` and `(b, a)` would have produced two different slot pairs — the
database constraint could not have caught the duplicate couple. The idempotence check hid it in
practice; the rule removes the hole.) The same function is used by the v11→v12 migration, so
imported couples are ordered identically.

## 3. Parent-child rules

| Rule | Behaviour |
|---|---|
| **Duplicate links** | prevented. Re-adding a link that exists leaves one row, and re-adding a *removed* link un-flags the existing row instead of creating a second (`UNIQUE(family_id, child_id)`) |
| **Self-link** | `ArgumentError` |
| **Same parent twice for one child** | **refused** (`StateError`) even through a different family — a child cannot have the same parent recorded twice |
| **Duplicate parent-child membership** | the same child cannot be linked twice into one family; it *can* belong to more than one family legitimately (see multiple parents) |
| **Unknown / ambiguous parent** | a parent with several families must name one with `familyId`, otherwise `StateError` |
| **Family from another tree** | `ArgumentError` |
| **Unknown or deleted person** | `ArgumentError` |

### Which parentage kinds the product actually permits

Decided from the existing model, not invented:

| Kind | Supported? | How |
|---|---|---|
| **Biological** | yes | default `relationshipType: 'biological'` |
| **Adoption** | **yes — already in the schema** | `family_children_v2.relationship_type` accepts it; the API exposes it as a parameter. There is **no UI for choosing it yet**, and this phase did not add one |
| **Step-parent** | yes, same mechanism | the step-parent is a partner in the family and the link's type records how the parentage works |
| **Foster** | yes, same mechanism | value is available; nothing sets it today |
| **Multiple parents** | **yes** | a child may belong to several families, so it can have more than two parents (e.g. birth parents + adoptive parents). Tested with four |
| **Unknown parents** | yes, as **absence** | a person with no links has no parents. The app deliberately does **not** create placeholder "Unknown" people to stand in for an unknown parent, and this phase did not add one |

**Not supported, and not invented here:** more than two partners in a single family (a family has two
slots); one person occupying two slots of the same family; un-merging; and any notion of parentage
that is not a parent-child link.

### Removing a parent

A child is linked to a *family*, so when the parent has a partner in that family, removing the
parent-child relationship would silently drop the **co-parent** as well. That is refused unless the
caller passes `removeCoParent: true`. With a single parent there is no co-parent and no flag is
needed. The child, the parent and the family are never deleted by this operation.

## 4. Tests

New suite `test/data/relationship_repository_test.dart` — **24 tests**:

- **Partner rules:** one partner; argument-order independence and re-add as a no-op; remarriage with
  more than one partnership; the primary flag; same-sex couple; unknown gender; the canonical slot
  rule as a unit test; self-partnership rejected; deleted person rejected; cross-tree person rejected.
- **Parent-child rules:** single parent; a child of a partnership has both partners as parents (one
  link, two edges); duplicate parentage is a no-op; self-parent rejected; the same parent twice through
  different families refused; ambiguous parent must name the family; a foreign family rejected;
  adoption/step recorded rather than invented; a person with no parents; more than two parents across
  families; removal without a co-parent; removal with a co-parent refused unless acknowledged.
- **Getters:** a three-generation tree read back consistently across `getParents` / `getChildren` /
  `getSiblings` / `getSpouses` / `getFamiliesForPerson` / `getPartnerships` /
  `getParentChildRelationships`; every getter hides a deleted person.

**Replaced:** `test/data/relationship_delete_test.dart` was deleted. It tested the old link-id and
family-id operations, which no longer exist; its coverage is absorbed by the new suite plus
`deletion_matrix_test.dart`, which now drives the domain operations (`removeSpouseRelationship`,
`removeParentChildRelationship`) instead of raw ids.

## 5. Phase report

- **Files changed:** `lib/data/repositories/relationship_repository.dart` (operations rewritten),
  `lib/data/models/relationship_edges.dart` (shared `canonicalPartnerSlots` + `isFemaleGender`),
  `lib/data/database/app_database.dart` (migration uses the shared slot rule),
  `test/data/relationship_repository_test.dart` (new),
  `test/data/deletion_matrix_test.dart` and `test/data/merge_transaction_test.dart` (updated to the
  domain operations), `test/data/relationship_delete_test.dart` (deleted), plus this document.
- **Schema changes:** none.
- **API changes:** `dissolveFamily` / `removeParentChildLink` removed; `removeSpouseRelationship` /
  `removeParentChildRelationship` added; `addSpouseRelationship` gained `isPrimary` and canonical
  ordering; `addParentChildRelationship` gained `relationshipType` and the duplicate-parentage guard;
  `getFamiliesForPerson` added to the repository.
- **Tests added/changed:** 24 added, 1 file deleted, 2 files updated.
- **Test count:** **120 passing / 0 failing / 0 skipped** (was 111).
- **Analyzer:** 18 issues, 0 errors (unchanged, all pre-existing).
- **Build:** `flutter build web --debug` → **success** (`√ Built build\web`, 62.0 s).
- **Remaining risks:**
  1. No UI drives these operations yet: `person_form_page` still creates relationships inline, and
     there is no screen for removing a partnership or a parentage, so the new operations are covered
     by tests but not reachable by a user.
  2. `addParentChildRelationship` still throws (rather than prompting) when a parent has several
     families; the caller — the person form — does not pass `familyId`, so that flow surfaces an
     error. A family picker belongs to the UI phase.
  3. Removing a *partnership* with children removes their parentage (with explicit consent). Ending a
     marriage while keeping both parents is not representable in this model, where a family is both
     the partnership and the parent pair.
  4. Adoption/foster/step values are supported end to end in the data layer but nothing in the UI
     sets them.
- **Commit hash:** see the commit carrying this file.
