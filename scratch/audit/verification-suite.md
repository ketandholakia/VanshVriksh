# VanshVriksh — Fresh/Migrated Schema and Test Architecture

**Phase:** a permanent database verification suite, and a test layout that separates *what the schema
is* from *what the code does*.

---

## 1. Test architecture

```
test/
├── support/                          shared, not tests themselves
│   ├── test_database.dart            a database in the post-startup state (schema + owning tree)
│   ├── schema_expectations.dart      THE canonical schema, declared as data
│   ├── schema_verification.dart      expectCanonicalSchema() + schemaFingerprint()
│   └── legacy_fixtures.dart          legacy tables, seeding and upgrade helpers
│
├── data/                             data-layer behaviour
│   ├── schema_verification_test.dart   fresh + migrated must equal the declared schema
│   ├── domain_invariants_test.dart     invariants, detection proof, post-operation checks
│   ├── integrity_constraints_test.dart constraints exercised with raw SQL
│   ├── migration_test.dart             legacy import behaviour
│   ├── migration_parity_test.dart      ambiguity preserved, failed migration rolls back
│   ├── deletion_matrix_test.dart       every delete/remove/purge operation
│   ├── person_write_test.dart          write semantics
│   ├── relationship_repository_test.dart  partner and parentage rules
│   └── merge_contract_test.dart        the merge contract incl. fault injection
│
├── features/                         UI-level behaviour (duplicates, GEDCOM)
└── widget_test.dart                  app-shell smoke test
```

**Layering rule:** `schema_expectations.dart` states the intent; the two verification suites compare
reality against it; the behaviour suites exercise the repositories. A schema change now requires
editing one declared file deliberately — it cannot slip through as a side effect.

**Replaced:** `test/data/schema_test.dart` (21 tests) was deleted. It checked the same schema facts
inline, so it duplicated what the verification suite now declares in one place, and its delete-action
tests duplicated `integrity_constraints_test.dart`. Coverage was not lost, it moved to the suites that
own it.

---

## 2. Schema verification

`test/data/schema_verification_test.dart` — **8 tests**:

| Check | How |
|---|---|
| expected tables | the full table-name list, compared to the declared map's keys |
| expected columns | `PRAGMA table_info`: name, nullability, primary-key position and **default value**, per table, in order |
| expected indexes | the named-index set is compared for **equality**, so an unexpected extra index fails too |
| expected foreign keys | `PRAGMA foreign_key_list`: column, parent table and **delete action**, per table |
| expected uniqueness | `PRAGMA index_list` with `origin = 'u'` plus `index_info`, so real UNIQUE constraints are proven, not assumed |
| schema version | `PRAGMA user_version` must equal the declared version (13) |

Applied to:

1. **a brand-new database** (`createAll`);
2. **migrated from v12** (the previous version);
3. **migrated from v11**;
4. **migrated from a sparse legacy database (v7)** — no canonical tables at all, so the upgrade has to
   create and rebuild everything;
5. **migrated from a legacy database carrying data** — the same, plus assertions that the imported
   couple and child survived and are still connected.

Plus one test that the **fingerprints of fresh and migrated databases are identical** — not just equal
to each other's expectations, but to the declared schema, which is the stronger statement: two
databases agreeing on a wrong schema would still pass a pure comparison.

---

## 3. Domain invariants

`test/data/domain_invariants_test.dart` — **15 tests**. The invariants are SQL queries that must
return **zero rows**; they are the specification rather than a description of any method.

| Invariant | Kind |
|---|---|
| a child link has a family | FK-enforced |
| a child link has a child | FK-enforced |
| a live child link does not point at a retired family | **logical** — an FK cannot see `is_deleted` |
| a family references existing people | FK-enforced |
| a live family does not keep a retired partner | **logical** |
| a person belongs to an existing tree | FK-enforced |
| a family belongs to an existing tree | FK-enforced |
| a tree root references an existing person | FK-enforced |
| no duplicated family-child link | UNIQUE-enforced |
| no duplicated couple | UNIQUE-enforced |
| a family has at least one partner | **logical** |
| a family does not have the same person in both slots | **logical** |
| no person-scoped record without its person | FK-enforced |
| no merged person is left active | **logical** |
| a merge pointer targets a live person | **logical** |
| a person is not merged into themselves | **logical** |
| a duplicate marker names two different, existing people | FR+FK-enforced |

**One deliberate exception, documented in the file:** a *link* pointing at a soft-deleted person is
**not** a violation. The delete contract flags only the person (so the delete stays reversible) and
every read path excludes deleted people; the rule that matters is that a live *partnership* never
keeps a retired partner, which is a separate invariant. Writing this down is the point — an earlier
draft of the suite flagged the intended behaviour as corruption, and the delete contract won.

### The invariants are proven to detect, not just to pass
Seven tests deliberately corrupt the database **behind the constraints' back** — states a foreign key
cannot prevent because the row still exists, only its flag or a slot changed — and assert the matching
invariant fires:

- a live child link pointing at a retired family;
- a live family keeping a retired partner;
- a merged person left active;
- a merge pointer at a retired person;
- a person merged into themselves;
- a family with the same person in both slots;
- a family with no partner at all.

Two more prove the FK-enforced ones are unreachable by trying: repointing a link at a non-existent
family, and reassigning a person to a non-existent tree — both rejected, with the database still clean.

### Operations, not implementations
Five tests run the repositories and then require every invariant to hold: the delete flow (person,
then child, then restore), dissolving a partnership, removing one parent-child relationship, a
completed merge, and a full tree purge with events, media, notes, to-dos and a marker. A failed merge
is checked for the complementary property — the data fingerprint is unchanged afterwards.

---

## 4. Phase report

- **Files changed:** `test/support/schema_expectations.dart` (new), `test/support/schema_verification.dart`
  (new), `test/support/legacy_fixtures.dart` (new), `test/data/schema_verification_test.dart` (new),
  `test/data/domain_invariants_test.dart` (new); `test/data/schema_test.dart` deleted (superseded).
- **Production code changed:** none. **Schema:** unchanged (still v13).
- **Tests added/changed:** 23 added, 21 removed (the superseded suite), plus two throwaway schema-dump
  helpers removed.
- **Test count:** **187 passing / 0 failing / 0 skipped** (was 185 — the net is small because 21
  duplicate tests were replaced by 23 that are declared rather than inline).
- **Analyzer:** 18 issues, 0 errors (all pre-existing).
- **Build:** `flutter build web --debug` → **success** (`√ Built build\web`, 50.3 s).
- **Remaining risks:**
  1. `migration_test.dart` and `migration_parity_test.dart` still carry their own fixture code instead of
     using `legacy_fixtures.dart`; consolidating them is the obvious next cleanup (they pass as they are,
     so the change was left out of this phase to avoid touching working tests).
  2. The declared expectations must be updated deliberately when the schema changes — that is the
     intent, but it does make a schema change a two-file edit.
  3. The invariants cover the model; the UI layer (provider caching, stale reads) is not covered by any
     automated check.
- **Commit hash:** see the commit carrying this file.
