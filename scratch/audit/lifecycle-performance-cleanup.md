# VanshVriksh — Database Lifecycle, Performance and Cleanup

**Phase:** the final data-layer engineering pass. Every change below is backed by evidence gathered
from the code rather than by pattern-matching.

---

## 1. Database lifecycle

**Problem:** `databaseProvider` returned `AppDatabase()` and never closed it, so the SQLite
connection and its file handle lived for the whole process. Anything that replaced the provider scope
(a test container, a future "switch database file" flow) leaked the old connection.

**Fix** (`lib/data/providers/database_provider.dart`):

```dart
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
```

The rest of the Riverpod surface was reviewed and needed nothing: every other provider is a
`Provider` over a stateless service or a repository built from `databaseProvider`, so they own no
disposable resource — only the database does. Derived providers (`genealogyRepository` and friends)
are rebuilt if the database provider is ever replaced, and the old database is closed at that moment.

## 2. Query performance — only demonstrated problems were changed

### 2.1 The tree views asked the database once per node (fixed)

`multiGenFamilyTreeProvider` walked ancestors three levels up and descendants two down with
`await getParents(id)` / `getChildren(id)` / `getSpouses(id)` **per node**, and each of those is
itself two or three queries. A three-up, two-down walk over a few dozen people issued **hundreds** of
queries per rebuild; the fan chart did the same per generation.

**Fix:** a `FamilyGraph` (`lib/data/models/family_graph.dart`) built from **three** queries — the
tree's people, its partnerships, its child links — with indexed lookups (`parentsOf`, `childrenOf`,
`spousesOf`). `RelationshipRepository.loadFamilyGraph(treeId)` builds it; `basicFamilyTreeProvider`,
`multiGenFamilyTreeProvider` and `ancestryFanChartProvider` now traverse the graph in memory.
The BFS loops no longer contain `await` at all.

| View | Before | After |
|---|---|---|
| basic tree (1 person) | 3 relationship calls ≈ 8 queries | 1 person lookup + 3 queries |
| multi-generation tree (≈30 nodes) | ≈ 90 calls ≈ 250+ queries | 1 person lookup + 3 queries |
| fan chart (6 generations) | ≈ 30 calls ≈ 90 queries | 1 person lookup + 3 queries |

### 2.2 The relationship stream read the whole child-link table (fixed)

`watchParentChildRelationships(treeId)` watched **every** row of `family_children_v2` and filtered in
Dart, so a change anywhere in the database rebuilt the tree from a full table scan.

**Fix:** the links query is now joined to `families_v2` and filtered by `tree_id`, so only this tree's
links are read (and the new index on `families_v2.tree_id` is used).

### 2.3 Reviewed and deliberately left alone

| Suspect | Verdict |
|---|---|
| `getParents` / `getChildren` / `getSpouses` per person | still fine for their callers (profile page, integrity check, dashboard) — a handful of queries, all indexed |
| `mergePeople`'s per-family loops | bounded by the merge scope, inside a transaction; not a demonstrated problem |
| `_collapseDuplicateParentageOf`, `previewTreePurge`, `purgeTree` | `IN (...)` queries over a bounded id set, one per table |
| `searchPeople`'s `LIKE '%…%'` | cannot use an index by definition; a search feature would need FTS, which is a feature decision, not a fix |
| index coverage | already complete: every foreign-key column has an index, verified by a test |

---

## 3. Transactions — review of every multi-table write

| Operation | Writes | Transaction? |
|---|---|---|
| `mergePeople` | both person rows, families, child links, person-scoped rows, markers | ✅ |
| `purgeTree` | 8 tables | ✅ |
| `deletePerson` | person + partner slots + families + child links | ✅ |
| `restorePerson` | 1 row | ✅ (single statement) |
| `addSpouseRelationship` | family row (+ partner validation reads) | ✅ |
| `removeSpouseRelationship` | child links + family | ✅ |
| `addParentChildRelationship` | family (when creating) + child link | ✅ |
| `removeParentChildRelationship` | one or more child links | ✅ |
| `addChildToFamily`, `createFamily` | 1 row each | single statement |
| GEDCOM import | people, families, links | ✅ |
| schema migration | everything | ✅ (drift wraps `onUpgrade`) |

**The one gap, documented rather than papered over:** the *UI* composes several of these atomic calls
for a business action that is logically one step — `person_form_page` inserts the person, then adds
each selected relationship, then possibly the spouse link. If it fails in between, the person exists
with some links and not others: incomplete, not corrupt (every invariant still holds), and the user
can finish the job in the UI. Making that atomic means moving the "which relationships to create"
logic out of the form into a repository method; that is a UI refactor with no test coverage on the
form today, so it was deliberately **not** done in a data-layer pass. It is the natural next step if
the form gets widget tests.

