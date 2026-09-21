# VanshVriksh — Migration Strategy

**Phase:** migration architecture redesigned and consolidated. Schema **v12 is the canonical
baseline**; everything older is an import path.

---

## 1. The questions the brief asked, answered

| Question | Answer | Evidence |
|---|---|---|
| **Which schema versions are actually relevant?** | Only **v12** (the canonical schema) and *pre-v12 as an import path*. There has never been a release, so no version is "supported" in the sense of a contract with users | no releases; `schemaVersion` history is 3→12 inside one repo |
| **Do existing development databases need preservation?** | **Not assumed, but supported.** I cannot see what databases exist on your machine, and the cost of keeping a deterministic, verified import is now small. Dropping it would silently destroy a dev database that happened to be older | the import is ~200 lines of raw SQL, fully tested |
| **Is a clean schema reset acceptable?** | For *new* databases, yes — and that is exactly what `onCreate` does (`createAll`). For an *existing* file it is not acceptable to silently reset, because that destroys genealogy data, so the upgrade path is kept | `onCreate: m.createAll()` |
| **Do the legacy `persons` / `relationships` tables still need migration?** | **Yes, as an import source only.** They are read once by the upgrade (raw SQL, no drift classes), then dropped. They are not part of the model and a fresh database never creates them | `_absorbLegacyPersons`, `_absorbLegacyRelationships` |
| **Can migrations be consolidated?** | **Yes, and they now are.** Nine incremental `if (from < n)` steps became one deterministic routine that works from any older version | `_upgradeToCanonicalSchema` |

**Decision:** keep the ability to upgrade, consolidate how it happens, and make it verifiable. The
alternative (dropping the import path) would lose data in a database that nobody can inspect before
the fact, for no benefit — the consolidated path is one code path, not nine.

---

## 2. The consolidated upgrade

`schemaVersion` stays **12**. `onUpgrade` is now a single call, and the routine is deterministic:

```
_upgradeToCanonicalSchema(m)
  1. ensure every canonical table exists   → a v7 database that only has the legacy tables
                                             gets all 12 tables created, no replay of 9 steps
  2. ensure the legacy columns exist       → an ancient `persons` table that lacks
                                             birth_surname/married_surname is extended before
                                             the import reads it
  3. import legacy persons                 → identity, names, dates, places, bio, notes, privacy,
                                             profile photo, surname history
  4. import legacy relationships           → partners and parentage (see §3)
  5. ensure the ownership root exists
  6. repair states the new constraints would reject
  7. rebuild every canonical table         → drops obsolete columns, applies foreign keys,
                                             re-creates the schema-declared indexes
  8. drop persons / relationships / sync_change_log
  9. verify the import                     → throws if anything it claims to preserve is missing
```

**Atomic.** Drift already runs `onUpgrade` inside a transaction — an explicit `BEGIN` fails with
"cannot start a transaction within a transaction". So step 9 throwing rolls the whole upgrade back
and the database keeps its previous version and contents. This is asserted by a test: a deliberately
unmigratable database comes back with `user_version` still at 11, the legacy table still present, its
row intact, and nothing from later steps created.

*(This also corrects a claim in my earlier characterization: the half-migrated state I measured then
came from the *retry* path, not from a missing rollback. The migration is transactional; the
verification and the consolidated routine now make that property explicit and tested.)*

---

## 3. Legacy relationship values — investigated, not assumed

I inspected the constants and the whole git history rather than assuming `marriage`:

| Value | Confirmed? | Evidence |
|---|---|---|
| `parent_child` | **yes** | `RelationshipTypes.parentChild`; written by the initial-commit relationship code |
| `spouse` | **yes** | `RelationshipTypes.spouse`; written by the same code |
| `marriage` | **not a legacy edge value** — accepted defensively | it is the *default* of `families_v2.relationship_type`, so a partially migrated or hand-edited database can carry it |
| `husband`, `wife`, `partner`, `couple`, `married`, `divorced`, `widow` | **never appear** anywhere in the codebase or its history | full-text search over `lib/` and `git log -S` |

