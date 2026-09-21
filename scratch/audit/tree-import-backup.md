# VanshVriksh — Audit: Tree / Dashboard / Duplicates / Integrity / GEDCOM / Backup

Scope (all files read in full):
- `lib/features/tree/**`, `lib/features/dashboard/**`, `lib/features/duplicates/**`,
  `lib/features/integrity/**`, `lib/features/gedcom/**`, `lib/features/backup/**`
- `lib/services/backup_service.dart`, `lib/services/image_storage_service.dart`, `lib/services/media_storage_service.dart`

Supporting code read for evidence (not modified): `lib/data/repositories/genealogy_repository.dart`,
`lib/data/repositories/relationship_repository.dart`, `lib/data/database/daos/*`, `lib/data/database/tables/*`,
`lib/features/people/people_providers.dart`, `lib/features/settings/*`, `lib/app/*`,
`pubspec.yaml` / `pubspec.lock`, and the vendored third-party layout engine `graphview-1.5.1`
(`lib/layered/SugiyamaAlgorithm.dart`, `lib/Graph.dart`, `lib/GraphView.dart`).

No file was modified except this report.

---

## 0. Executive summary (severity-ordered)

| # | Sev | Area | Finding | Location |
|---|-----|------|---------|----------|
| 1 | Critical | Duplicates/merge | `mergePeople` is multi-step and **not wrapped in a transaction** → partial merge on any failure; also risks `UNIQUE(family_id, child_id)` violation via soft-deleted rows | genealogy_repository.dart:266–456 (child loop 305–330) |
| 2 | Critical | Backup/restore | `restoreBackup` writes the ZIP straight over the **live** SQLite DB while drift holds it open, with no atomic swap and only a textual "please restart" hint | backup_service.dart:48–71; backup_restore_page.dart:131–176 |
| 3 | High | Backup/restore | Encrypted backup leaves the **plaintext `.zip` on disk** forever (`_encryptBackupFile` never deletes the source) | backup_service.dart:220–226 |
| 4 | High | Backup/restore | **Zip Slip**: `p.join(appDir.path, file.name)` with no containment check on attacker-supplied archives | backup_service.dart:61–68 |
| 5 | High | GEDCOM | Parser reads **UTF-8 only**, ignores `CHAR`/ANSEL/ANSI; non-UTF-8 GEDCOM throws and the whole import fails | gedcom_parser.dart:32 |
| 6 | High | GEDCOM | **No GEDCOM export at all** — feature is a stub dialog → no round-trip, no portability | settings_page.dart:281–289 |
| 7 | High | GEDCOM | Dates `BEF/AFT/ABT/BET ... AND ...` are stored as **exact** dates (BET 1900 AND 1910 → 1910-01-01); `DEAT` never sets `isLiving=false` → birthday reminders for the dead | gedcom_importer.dart:63, 157–200 |
| 8 | High | Duplicates | All-pairs O(n²) × Levenshtein **plus a DB round-trip per candidate**, on the main isolate → multi-second/minutes freeze on real trees | duplicate_detection_providers.dart:50–94 |
| 9 | High | Tree | Spouse edges are fed to Sugiyama as **directed hierarchy edges** → spouses are laid out one generation below their partner, sharing a rank with the children; full layout recomputed synchronously in `build()` | tree_providers.dart:117–126; family_tree_page.dart:345–372 |
| 10 | High | Tree/UI | `zoomOnLoad` setting is **dead** in the tree view (declared, never read) — no zoom-to-fit / center-on-root | family_tree_page.dart:314, 321–374 |
| 11 | High | Duplicates | Merge silently drops `occupation/religion/ethnicity`, orphans citations, keeps survivor's `isLiving`, no undo | genealogy_repository.dart:380–456 |
| 12 | Medium | Tree | Sibling/children queries have **no ORDER BY** → `birthOrder` ignored | relationship_dao.dart:41–63 |
| 13 | Medium | Tree | Fan chart: card geometry and painted sectors use **different centers/radii**; auto-fit frames the wrong region; root sector can never be tapped | family_fan_chart_page.dart:472–476 vs 513–537, 649–662 |
| 14 | Medium | Tree/Reactivity | Tree is stale after adding a child to an existing family (provider watches `families_v2` only) | people_providers.dart:24–28; relationship_repository.dart:156–158 |
| 15 | Medium | Dashboard | `difference().inDays` truncation → off-by-one "Today/Tomorrow" across DST; Feb-29 clamped to Feb 28 (displayed as the real date) | dashboard_providers.dart:80, 119, 130–133 |
| 16 | Medium | Integrity | Only 2 invariants checked (parent age gap, parent-child cycle); nothing else (future dates, death<birth, missing files, orphans, merged refs) | integrity_check_providers.dart:30–104 |
| 17 | Medium | Backup/restore | Whole archive decoded in memory (`decodeBytes` + `file.content as List<int>`) → OOM on media-heavy backups; no manifest/schema/checksum | backup_service.dart:51, 68 |
| 18 | Medium | Backup security | AES-CBC **without MAC**, hardcoded salt, silent legacy SHA-256 KDF fallback, no KDF params stored | backup_service.dart:266–312 |
| 19 | Medium | Backup | Auto-backup switches (daily/weekly/monthly, Wi-Fi-only) persist but nothing implements them | backup_restore_page.dart:400–470; pubspec.yaml (no scheduler dep) |
| 20 | Medium | GEDCOM | Parser `line.trim()` + `split(' ')` + single-space rejoin corrupts `CONC` semantics and multi-space values; malformed lines skipped silently | gedcom_parser.dart:37–70 |
| 21 | Medium | Duplicates | Marked-duplicates page throws (`marker.personB!`) when both people are gone | marked_duplicates_page.dart:529–530 |
| 22 | Medium | Adjacent (in-app v2 tree) | `FutureBuilder(future: _loadBranchData())` created in `build()` → refetch/rebuild storm; `visitedFamilyIds` mutated during build | app/genealogy_tree_page.dart:170–200, 366–375, 640 |
| 23 | Low | Tree | Dead code: `tree_page.dart` (placeholder), `backup_page.dart`; `_TreePersonCard` hint branch unreachable in tree; double spouse edges | tree_page.dart; backup_page.dart; family_tree_page.dart:398–470 |
| 24 | Low | Duplicates | Score can reach 202 but is rendered as `"${score}%"`; marked-page shows *move count* as the score | duplicate_detection_page.dart:236; marked_duplicates_page.dart:538–544 |
| 25 | Low | Backup | Minute-resolution backup filenames overwrite; `backups/` grows unbounded; Drive uploads never pruned/deduplicated | backup_service.dart:196–218, 114–150 |
| 26 | Low | Backup | Encrypted-file detection by `.enc` extension only; restore-from-cloud records a *backup* history entry | backup_service.dart:243, 152–156 |
| 27 | Low | Integrity | `integrityIssuesProvider` cached forever (no refresh/invalidate) → stale results after fixes | integrity_check_providers.dart:20 |

