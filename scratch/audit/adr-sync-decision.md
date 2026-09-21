# ADR: Sync Architecture Decision

**Status:** decided — **no sync is implemented, and none is required now.**
**Decision date:** 2026-09-21 · **Schema version:** 14

---

## 1. What was inspected

| Item | Where | State found |
|---|---|---|
| `syncStatus` | `genealogy_persons`, `families_v2`, `family_children_v2`, `surname_events` | **already removed** in the canonical-model phase: written once at insert, never read, never advanced |
| `version` | same tables | **already removed**; always `1` |
| `last_synced_at` | same tables | **already removed**; never written |
| change log | `sync_change_log` table (`source_table_name`, `record_uuid`, `change_type`, `change_data`, `sync_status`, `device_id`) | **already removed**; zero producers, zero consumers |
| `isDeleted` | persons, families, child links | present and **in use** — the soft-delete/tombstone for the local delete contract |
| timestamps | `created_at`, `updated_at` everywhere | present and **in use** — ordering, display, merge bookkeeping |
| UUIDs | persons, families, child links, surname events | present, **written but never read** (see §3) |
| merge information | `merged_into_id` (self-FK, `SET NULL`) | present and **in use** by the merge contract |

**Infrastructure:** no sync engine, no sockets, no WebSocket, no Firebase, no realtime layer. The
only network code is:
- **Google Drive backup** (`google_sign_in` + `googleapis/drive`) — a genuine, working whole-file
  upload/download of an encrypted zip. That is *file-level backup*, not record-level sync: it moves a
  snapshot between the database and the cloud, with no merge, no diff, no conflict handling.
- a Nominatim place lookup in the person form.

## 2. Determination: no current product requirement

| Capability | Required? | Evidence |
|---|---|---|
| Cloud sync | **No** | single-user, local-first app; cloud *backup* already covers "my data survives a lost device"; nothing in the UI or model asks for merged state |
| Multi-device sync | **No** | no device identity anywhere; the schema has no notion of a peer, a cursor or a lamport clock |
| Offline conflict resolution | **No** | there is nothing to conflict *with*: one writer, one database file |
| Collaborative editing | **No** | no accounts, no sharing, no permissions, no per-user attribution |

**Therefore:** simplify, remove unused sync infrastructure, keep only fields with a justified future
purpose, and document the decision. Per the brief, no half-sync architecture is left in place.

## 3. What was done

### Removed in this phase

**`uuid` from `families_v2`, `family_children_v2` and `surname_events`** (3 columns, 3 unique
constraints). Evidence: nothing in `lib/` ever *reads* a uuid — the only references were the insert
sites and the uniqueness constraint itself. Families and child links are structural rows whose
identity never travels on its own, so a stable cross-database id for them has no current or
near-future use. Removing them also removes three unique indexes' worth of write cost on every
insert.

### Kept, with the justification

| Field | Justification |
|---|---|
| `genealogy_persons.uuid` | The identity a *person* has beyond the row id. It is already part of a contract (the merge contract: the retired duplicate keeps its uuid so an external reference to that identity is still resolvable), and it is exactly the seed a future cross-database import, dedupe or sync would need. A person is the entity a user thinks about as "the same person" across databases; a family row is not. |
| `is_deleted` | The tombstone for the local soft-delete contract — reversible deletes, reads filter it. Sync would reuse it as its tombstone, which is a bonus, not the reason. |
| `created_at` / `updated_at` | Ordering, display, and merge bookkeeping. Sync would use `updated_at` as a last-writer signal; again a bonus. |
| `merged_into_id` | Consumed by the merge contract and by `restorePerson`, which refuses to resurrect a merged identity. |

### Removed earlier (for completeness)

`sync_status`, `version`, `last_synced_at` (4 tables) and the `sync_change_log` table — all write-only
or entirely unused. Nothing replaced them.

**Schema version:** 13 → 14. The upgrade path rebuilds every canonical table, so an existing database
converges on the simplified schema (verified by the schema-verification suite, which asserts that
fresh, migrated and *declared* schemas are identical).

## 4. What was explicitly NOT done