The vocabulary now lives in one place, `lib/core/constants/relationship_types.dart`, with
`partnerTypes = {spouse, marriage}` and `parentChildTypes = {parent_child}`, and the migration reads
those sets instead of hard-coded literals. A value outside the sets is **counted and ignored** — never
guessed into a relationship (tested with a `'partner'` row).

### Ambiguous legacy data is preserved, never chosen arbitrarily

The model records at most two parents per family. A legacy child with **three** recorded parents keeps
**all three**: the first two share a family and each further parent gets their own single-parent
family, whose `notes` column records why:

> *"Imported from legacy data: \<child\> was recorded with 3 parents, but a family holds two. This
> family keeps one of the additional parents so no parentage is lost."*

That is the "report or mark ambiguity" requirement satisfied in-band (`clamp`ing to two and dropping
the rest would have been silent data loss — which is what the previous code did).

### The import is verified

`_verifyUpgrade` re-reads the database and fails the migration if:
- fewer people exist than were imported, or
- any imported parentage is not reachable as a live link through a family that names that parent, or
- partner rows were imported but no partnership exists.

Failures throw with a list, which rolls the upgrade back.

---

## 4. Fresh vs migrated

`test/data/migration_parity_test.dart` compares a **structural fingerprint** of a fresh database with
one produced by upgrading, covering everything the brief listed:

| Aspect | How it is compared |
|---|---|
| tables | the full table-name list from `sqlite_master` |
| columns | `PRAGMA table_info`: name, declared type, NOT NULL, default value, primary-key position |
| constraints | `PRAGMA index_list` per table: name, uniqueness, origin (`u` = UNIQUE, `pk` = PRIMARY KEY) |
| foreign keys | `PRAGMA foreign_key_list`: source column, target table/column, `ON DELETE`, `ON UPDATE` |
| indexes | the named index list **and** each table's index entries |
| default values | captured in the column fingerprint |
| table SQL | normalized `CREATE TABLE` text |

Two migrations are checked: **v11 → v12** and a **sparse legacy database (v7) that only contains
`persons` and `relationships`** — the strongest case, since the upgrade has to create every canonical
table and then rebuild it. Both are identical to a fresh database.

---

## 5. Tests

New `test/data/migration_parity_test.dart` — **5 tests**: v11 parity, sparse-v7 parity, more parents
than a family can hold (all preserved + the marker written), an unconfirmed legacy value ignored, and
the atomicity/rollback proof.

Existing `test/data/migration_test.dart` (10 tests) still covers the import cases: `'spouse'` and
`'marriage'` partner rows, both-directions duplicates collapsing to one partnership, single and two
parent families, the ambiguous-shape case that used to abort the upgrade, person copying with surname
history, legacy tables dropped, index parity, and people anchored to an existing tree.

---

## 6. Phase report

- **Files changed:** `lib/data/database/app_database.dart` (migration consolidated, atomic, verified,
  lossless ambiguity handling), `lib/core/constants/relationship_types.dart` (documented legacy
  vocabulary as the single source), `test/data/migration_parity_test.dart` (new), plus this document.
- **Schema changes:** none. `schemaVersion` stays **12**; no table, column, index or constraint changed.
- **API changes:** none public. Internally, `_absorbLegacyRelationships` returns what it imported and
  `_upgradeToCanonicalSchema` verifies it.
- **Tests added/changed:** 5 added, none removed.
- **Test count:** **125 passing / 0 failing / 0 skipped** (was 120).
- **Analyzer:** 18 issues, 0 errors (unchanged, all pre-existing).
- **Build:** `flutter build web --debug` → **success** (`√ Built build\web`, 72.2 s).
- **Remaining risks:**
  1. A pre-v10 database is imported **once**; after that the legacy tables are gone, so a bug found in
     the import later cannot be re-run against the original data. Back up such a database before opening
     it with this build.
  2. The `families_v2.tree_id` backfill assumes the single default tree (correct for every database
     this app has produced; a wrong value fails loudly through the foreign key).
  3. Unrecognised legacy relationship values are counted internally but there is **no user-facing
     report surface** — nothing in the UI tells the user that a row was ignored.
  4. The database is not backed up automatically before an upgrade; a failed upgrade rolls back, but a
     *successful* wrong one cannot be undone from inside the app.
- **Commit hash:** see the commit carrying this file.