---

## 1. Tree rendering

### 1.1 (High) Spouse edges are hierarchy edges → spouses rendered a generation below their partner
`tree_providers.dart:117–126` adds a directed `spouse` edge **per direction**:
```dart
// Fetch spouses for everyone found ...
final allNodeIds = nodes.keys.toList();
for (final id in allNodeIds) {
  final spouses = await relationshipRepository.getSpouses(id);
  for (final spouse in spouses) {
    if (!nodes.containsKey(spouse.id)) { nodes[spouse.id] = spouse; }
    edges.add(TreeEdge(sourceId: id, targetId: spouse.id, relationType: 'spouse'));
  }
}
```
`family_tree_page.dart:353–357` passes **all** edges (spouse + parent_child) to one `Graph`, and
`family_tree_page.dart:372` lays it out with `SugiyamaAlgorithm(configuration)` — the app never tells
the engine that spouse edges are "same-level" edges.

Engine behaviour (verified in `graphview-1.5.1/lib/layered/SugiyamaAlgorithm.dart`):
default `layeringStrategy = topDown` and `cycleRemovalStrategy = greedy`
(`lib/layered/SugiyamaConfiguration.dart:20–22`). `GreedyCycleRemoval._removeCycles` reverses the
incoming edge of the node with the highest out−in degree; for `R→S`, `S→R`, `R→C(children)` the
`S→R` spouse edge is reversed (dropping it as a duplicate of `R→S`) leaving the DAG `R→S`, `R→C`.
`layerAssignmentTopDown()` then puts `S` and `C` in the **same layer** below `R`.

Impact: a spouse always appears on the children's row; couple grouping is impossible; connectors are
drawn as parent→child arrows between partners. Any real family with same-rank couples (i.e. all of them)
renders semantically wrong.

Fix: do not encode marriage as a graph edge. Model each couple as one logical node (or use a
`subgraph`/`isTree=false` + explicit `Node.position` layout), or render spouses with a dedicated
non-hierarchical edge type (e.g. keep them out of the Sugiyama graph and draw them with a custom
`EdgeRenderer` at the same `y`), or switch to a purpose-built family layout
(couple-box + child-drop algorithm) and only use `graphview` for the ancestor/descendant spine.

### 1.2 (High) Layout is recomputed synchronously inside `build()`; graph is mutated in build
`family_tree_page.dart:321, 345–372`:
```dart
final Graph graph = Graph()..isTree = true;
...
graph.edges.clear();
graph.nodes.clear();          // line 345-346
for (final person in widget.treeData.nodes.values) { nodeMap[person.id] = Node.Id(person.id); }
for (final edge in widget.treeData.edges) { ... graph.addEdge(...); }
...
algorithm: SugiyamaAlgorithm(configuration),
```
`GraphChildDelegate.runAlgorithm()` (graphview `lib/GraphView.dart`) is invoked from
`performLayout`, i.e. the whole Sugiyama pipeline (`cycleRemoval → layerAssignment → nodeOrdering
(10 iterations, `DEFAULT_ITERATIONS = 10`) → coordinateAssignment`) runs **on the UI isolate during
layout**, and every rebuild of `_BasicTreeCanvas` constructs a new delegate → `_needsFullRecalculation`
→ full re-layout. `nodeOrdering` uses `transposeSimple` with `while (improved)` and
`crossingCount` → worst case ≈O(iterations · V · E).

Also, all nodes are materialised as widgets by `GraphView` — there is no virtualization, so a
1 000-person tree builds 1 000 cards + a full layout on every rebuild (theme change, settings change,
any provider tick). Combined with `InteractiveViewer(constrained: false)` nothing is culled.

Impact: visible jank → seconds-long freeze / ANR on mid-size trees; wasted CPU on every rebuild.

Fix: build the `Graph` once per `treeData` identity (memoize in State, keyed by a data hash), keep the
`SugiyamaAlgorithm` instance and call `forceRecalculation()` only on data change; run layout in a
`compute`/isolate and return positions; virtualize (only build cards inside the current viewport) or
switch to a `CustomPaint`-only renderer for large trees.

### 1.3 (High) `zoomOnLoad` is dead in the tree view
`family_tree_page.dart:83` reads the setting and `family_tree_page.dart:314` declares
`final bool zoomOnLoad;` on `_BasicTreeCanvas`, but `_BasicTreeCanvasState` never references
`widget.zoomOnLoad` (grep: zero occurrences beyond the declaration). There is also no
`TransformationController`, so there is no fit-to-view, no center-on-root, no "reset view".

Impact: the Settings toggle does nothing for the Family Tree; users always open at scale 1 with the
graph anchored top-left; no way to frame the whole tree.

Fix: add a `TransformationController`, and on first post-frame compute the graph bounds
(`Graph.calculateGraphBounds()` is available) and set the matrix (mirror the fan-chart
`_fitToViewport` logic already in `family_fan_chart_page.dart:400–420`).

### 1.4 (Medium) Cycle handling: no infinite loop, but cycles are silently tolerated
- Data layer is safe: the ancestor/descendant BFS uses a `visitedNodes` set
  (`tree_providers.dart:70–113`) so a cyclic parent chain cannot loop forever; the depth caps
  `maxUpDepth = 3`, `maxDownDepth = 2` (lines 76–77) also bound it. Good.
- The fan-chart walk is bounded by `maxGenerations` (`tree_providers.dart:155`) — safe.
- However, cyclic input is not detected or surfaced anywhere in the tree feature; the only cycle
  detection in the app is in the integrity checker (§4). Also, because spouse edges exist in both
  directions (1.1) the graph is *always* cyclic, so `cycleRemoval` runs on every render and silently
  rewrites edges.

Fix: run the same DFS cycle check on `treeData.edges` before layout and show a warning banner;
consider deduplicating spouse edges (`if (id.compareTo(spouse.id) < 0)`) to halve edge count and avoid
the guaranteed 2-cycle.

### 1.5 (Medium) Missing-person handling is inconsistent
`basicFamilyTreeProvider`/`multiGenFamilyTreeProvider` fetch person rows for every relationship id;
`relationship_dao.dart` never filters `isDeleted`, so **soft-deleted people still appear in the tree**:
```dart
// relationship_dao.dart:36-39 (getParentPersonsOfChild)
return (_database.select(_database.genealogyPersons)
      ..where((t) => t.id.isIn(parentIds))).get();
```
No `t.isDeleted.equals(false)` filter (contrast with `genealogy_person_dao.getPeopleByTree` which does
filter). A person soft-deleted by a merge (mergedIntoId set, isDeleted=true, §3.4) therefore keeps
rendering as a live node if any family link still points at it — and merge's link repointing can leave
such rows behind on partial failure.