- No sync engine, no change-log table, no outbox, no peer/device table, no vector clocks, no
  tombstones table, no conflict-resolution hooks.
- No "sync-ready" columns reintroduced. A future sync design decides its own schema; pre-building it
  is exactly the half-sync architecture the brief forbids.

## 5. If sync is ever required — the design that must exist first

This is a **sketch for a future decision, not an implementation plan that has been started.** It is
recorded so the next engineer does not have to rediscover the questions, and so that this decision can
be reversed deliberately rather than drifted into.

| Concern | What must be decided before any code |
|---|---|
| Change identity | every syncable row needs a stable id that survives round trips: `genealogy_persons.uuid` already provides it for people; families/links would need it back, or a different addressing scheme (e.g. path-based) |
| Ordering | needs a logical clock (per-device counter + device id), not wall-clock `updated_at`, which cannot order concurrent edits |
| Conflict resolution | per-field policy: last-writer-wins is unacceptable for genealogy facts; the merge contract's "survivor wins unless absent, caller can prefer the duplicate" is the in-app analogue and suggests field-level merge with user review for genuine conflicts |
| Tombstones | soft delete already exists for people; families and links are flagged too. Tombstone retention/GC policy must be defined, or a deleted row resurrects on the next pull |
| Merge conflicts | merging is already a first-class operation with a documented contract; sync must decide whether merges are synced as *operations* or as *states* — the former is far safer |
| Resurrection | a row deleted on one device and edited on another needs a rule; the current soft delete makes "deleted wins" cheap, "edit wins" explicit |
| Deletes | deleting a tree currently purges rows; a purge is not syncable without a tombstone for every purged row (a "tree deleted" marker would be needed instead) |
| Retries | uploads must be idempotent: a repeated push of the same change must be a no-op, which means changes carry their own identity (not just their row's) |
| Idempotency | requires per-change ids and a durable record of what has been applied |
| Versioning | the payload and the schema version must both be negotiated, and the backup format is already encrypted+versioned groundwork |

The honest summary: **a real sync design is a project, not a column.** Nothing in the current app
would be wasted on it (uuid on people, soft delete, `updated_at`, and the merge contract are all
useful), and nothing in the current app pretends it exists.

## 6. Triggers to revisit this decision

1. A request for the same tree on two devices with both editable.
2. Accounts, sharing, or any second writer of the database.
3. A web deployment that expects live data rather than the current local-first model.
4. Any feature that would need to reconcile two divergent copies (e.g. importing a relative's tree).

Until one of those exists, sync stays unimplemented and undocumented in the schema — which is what
this ADR records.

---

## 7. Phase report

- **Files changed:** `families_v2_table.dart`, `family_children_v2_table.dart`,
  `surname_events_table.dart` (uuid columns removed), `app_database.dart` (schemaVersion 14, migration
  inserts without uuid), `relationship_repository.dart`, `genealogy_repository.dart`,
  `gedcom_importer.dart` (insert sites), `app_database.g.dart` (regenerated),
  `test/support/schema_expectations.dart` (v14, three columns and two unique constraints removed),
  four test files updated.
- **Schema changes:** `schemaVersion` 13 → **14**; three `uuid` columns and their unique constraints
  removed. No other change.
- **API changes:** none. (Companions for families/child links/surname events no longer take `uuid`.)
- **Tests added/changed:** expectations updated; test insert sites updated; schema-version assertions
  now reference the declared constant instead of a literal. **177 passing / 0 failing / 0 skipped.**
- **Analyzer:** 18 issues, 0 errors.
- **Build:** `flutter build web --debug` → **success** (`√ Built build\web`, 56.5 s).
- **Remaining risks:**
  1. `genealogy_persons.uuid` is still write-only. It is kept deliberately (§3) — the first consumer
     will be an export, a cross-database import or a sync design. If none of those materialises, it is
     the next candidate for removal.
  2. Google Drive backup is a real cloud dependency; it is backup, not sync, and this ADR should stop
     anyone from mistaking one for the other.
  3. Restoring an old backup replaces the whole database file — there is no merge path, by decision.
- **Commit hash:** see the commit carrying this file.