---

## 4. Legacy cleanup

Every removal below was preceded by a reference check across `lib/` (excluding generated files).

### Removed: three tables nothing referenced

| Removed | Evidence |
|---|---|
| `citations` | no producer, no consumer, no DAO, no repository, no provider, no UI |
| `citation_links` | same — its only mention in the codebase was the *maintenance* code written for it |
| `todos` | same — no DAO, no repository, no provider, no UI |

Deleting them removed:
- three table definitions and their generated code;
- `_repointCitationLinks` (a 45-line merge helper whose only purpose was maintaining a table nothing
  used) and the merge's to-do repointing;
- the purge's citation/to-do steps and the `todos` counter in `TreePurgePreview`;
- the `citations`/`citation_links`/`todos` create/rebuild steps in the migration, replaced by explicit
  `DROP TABLE IF EXISTS` so an older database sheds them (proven by the migration parity tests);
- the tests that existed only for them.

**How to reintroduce:** the schema is declared in one place (`test/support/schema_expectations.dart`)
and the upgrade path rebuilds every canonical table, so adding a citations or to-do feature later is a
normal schema change plus a migration step — cheaper than carrying three unused tables and the code
that maintained them.

### Deliberately kept, with the evidence

| Kept | Why |
|---|---|
| `media_items` + `MediaRepository` + `MediaStorageService` | used by `PersonMediaGalleryPage`, reachable at `/people/:id/media` |
| `research_notes` + `ResearchNotesRepository` | used by the person-facts screens, reachable at `/people/:id/facts` |
| `events` + `EventsRepository` | used by the same facts screens and by duplicate detection |
| `surname_events` | written by the legacy import, read by the genealogy profile screen — see below |
| `duplicate_markers` | used by the duplicate detection and marked-duplicates screens |

*Note on the first evidence pass:* grepping for the **table accessors** (`mediaItems`, `researchNotes`,
`todos`) reported zero uses for all of them, which would have condemned two live subsystems. Grepping
for the **repositories** showed media and research notes have reachable UI. The lesson is recorded
here because it is exactly the mistake the brief warns about: verify references, not names.

### The remaining dead architecture (identified, not deleted)

`lib/features/genealogy/**` (4 screens) plus `lib/app/genealogy_tree_page.dart` and six `/v2/*` routes
form a complete second implementation that nothing links to; nothing outside that island references
it either. Its only reader of `surname_events` is the genealogy profile screen.

It was **not** deleted in this pass because it is the only writer of `custom_display_name` and
`display_name_format` — deleting it would leave two columns that are read (by the name formatter) with
no way to be set, which is a product decision rather than a data-layer one. The precise file list is
above; removing it is a contained, mechanical change whenever the display-name feature is either
wired into the v1 screens or dropped.

---

## 5. Phase report

- **Files changed:** `database_provider.dart` (dispose), `relationship_repository.dart` (graph load +
  tree-scoped link stream), `lib/data/models/family_graph.dart` (new), `tree_providers.dart` (three
  providers now traverse the graph), `app_database.dart` (three tables dropped), `genealogy_repository.dart`
  and `family_tree_repository.dart` (removed dead maintenance code), `schema_expectations.dart` and four
  test files updated; three table files deleted.
- **Schema changes:** three tables removed (`citations`, `citation_links`, `todos`); no other table,
  column, index, constraint or foreign key changed. `schemaVersion` stays 13 — the migration drops the
  removed tables when it encounters them, so an upgraded database reaches the same schema as a fresh
  one.
- **API changes:** `TreePurgePreview` lost its `todos` field; `FamilyGraph` and
  `RelationshipRepository.loadFamilyGraph` added. No public API removed.
- **Tests added/changed:** the suites for the removed tables were removed; the expectations file is now
  the single declaration of the schema. **Test count: 177 passing / 0 failing / 0 skipped** (was 187 —
  the drop is the deleted dead-table tests).
- **Analyzer:** 18 issues, 0 errors.
- **Build:** `flutter build web --debug` → **success** (`√ Built build\web`, 60.2 s).
- **Remaining risks:**
  1. The UI still composes several atomic repository calls for "save person with relationships" (§3).
  2. The `/v2` island remains dead code (§4).
  3. Performance work beyond the two demonstrated problems would be speculative; the numbers above are
     query counts derived from the code, not measurements from a profiler.
  4. `surname_events` remains written by the import and read only by dead UI — it goes with the island.
- **Commit hash:** see the commit carrying this file.