Fix: add `isDeleted` filters to every lookup in `relationship_dao` (and treat `mergedIntoId != null` as
deleted), or resolve parents/children/spouses through a single repository method that filters.

### 1.6 (Medium) Sibling/children ordering ignores `birthOrder`
`relationship_dao.dart:41–63` (`getChildPersonsOfParent`) and `:56–58`:
```dart
final childLinks = await (_database.select(_database.familyChildrenV2)
      ..where((t) => t.familyId.isIn(familyIds))).get();
final childIds = childLinks.map((e) => e.childId).toList();
...
return (_database.select(_database.genealogyPersons)
      ..where((t) => t.id.isIn(childIds))).get();
```
No `orderBy`, and `IN (...)` order is not preserved → children come back in rowid order. The tree card,
person page, and sibling list therefore ignore `familyChildrenV2.birthOrder`
(`genealogy_person_dao.getChildrenForFamily` does order by it, but the tree does not use that path).
`relationToChild`/spouse ordering: `getFamiliesForPerson` orders by `isPrimaryMarriage desc,
marriageDate asc` (good) but `getSpouses` (used by the tree) returns `IN` order.

Fix: order children by `birthOrder` (fallback `createdAt`) before returning; sort spouses by
`isPrimaryMarriage`/`marriageDate`; ideally sort inside `FamilyChildrenV2` join.

### 1.7 (Medium) Fan chart: painted sectors and card geometry disagree
- Cards are placed around `arcCenter = Offset(canvasWidth / 2, canvasHeight + 220)` with
  `baseRadius = 200`, `radiusStep = 145` (`family_fan_chart_page.dart:472–476, 484`).
- Sectors are painted around `center = Offset(canvasWidth / 2, canvasHeight / 2)` with
  `radius = 110 + generation * 120`, `innerRadius = radius - 108` (`:513–537`).
Two different centres **and** different radii. The auto-fit (`:400–420`) uses
`_contentBounds(nodes)` — the *card* extents — while what the user sees is the painted sector fan, so
`zoomOnLoad` frames an offset region. With `maxGenerations = 8`
(`fan_chart_settings_provider.dart:4`) sector radius reaches `110 + 8·120 = 1070 > canvasHeight/2 = 800`,
i.e. the fan paints outside the 1600×1600 `SizedBox` while hit-testing is clipped to the child's box.

Impact: wrong initial framing, generated fan chart drifts off-centre/off-canvas at higher generation
counts, misleading empty space.

Fix: derive card positions from the same `(center, innerRadius, outerRadius, angleRange)` as the sectors
(place the card at the sector's mid-angle/mid-radius), and size the canvas from the max radius instead
of hard-coding 1600.

### 1.8 (Low) Root sector is unhittable
`family_fan_chart_page.dart:513–521` gives the root `startAngle: 0, sweepAngle: 2 * math.pi`, and
`_FanSector.contains` (`:649–662`) normalises `startAngle + sweepAngle` → `0`, so
`if (start <= end) return angle >= start && angle <= end;` requires `angle == 0`. Tapping the centre
circle can never open the root profile.

Fix: special-case full-circle sectors (`sweepAngle >= 2π - ε` → radius test only), or set
`startAngle: -math.pi/2` and branch on wrap-around properly.

### 1.9 (Low) Fan chart duplicates shared ancestors (pedigree collapse) with no marking
`tree_providers.dart:155–212` walks each generation independently (`nextGenerationPersons.addAll`)
without tracking which people were already emitted, so a person appearing through two lines is painted
in every slot they occupy, recursively. Also `father/mother` assignment falls back to positional
"first unknown = father" (`:166–172`), which mislabels a second male parent as *mother*.

Fix: keep a `Set<String> emittedPersonIds` and flag repeats as "shared ancestor" hints; only assign
father/mother when `gender` is explicit, otherwise render neutral "Parent" slots.

### 1.10 (Low) Dead/unreachable code
- `tree_page.dart` is a placeholder ("Tree view coming next") and is **not routed** (`/tree` →
  `FamilyTreePage` in `app_router.dart:67`).
- `_TreePersonCard`'s whole `isHint` branch (`family_tree_page.dart:398–470`) is unreachable: every
  card is constructed with `isHint: false` (`:399` builder).
- `zoomOnLoad` parameter (§1.3) unused.

---

## 2. Dashboard / upcoming birthdays

### 2.1 (Medium) Day arithmetic truncation + Feb-29 policy
`dashboard_providers.dart:71–81` and `:113–119`:
```dart
var nextBirthday = _safeBirthday(today.year, birthDate.month, birthDate.day);
if (nextBirthday.isBefore(todayDate)) { nextBirthday = _safeBirthday(today.year + 1, ...); }
final daysLeft = nextBirthday.difference(todayDate).inDays;
```
`DateTime(y,m,d)` are local midnights; across a DST transition the difference is 23 h → `inDays == 0`,
so tomorrow's birthday can render as "Today" (and "0 days"). Not triggered in IST (no DST) but the app
ships iOS/Android/desktop worldwide. `_safeBirthday` (`:130–133`) clamps Feb 29 → Feb 28 in common
years via `DateTime(year, month + 1, 0).day` — the clamp itself is correct (including the December
wrap), but the *displayed* `nextBirthday` is then the clamped date, so a Feb-29 person shows
"28-02-YYYY" as their birthday in 3 out of 4 years.

Fix: compute using date-only arithmetic (`DateUtils.dateOnly`, then `daysBetween` over UTC dates) and
store the *real* anniversary date separately from the display date, or roll Feb 29 → Mar 1
(explicit policy + a note in the UI).

### 2.2 (High, cross-feature) `isLiving` is never derived from data
`dashboard_providers.dart:69, 111` skip `!person.isLiving`, and the column defaults to `true`
(`tables/genealogy_persons_table.dart`, `isLiving default true`) — unchanged by the GEDCOM importer
even when `DEAT` exists (§5.4). So dead ancestors imported from GEDCOM generate birthday reminders, and
`DashboardStats.livingMembers/deceasedMembers` (`dashboard_providers.dart:32–38`) are wrong for them.

Fix: set `isLiving = deathDate == null` on import/update, or compute `isLiving` at read time as
`deathDate == null` and keep the column only as an override.

### 2.3 (Low) Duplicated aggregation and no caching policy
`_countUpcomingBirthdays` (`:102–126`) and `upcomingBirthdaysProvider` (`:56–98`) implement the same
loop twice. `upcomingBirthdaysProvider` is a plain `Provider` recomputed on every watch/rebuild, and
`dashboardStatsProvider` recomputes on every `peopleListProvider` emission (i.e. every DB write).
Cost is O(n) — acceptable today, but it is a per-frame recomputation of a date-scan for a
`Provider` that could be a `select`.

Fix: single shared function; memoize per (people, day) as a `Provider.family` keyed by `today`.

### 2.4 (Low) `membersWithPhotos` = "path is non-empty"
`dashboard_providers.dart:25–30` counts a photo whenever `profilePhotoPath` is a non-empty string; it
never checks the file exists. After a restore that drops photo files, or after manual file deletion,
the "With Photos" statistic stays high while avatars render broken.

Fix: verify existence lazily (or maintain a `photoMissing` flag during restore/integrity check).

---

## 3. Duplicate detection and merge

### 3.1 (High) O(n²) + per-pair DB round-trip on the main isolate
`duplicate_detection_providers.dart:50–94`:
```dart
for (var i = 0; i < people.length; i++) {
  for (var j = i + 1; j < people.length; j++) {
    ...
    final match = _scoreDuplicate(a, b);
    if (match == null) continue;
    final preview = await repository.getMergePreview(   // 4 queries each
      survivorId: match.primary.id, duplicateId: match.duplicate.id);
```
The scoring itself is O(n²) pairs × (2× `_normalizedName`, full `_levenshtein` (O(len²)) twice), and
each surviving candidate adds `getMergePreview` = 4 SQL queries + `getFamiliesForPerson`
(`genealogy_repository.dart:233–264`) executed **serially with `await` inside the loop**. As a
`FutureProvider` it runs on the UI isolate. For n = 1 000 → 499 500 pairs (≈10⁸ char comparisons);
for a 5 000-person GEDCOM this is minutes of frozen UI.

Fix: (a) bucket candidates by blocking keys first — e.g. `lower(lastName)` or a phonetic/normalised
surname soundex, and only compare within a bucket; (b) compute score with trigram/Jaro-Winkler or a
bounded Levenshtein window; (c) defer `getMergePreview` to the moment the user opens a pair; (d) run
the scan in an isolate (`Isolate.run`) with progress reporting; (e) add an n-limit / "scan in
background" affordance.

### 3.2 (Medium) Score model is unbounded and has false-positive shape
`_duplicateScore` (`:172–196`) sums weights to a theoretical max of 202:
`50 + 30 + 10 + 35 + 20 + 15 + 20 + 8 + 10 + 4`. Threshold is `if (score < 62) return null;` (`:129`).
Because `fullNameMatch (50) + sameLastName (15) + nameDistance ≤ 2 (10)` already reaches 75 **with no
date evidence at all**, "John Smith" vs "John Smith" (father and son, both living, no dates) is surfaced
(even in the "high-confidence only ≥ 80" filter at `duplicate_detection_page.dart:50`). Conversely
`_normalizedName` strips everything outside `[a-z0-9]`, so diacritics and non-Latin scripts lose signal
in the fuzzy component (the structured comparison still helps).

Fix: normalise to 0–100, cap the fuzzy contribution, require **at least one independent axis**
(a date or a place) before emitting a candidate, and penalise same-name with discordant birth years
more strongly (currently `-0`; only `+8` is *added* for near years).

### 3.3 (Low) Score rendered as a percentage though it is not one
`duplicate_detection_page.dart:236` `Chip(label: Text('${candidate.score}%'))` while scores can exceed
100; `marked_duplicates_page.dart:538–544` assigns the *move count* to the same `score` field, so a
marked pair shows e.g. "17%".

Fix: display "score 87/100" (after clamping) or a qualitative label; don't reuse `score` for move counts.

### 3.4 (Critical) `mergePeople` is not transactional
`genealogy_repository.dart:266–456` performs, sequentially and without `_database.transaction(...)`:
reassignment of `familiesV2.husbandId/wifeId` rows (lines ~290–304), the `familyChildrenV2` child
repointing loop (`:305–330`), four table-wide updates (`surnameEvents`, `events`, `mediaItems`,
`researchNotes`, `:333–352`), the survivor field merge (`:356–440`), the soft delete (`:442–452`) and
marker cleanup (`:454–456`). Every `await` is a failure point.

Concrete failure path: `familyChildrenV2` has `UNIQUE(family_id, child_id)`
(`tables/family_children_v2_table.dart`, `customConstraints`), but the pre-check at `:312–320` only
looks at non-deleted rows:
```dart
final survivorAlreadyChild = await (_database.select(_database.familyChildrenV2)
      ..where((t) => t.familyId.equals(link.familyId) &
                    t.childId.equals(survivorId) & t.isDeleted.equals(false)))
```
If a soft-deleted `(family, survivor)` row exists (very likely after an earlier merge or unlink), the
`update ... childId = survivorId` at `:328` throws `SqliteException(UNIQUE constraint failed)` —
after the family spouse slots have already been rewritten. Result: surviving person now occupies the
duplicate's marriage slot while the duplicate is still fully alive, no `mergedIntoId`, markers deleted
only if execution got that far.

Impact: silent structural corruption of relationships that the user cannot see or undo.

Fix: wrap the entire body in `await _database.transaction(() async { ... })`; make the uniqueness
pre-check ignore `isDeleted` (or hard-delete the conflicting soft-deleted row inside the transaction);
add an idempotency guard so a retry cannot half-apply.

### 3.5 (High) Merge is lossy and irreversible
`mergePeople` field merge (`:356–440`):
- Merged: firstName, middleName, lastName, birthSurname, marriedSurname, prefix, suffix, nickname,
  gender, birthDate(+qualifier), birthPlace(+lat/lng), deathDate(+qualifier), deathPlace(+lat/lng),
  currentPlace, biography, notes, profilePhotoPath.
- **Not merged** (survivor's value wins even if empty): `occupation`, `religion`, `ethnicity`,
  `displayNameFormat`, `customDisplayName`, `isPrivate`, `privacyLevel`. E.g. duplicate had
  `occupation = 'Blacksmith'`, survivor empty → data loss.
- `isLiving: Value(survivor.isLiving)` (`:431`): a living survivor merged with a deceased duplicate
  stays "living" (birthday reminders for a dead person).
- Citations are **never repointed**: `citation_links.entityId` (entityType = 'person') still points at
  the soft-deleted duplicate → citations become unreachable from the survivor
  (`tables/citation_links_table.dart`). `surname_events.relatedPersonId` is likewise untouched.
- `profilePhotoPath` of the duplicate is dropped but its file is never deleted → orphan file
  (`image_storage_service.deleteFileIfExists` is never called from `mergePeople`).
- No undo: the duplicate is soft-deleted with `mergedIntoId`, but there is no "unmerge" path, no
  snapshot of the pre-merge row, and events/media/notes lose all trace of their original owner
  (only `events`/`surnameEvents` get `updatedAt`).

Impact: irreversible quality loss on the most destructive user action in the app.

Fix: merge the missing scalar fields with the same `_keep` policy (or let the user pick per field);
derive `isLiving` from the merged dates; repoint `citationLinks.entityId` and
`surnameEvents.relatedPersonId`; write a `merge_log` row (survivor, duplicate, field-level diff) to
power an undo; delete orphaned media files.

### 3.6 (Medium) `getDuplicateMarkers` ignores its `treeId` argument
`genealogy_repository.dart:200–202`:
```dart
Future<List<DuplicateMarker>> getDuplicateMarkers(String treeId) async {
  return _database.select(_database.duplicateMarkers).get();
}
```
Returns markers for **all** trees (and the parameter is unused → dead signature). `markAsDuplicate`
also never checks for an existing marker for the pair, so re-marking inserts duplicates (the UI hides
them because `_markerKey` sorts the ids, the rows still accumulate).

Fix: filter by `treeId`, dedupe on insert (`insertOrIgnore` with a unique index on the sorted pair).

### 3.7 (Medium) Marked-duplicates crash when a person is gone
`marked_duplicates_page.dart:529–530`:
```dart
primary: marker.personA ?? marker.personB!,
duplicate: marker.personB ?? marker.personA!,
```
If both `personA` and `personB` are null (both merged away, or the tree changed), this throws a null
check error inside the tap handler. The `markedDuplicatesProvider` itself tolerates nulls
(`personA`/`personB` are nullable) but the "Open first"/merge paths assume at least one exists —
`_BulkActionBar.onOpenFirst` (`:196`) always pushes `/people/${marker.personAId}` even when that id
is a merged/soft-deleted person (→ "Selected person not found" page).

Fix: filter out markers whose people no longer exist (or auto-clean them), and null-guard the merge
dialog construction.

---

## 4. Integrity check

### 4.1 (Medium) Only two invariants are actually checked
`integrity_check_providers.dart` implements exactly:
1. Parent/child age gap: `ageGap < 0` → error; `ageGap < 12` → warning (`:41–64`), using
   `difference(...).inDays / 365.25`.
2. A single DFS (`:71–100`) that reports "Circular parent-child chain" (and `break`s after the first
   finding — `:92–103` in the caller loop), so N cycles are reported as one issue.

Everything else advertised by an "integrity check" is missing: birth after death, dates in the future,
implausible lifespans (>130), self-parent/self-spouse, person referenced by a family/event/media row
but absent (`byId[rel.personId] == null` is silently skipped at `:43` rather than reported), soft-deleted
or `mergedIntoId` persons still referenced, duplicate family links for the same child, families with no
parents, media whose `filePath` no longer exists on disk, unsorted/duplicate `birthOrder`, and
`profilePhotoPath` files missing.

The DFS is also O(V·E) because each call rescans the whole edge list
(`parentChildRels.where(...)` inside `dfs`, `:76–79`) — fine for 100 people, quadratic for a large tree.
Because the provider is a plain `FutureProvider` with no refresh button and no invalidation, results
are cached for the session (`:20`) — fixing an issue and returning to the page still shows the old list.

Fix: broaden the checks (list above), iterate all cycles (drop the `break`), build an adjacency map
once for O(V+E), and add `ref.invalidateOnFocus`/a Refresh button.

### 4.2 (Low) Age-gap check ignores death dates and qualifiers
Parent-child gap uses only birth dates, so a parent who died before the child was born is not flagged,
and `birthDateQualifier = 'ABT'/'BEF'/'BET'` (which the app imports from GEDCOM, §5.3) is ignored —
an "ABT 1900" parent is compared as if exact.

Fix: subtract life overlap (parent must be alive at child's birth within tolerance), and skip/loosen
comparisons when either date has a qualifier.

---

## 5. GEDCOM

### 5.1 (High) Encoding: UTF-8 only, `CHAR`/ANSEL/ANSI unsupported
`gedcom_parser.dart:31–33`:
```dart
static Future<List<GedcomNode>> parseFile(File file) async {
  final lines = await file.readAsLines(encoding: utf8);
```
Real-world GEDCOM 5.5.1 files are commonly `ANSEL` (legacy genealogy export) or `ANSI` / `WINDOWS-1252`
and declare it in the header (`1 CHAR ANSEL`). Invalid UTF-8 bytes make `readAsLines` throw
`FormatException`, which `GedcomImportNotifier` surfaces as a generic failure
(`gedcom_import_providers.dart:18–26`) — the whole import dies with no partial result and no hint.
The `CHAR` header tag is never read anywhere in the importer. Line endings are split on `\n`/`\r\n`
only, so classic `\r`-only (old Mac) files parse as a single line. A UTF-8 BOM makes the first line's
level unparsable (`int.tryParse('\uFEFF0')` → null) and the `HEAD` record is dropped.

Fix: read bytes, detect encoding (BOM → UTF-8/UTF-16; otherwise read `1 CHAR` from the header bytes
and map `ANSEL/WINDOWS-1252/LATIN1/UNICODE` to a decoder, e.g. `windows-1252`/a small ANSEL table),
fall back to latin1 for byte values > 0x7F; normalise line endings (`\r\n|\r|\n`); strip BOM.

### 5.2 (High) No export — round-trip impossible
`settings_page.dart:281–289` shows "GEDCOM Export" with `content: Text('GEDCOM export will be added later.')`.
A repo-wide grep (`toGedcom|exportGedcom|gedcom` write path) finds only the importer and this stub.
So imported trees can never be exported, shared with other genealogy software, or diffed.

Fix: implement an exporter (HEAD/SUBM, INDI with NAME/GIVN/SURN/SEX/BIRT/DEAT/NOTE, FAM with
HUSB/WIFE/CHIL/MARR, `CHAR UTF-8`), share via `share_plus` as the backup flow already does; add a
round-trip test (export → re-import → compare).

### 5.3 (High) Date parsing: qualifiers become exact dates, `BET ... AND ...` collapses
`gedcom_importer.dart:157–200`:
```dart
for (final p in parts) {
  if (months.containsKey(p)) { month = months[p]; }
  else if (int.tryParse(p) != null) {
    final val = int.parse(p);
    if (val > 31) { year = val; } else { day = val; }
  }
}
DateTime? date;
if (year != null) { date = DateTime(year, month ?? 1, day ?? 1); }
```
- `"BET 1900 AND 1910"`: qualifier `BET` is stripped, then `1900` sets `year`, `1910` **overwrites**
  it → stored as exactly `1910-01-01` with `birthDateQualifier='BET'`. The app then treats it as an
  exact date (birthday reminders, age gap, sorting).
- `"BEF 1850"`, `"AFT 1900"`, `"ABT 1875"` → `1850-01-01` / `1900-01-01` / `1875-01-01` exact.
- `"12 1900"` sets `day=12, year=1900` (ok), but a bare two-digit year e.g. `50` → `50 > 31` → year 50 AD.
- `raw` is returned in `GedcomDateResult` but never persisted (there is no raw-date column on
  `genealogy_persons`), so the original text is lost.
- `node.getChild('DATE')` returns only the first `DATE`, so a second `DATE` (e.g. in an `EVEN`
  sub-structure) is ignored.

Fix: keep the raw date string (add `birthDateRaw`/`deathDateRaw` columns or write it into events),
only synthesise a `DateTime` for unambiguous `DD MMM YYYY` / `MMM YYYY` / `YYYY`, store range
qualifiers with both bounds, and never emit a date for `BEF/AFT/BET`.

### 5.4 (High) `DEAT` does not set `isLiving = false`
The person companion built at `gedcom_importer.dart:78–95` sets `deathDate`, `deathPlace`,
`deathDateQualifier` — but never `isLiving`. The column default is `true`, so every imported deceased
person counts as living (dashboard "Living", birthday reminders, tree avatar styling).

Fix: `isLiving: Value(deatDate.date == null && deatNode == null)`.

### 5.5 (Medium) Formatting/whitespace corruption and silent line drops
`gedcom_parser.dart:37–70`:
```dart
for (var line in lines) {
  line = line.trim();                       // 37
  if (line.isEmpty) continue;               // 38
  final parts = line.split(' ');            // 40
  if (parts.length < 2) continue;           // 41  (silent drop)
  final level = int.tryParse(parts[0]);
  if (level == null) continue;              // 44  (silent drop)
  ...
  value = parts.sublist(2).join(' ');       // 64  (rejoins with a single space)
```
- `trim()` destroys `CONC` semantics: GEDCOM `CONC` appends the value **verbatim**, and the leading
  space of the continuation is significant. The handler at `:73–82` concatenates the already-trimmed
  `value`, so long note/address text loses spaces at every wrap point.
- `split(' ')` + `join(' ')` collapses any run of spaces inside values (names like `"John  van der
  Berg"`, addresses, note indentation).
- Malformed lines (`parts.length < 2`, non-numeric level) are dropped with **no counter, no warning**;
  a level jump (>1) silently attaches the node to the nearest ancestor instead of flagging corruption.
- No escape processing: `@@` (literal `@`) and `@#DGREGORIAN@`-style date escapes are passed through
  unchanged, so imported notes render with literal `@@` and `@#...@`.

Fix: preserve the raw line, split once on the first space characters only for level/pointer/tag
(`RegExp(r'^(\d+)\s+(?:(@[^@]+@)\s+)?(\S+)(?:\s(.*))?$')`), keep the remainder verbatim, handle
`CONC`/`CONT` with the untrimmed remainder, and unescape `@@`. Collect a diagnostics list
(line number + reason) to show after import.

### 5.6 (Medium) Very partial tag coverage
The importer only reads `INDI: NAME/SEX/BIRT(DATE,PLAC)/DEAT(DATE,PLAC)/NOTE`, and
`FAM: HUSB/WIFE/CHIL/MARR(DATE,PLAC)` (`gedcom_importer.dart:38–147`). Ignored, therefore lost:
`SOUR`/`CITN`/`PAGE`/`QUAY` citations (the app has `citations`/`citation_links` tables — nothing is
written), `OBJE`/`FILE`/`FORM` media (photos in GEDCOM never arrive), `OCCU`, `RESI`, `EDUC`, `EVEN`,
`CHR`/`BAPM`/`BURI`/`CREM`, `ADOP`, `DIV`/`DIVF`, `FAMS`/`FAMC` (the importer derives links from the
FAM side only, which is normally equivalent but not guaranteed), `ALIA`, `ASSO`, `REFN`, `RIN`, `RFN`,
`AFN`, `UID`, `ADDR`/`PHON`/`EMAIL`, `_UID`, and vendor tags. Multiple `NAME` nodes (alias / married
name) are ignored because `getChild('NAME')` returns only the first; in-line `1 NOTE @N5@` pointers are
stored as the literal text `"@N5@"` (`:92` `notes: Value(noteNode?.value)`).

Fix: add a tag dispatch table, wire `SOUR` → `citations`/`citation_links`, `OBJE` → copy the file from
a chosen folder into `person_media` + a `media_items` row, map `OCCU/RESI/EDUC` → `events`, and resolve
`NOTE`/`SOUR` pointers against their top-level records. Ignore unknown tags but count them for a report.

### 5.7 (Medium) Name parsing edge cases
`gedcom_importer.dart:48–60`:
```dart
final rawName = nameNode.value ?? '';
final parts = rawName.split('/');
firstName = parts.isNotEmpty ? parts[0].trim() : '';
if (parts.length > 1) lastName = parts[1].trim();
if (parts.length > 2) suffix = parts[2].trim();
if (givn != null) firstName = givn;
if (surn != null) lastName = surn;
```
- `"John //"` (unknown surname) yields `lastName = ''` instead of null → an empty (non-null) surname in
  the DB, which `displayPersonName` hides but `_structuredKey` treats as absent — inconsistent.
- A name prefix ("Dr. John /Smith/") ends up inside `firstName`; the app has a `prefix` column that is
  never populated from GEDCOM.
- Nicknames in quotes (`John "Jack" /Smith/`) are not extracted into `nickname`.
- `suffix = parts[2]` usually contains a leading space and the app's suffix convention (`Jr.`) — mostly
  harmless after trim, but two suffixes (`/Smith/ Jr. Ph.D.`) collapse into one string.
- When `NAME` lacks slashes (non-standard/vendor output) the whole string becomes `firstName`, and
  GIVN/SURN children (which are often absent) are the only recovery.

Fix: parse with a regex for `given /surname/ suffix` + quoted nickname, populate `prefix`/`nickname`/
`suffix` properly, and store empty surname as null.

### 5.8 (Medium) Re-import is not idempotent
`_personIdMap`/`_familyIdMap` generate fresh `Uuid().v4()` values per run (`gedcom_importer.dart:28–35`)
and nothing consults existing data; `insertOrIgnore` (`:150–152`) only protects exact primary-key
collisions, which cannot happen with new UUIDs. Importing the same file twice duplicates the entire
tree (and the duplicate detector will then flag every person as a duplicate of themselves, §3).

Fix: key imports by GEDCOM id per tree (`gedcom_id` column / mapping table), or offer an explicit
"merge into existing tree" mode with a preview count.

### 5.9 (Low) Error recovery and feedback
`importGedcomFile` (`gedcom_import_providers.dart:18–26`) sets `AsyncValue.loading` then
`AsyncValue.guard`; the settings page shows either "GEDCOM Import Successful!" or the raw exception
(`settings_page.dart:1220–1235`). There is no progress, no per-record report, no "N records skipped",
and parsing runs synchronously on the UI isolate (`parseLines` is a plain loop over possibly hundreds
of thousands of lines) → the progress dialog spins while the UI jank is real. A malformed line in the
middle of the file is silently dropped (§5.5), so users believe they imported everything.

Fix: stream the parse, count `parsed/inserted/skipped` per record type, return a summary object, and
show it; run parsing in an isolate for large files.

---

## 6. Backup / restore

### 6.1 (Critical) Restore overwrites the live database in place, non-atomically
`backup_service.dart:48–71`:
```dart
final archive = ZipDecoder().decodeBytes(bytes);
...
for (final file in archive.files) {
  final outputPath = p.join(appDir.path, file.name);
  if (file.isFile) { ... await outputFile.writeAsBytes(file.content as List<int>); }
```
The drift connection is open (`app_database_open_connection.dart` → `LazyDatabase` →
`NativeDatabase.createInBackground(File(.../vanshvriksh.db))`), and the restore overwrites that exact
file (plus `profile_photos/`, `person_media/`) while it is in use. The only protection is UI text:
"After restore, close and reopen the app." (`backup_restore_page.dart:150–156, 190–200`). If the user
does not restart, drift keeps serving the old page cache and may later write over the restored file;
a crash/power loss mid-extraction leaves a half-replaced DB (no temp-dir-then-rename).

Impact: silent data loss / corrupted DB on the app's most safety-critical path.

Fix: extract to a staging directory, `PRAGMA wal_checkpoint(TRUNCATE)`/close the DB, then atomically
swap (`rename`) and force an app restart (`SystemNavigator.pop()`/`Restart`); never write into
`appDir` directly; validate the staged DB with `PRAGMA integrity_check` before the swap.

### 6.2 (High) Encrypted backups leave a plaintext copy behind
`backup_service.dart:30–45` + `:220–226`:
```dart
final encryptedFile = await _encryptBackupFile(backupFile, password);
...
Future<File> _encryptBackupFile(File backupFile, String password) async {
  final encryptedBytes = _encryptBytes(await backupFile.readAsBytes(), password);
  final encryptedPath = backupFile.path.replaceAll('.zip', '.enc');
  ...
}
```
`backupFile` (the plaintext ZIP containing the whole family DB + all photos) is never deleted, is
recorded in shared preferences as history, and stays in `<documents>/backups/`. A user who believes
they created an encrypted backup still has the full plaintext dataset on the device (and in any
device/file backup that captures the app documents folder).

Fix: delete the source ZIP after successful encryption (`await backupFile.delete()`), or build the
archive entirely in memory/temp and encrypt while writing.

### 6.3 (High) Zip Slip on restore
`backup_service.dart:61–68` joins an untrusted archive entry name directly:
```dart
final outputPath = p.join(appDir.path, file.name);
```
`file.name` may contain `../` (or an absolute path), so a crafted `.zip` (the user picks it via
`FilePicker`, `backup_restore_page.dart:172–178`) can write files outside the app documents directory
— on desktop this is arbitrary file write within the user's permissions.

Fix: reject entries whose normalised path escapes the target (`p.isWithin(appDir.path, p.normalize(p.join(appDir.path, name)))`), reject absolute paths and `..` segments, and skip symlinks/links.

### 6.4 (Medium) Whole archive in memory; no manifest/version/checksum
`backup_service.dart:51` `ZipDecoder().decodeBytes(bytes)` materialises the entire archive, and `:68`
materialises each entry (`file.content as List<int>`), on top of `restoreBackup`'s earlier
`_resolveBackupBytes` (which for encrypted backups holds the full ciphertext plus the full plaintext).
A 2 GB photo backup → multiple GB of RAM → OOM. The archive also has no manifest: nothing records
app version, DB schema version, file inventory, counts, or a checksum, so a truncated/corrupt archive is
only discovered entries-deep into the restore, and there is no way to validate compatibility up front.

Fix: stream entries (`InputFileStream` + `extractArchiveToDisk`/`extractFileToDisk` from `archive`,
which also gives traversal protection), and add `manifest.json` (appVersion, schemaVersion, createdAt,
record counts, per-file sha256) verified before writing anything.

### 6.5 (Medium) Crypto: CBC without authentication, hardcoded salt, legacy KDF fallback
`backup_service.dart:266–312`:
```dart
final key = encrypt.Key(_deriveKey(password));
final iv = encrypt.IV.fromSecureRandom(16);
final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
...
final salt = utf8.encode('vanshvriksh_backup_salt');       // hardcoded
derivator.init(pc.Pbkdf2Parameters(Uint8List.fromList(salt), 100000, 32));
...
} catch (e) {
  final legacyKey = encrypt.Key(_deriveLegacyKey(password));   // SHA-256(password), 1 iteration
  ...
}
```
- No MAC/AEAD: ciphertext is malleable; a flipped bit decrypts to garbage (or, in CBC, corrupts a
  block) and is only caught later by the zip decoder. There is no way to distinguish "wrong password"
  from "corrupted file" → users get cryptic failures.
- Hardcoded salt + no stored KDF parameters means the derivation cannot ever be upgraded or
  per-backup randomised, and enables precomputation across users.
- The silent fallback to a single-round SHA-256 key keeps weak legacy backups acceptable and is
  attempted on **any** exception (including I/O-ish failures), masking real errors.

Fix: move to AES-GCM (or AES-CBC + HMAC-SHA256 with encrypt-then-MAC), store a versioned header
(`{version, kdf:'pbkdf2-sha256', iterations, salt(16B random), iv, mac}`) in the envelope, drop the
legacy path behind an explicit "old backup" code path with a clear message, and map failures to
"Wrong password or corrupted backup".

### 6.6 (Medium) Auto-backup settings are inert
`backup_restore_page.dart:400–470` renders Auto Backup, Backup Frequency (daily/weekly/monthly) and
Wi-Fi-only toggles; the subtitles admit "Enable scheduled backups later." / "Use Wi-Fi when auto
backup is added." The providers persist to `SharedPreferences`
(`settings/app_settings_provider.dart:144–167`) but no scheduler exists — `pubspec.yaml` has no
`workmanager`/`background_fetch`/`flutter_local_notifications`, no platform channel, and no timer
anywhere in `lib/`.

Impact: users reasonably assume their data is being backed up automatically; it never is.

Fix: implement with `workmanager` (Android/iOS) + a platform-appropriate desktop hook, or remove the
controls and clearly state that backups are manual.

### 6.7 (Medium) Restore does not reconcile files not present in the backup
The loop only writes entries that exist in the archive; photos/media created after the backup remain on
disk while their DB rows are gone (orphans), and `profile_photos` files that were *deleted* in the
backup's timeline reappear as DB rows pointing at missing files. Backups also exclude
`SharedPreferences` (backup history, settings, remind-on-load root person) — acceptable, but then the
restored app silently reports "No backups recorded yet" while `backups/` may still be full.

Fix: restore into a clean staging tree and swap wholesale; document exactly what is and is not included
in a backup (add a manifest summary shown in the UI).

### 6.8 (Low) Cloud backup hygiene
`uploadBackupToGoogleDrive` (`:114–150`) always `files.create`s into `appDataFolder` — no dedupe, no
retention, no size report; `restoreLatestFromGoogleDrive` (`:152–190`) picks
`orderBy: 'modifiedTime desc', pageSize: 1` **without any name/app filter**, so any other app-data file
in the folder would be downloaded as "the latest backup" (and recorded as such, `:186–190`). Scope is
the broad `driveFileScope` rather than `drive.appdata`.

Fix: prefix file names (`vanshvriksh_backup_*`) and filter on `name contains 'vanshvriksh_backup'`,
enforce retention (keep N), request `drive.appdata`, and verify the downloaded file is a valid archive
before restore.

### 6.9 (Low) Filenames and disk growth
`_createZipBackup` (`:196–218`) names backups with minute resolution
(`vanshvriksh_backup_YYYY_MM_DD_HH_MM.zip`): two backups in the same minute overwrite the first.
`<documents>/backups/` is never pruned; `getBackupHistory` caps the *history* at 20
(`_recordBackup`, `.take(20)`) but not the files, so the app's documents folder grows without bound
(each backup duplicates all photos).

Fix: include seconds/uid; delete backups beyond the retention limit; offer "delete old backups".

### 6.10 (Low) Encrypted detection by extension; inconsistent history semantics
`_isEncryptedFile` (`:243`) keys off `.enc` only, so a renamed/opened-back encrypted file is treated as
a plain ZIP (cryptic failure). `restoreLatestFromGoogleDrive` records a *backup* history entry for a
download (`:186–190`), so history mixes backups and restores. Files without `.zip` in the path skip the
`.replaceAll('.zip', '.enc')` rename semantics entirely (`:221`).

Fix: detect via a magic header/version byte inside the file; separate `backup` and `restore` history.

### 6.11 (Low) Media storage services
`image_storage_service.dart` / `media_storage_service.dart` copy the picked file verbatim (no size
check, no downscale): a 30 MB camera JPEG becomes a 30 MB avatar, and every backup carries it. Neither
service has a "verify file exists" helper used by backup/integrity. `deleteFileIfExists` is only wired
from `person_form_page.dart` and `person_media_gallery_page.dart` — never from delete-person or
`mergePeople`, so orphan files accumulate (see §3.5).

Fix: validate/limit size, optionally downscale avatars, and call `deleteFileIfExists` from person
deletion and merge; add an orphan-file sweep to the integrity check.

---

## 7. Missing major features (substantiated from code)

| Feature | Evidence |
|---|---|
| GEDCOM **export** | `settings_page.dart:281–289` stub dialog "GEDCOM export will be added later."; no exporter anywhere. |
| Print / PDF of tree or person, image export | No `pdf`/`printing` dependency in `pubspec.yaml`; no save/export path outside backup. |
| Sharing a tree, branch, or person (beyond backup file) | Only `SharePlus.instance.share(XFile(backupFile.path))` in `backup_restore_page.dart:89`. |
| Cloud **sync** | `genealogy_persons`/`families_v2`/`family_children_v2` carry `syncStatus`, `version`, `lastSyncedAt`, `uuid`, and there is a `sync_change_log` table — but a repo-wide grep finds `SyncChangeLog` referenced only by the generated drift code; no sync client/worker exists. Dead schema. |
| Multi-tree management/switching | `family_trees` table + `FamilyTreeRepository` exist, but **all** 30 usages hardcode `AppConstants.defaultTreeId` (`app_constants.dart:2`); there is no tree picker, create/rename/delete-tree UI. |
| Generation depth control in the tree | `tree_providers.dart:76–77` hardcodes `maxUpDepth = 3`, `maxDownDepth = 2`; no UI to widen it (the fan chart has a generation setting, `fan_chart_settings_provider.dart`, but the tree does not). |
| Collapse/expand branches, search & jump-to-person in the tree | `FamilyTreePage` has only a root-person dropdown; no search, no collapse (the abandoned `app/genealogy_tree_page.dart` has an expand-all toggle but is a separate, non-graph view). |
| Scheduled/automatic backup | see §6.6. |
| Backup content selection, backup delete/restore-verify | No UI; history is display-only (`backup_restore_page.dart:520–570`). |
| Duplicate merge undo/history | see §3.5. |
| Relationship calculator / "how are we related" | No implementation anywhere. |
| Media in GEDCOM import/export, citations import/export | see §5.6 (tables for citations exist but are never populated by import). |
| Dead pages shipped to users | `features/tree/tree_page.dart` ("Tree view coming next"), `features/backup/backup_page.dart` ("Import and export support will be added here") — both unrouted dead code. |

---

## 8. Adjacent finding (outside the listed directories, tree-related)

`lib/app/genealogy_tree_page.dart` (routed at `/v2/tree/:id`) renders an expandable branch list and has
two build-time hazards:
- `build()` creates a fresh future every rebuild: `FutureBuilder<List<FamiliesV2Data>>(future: repo.getFamiliesForPerson(personId))` (`:170`, `:640`) and `FutureBuilder<_BranchData>(future: _loadBranchData())` (`:366–372`). Each completion triggers `setState` → new future → new query … a self-refreshing query loop.
- `widget.visitedFamilyIds.add(widget.family.id)` is executed **inside `build()`** (`:640`) on a shared mutable `Set`, so which branches render depends on widget construction order (branches can be silently dropped).

Fix: hoist futures into `initState`/providers keyed by id; never mutate state during build; use a
`Set` copied per build.

---

## 9. Suggested remediation order

1. **Wrap `mergePeople` in a transaction** and fix the `UNIQUE(family_id, child_id)` pre-check (§3.4) — corruption risk with no recovery.
2. **Make restore atomic + safe** (staging dir, swap, integrity_check, forced restart) and close the two
   backup privacy holes (plaintext `.zip` left behind, Zip Slip) (§6.1–6.3).
3. **GEDCOM**: encoding detection, `isLiving` from `DEAT`, honest qualifier dates, then export (§5.1,
   5.3, 5.4, 5.2).
4. **Tree layout**: treat marriage as a non-hierarchical edge, layout off the UI thread, respect
   `zoomOnLoad` (§1.1–1.3).
5. **Duplicates**: blocking + isolate + one-shot preview; lossless merge (§3.1, §3.5).
6. **Integrity**: broaden invariants, iterate all cycles, add refresh (§4.1).
7. Housekeeping: dead pages, order-by fixes, score formatting, backup retention (§1.6, §1.10, §3.3, §6.9).
