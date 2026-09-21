import 'package:drift/drift.dart';

import '../../core/constants/app_constants.dart';
import 'tables/citation_links_table.dart';
import 'tables/citations_table.dart';
import 'tables/duplicate_markers_table.dart';
import 'tables/events_table.dart';
import 'tables/families_v2_table.dart';
import 'tables/family_children_v2_table.dart';
import 'tables/family_trees_table.dart';
import 'tables/genealogy_persons_table.dart';
import 'tables/media_items_table.dart';
import 'tables/research_notes_table.dart';
import 'tables/surname_events_table.dart';
import 'tables/todos_table.dart';
import 'daos/events_dao.dart';
import 'daos/genealogy_person_dao.dart';
import 'daos/research_notes_dao.dart';

import 'app_database_open_connection.dart'
    if (dart.library.html) 'app_database_open_connection_web.dart';

part 'app_database.g.dart';

/// The canonical genealogy database.
///
/// Model ownership:
/// ```
/// FamilyTree
///   ├── Person            (genealogy_persons.tree_id  → family_trees.id)
///   └── Family            (families_v2.tree_id        → family_trees.id)
///         ├── partner      (husband_id / wife_id      → genealogy_persons.id)
///         └── child        (family_children_v2.family_id / child_id)
/// ```
/// Person-scoped records (events, media, notes, todos, surname events) are owned
/// through `person_id`; duplicate markers are owned through the pair of people.
/// Every one of those paths is a real foreign key.
///
/// Two legacy tables (`persons`, `relationships`) are **not** part of the model.
/// They only ever existed on databases created before schema v10, are read by
/// the upgrade path through raw SQL, and are dropped by `_upgradeToCanonicalSchema`.
@DriftDatabase(
  tables: [
    FamilyTrees,
    GenealogyPersons,
    SurnameEvents,
    FamiliesV2,
    FamilyChildrenV2,
    MediaItems,
    Events,
    DuplicateMarkers,
    Citations,
    CitationLinks,
    ResearchNotes,
    Todos,
  ],
  daos: [
    GenealogyPersonDao,
    EventsDao,
    ResearchNotesDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 3) {
            await m.createTable(events);
            await m.createTable(citations);
            await m.createTable(citationLinks);
            await m.createTable(researchNotes);
            await m.createTable(todos);
          }
          if (from < 4) {
            await customStatement(
              'ALTER TABLE research_notes ADD COLUMN note_date_sort REAL',
            );
            await customStatement(
              'ALTER TABLE research_notes ADD COLUMN note_date_display TEXT',
            );
          }
          if (from < 5) {
            await m.createTable(duplicateMarkers);
          }
          if (from < 6) {
            await customStatement(
              'ALTER TABLE persons ADD COLUMN birth_surname TEXT',
            );
            await customStatement(
              'ALTER TABLE persons ADD COLUMN married_surname TEXT',
            );
          }
          if (from < 7) {
            await m.createTable(genealogyPersons);
            await m.createTable(surnameEvents);
            await m.createTable(familiesV2);
            await m.createTable(familyChildrenV2);
          }
          if (from < 8) {
            await _absorbLegacyPersons();
          }
          if (from < 10) {
            await _absorbLegacyRelationships();
          }
          if (from < 12) {
            await _upgradeToCanonicalSchema(m);
          }
        },
        beforeOpen: (details) async {
          // Enable foreign keys on EVERY connection, not just first create.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // ---------------------------------------------------------------------------
  // v11 → v12: canonical schema
  // ---------------------------------------------------------------------------

  /// Brings an older database to the canonical model:
  /// rebuilds every table whose definition changed (dropped sync columns, new
  /// foreign keys, new indexes), backfills the new mandatory `families_v2.tree_id`
  /// and drops the tables that are no longer part of the model.
  Future<void> _upgradeToCanonicalSchema(Migrator m) async {
    // Legacy data first: both of these are no-ops on a v10+ database.
    await _absorbLegacyPersons();
    await _absorbLegacyRelationships();

    await _ensureDefaultTreeRow();
    await _repairPreExistingData();
    await m.alterTable(TableMigration(familyTrees));
    await m.alterTable(TableMigration(genealogyPersons));
    await m.alterTable(
      TableMigration(
        familiesV2,
        // `tree_id` is mandatory in the new model. Every family in a pre-v12
        // database belongs to the application's single default tree; if that
        // tree is missing the foreign key makes the copy fail loudly instead of
        // inventing an owner.
        columnTransformer: {
          familiesV2.treeId: const Constant(AppConstants.defaultTreeId),
        },
      ),
    );
    await m.alterTable(TableMigration(familyChildrenV2));
    await m.alterTable(TableMigration(duplicateMarkers));
    await m.alterTable(TableMigration(surnameEvents));
    await m.alterTable(TableMigration(events));
    await m.alterTable(TableMigration(mediaItems));
    await m.alterTable(TableMigration(researchNotes));
    await m.alterTable(TableMigration(todos));

    // Tables that are no longer part of the model.
    await customStatement('DROP TABLE IF EXISTS persons');
    await customStatement('DROP TABLE IF EXISTS relationships');
    await customStatement('DROP TABLE IF EXISTS sync_change_log');
  }

  /// Makes sure the ownership root exists before anything references it.
  Future<void> _ensureDefaultTreeRow() async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await customStatement(
      'INSERT OR IGNORE INTO family_trees '
      '(id, tree_name, description, root_person_id, created_at, updated_at) '
      "VALUES ('${AppConstants.defaultTreeId}', 'My Family', "
      "'Default family tree', NULL, $now, $now)",
    );
  }

  /// Cleans up states that the new constraints would reject, so the rebuild
  /// cannot fail on pre-existing rows.
  Future<void> _repairPreExistingData() async {
    if (await _tableExists('family_trees')) {
      // `root_person_id` is an optional pointer, not a foreign key (see
      // family_trees_table.dart), so stale values are cleared here.
      await customStatement(
        'UPDATE family_trees SET root_person_id = NULL '
        'WHERE root_person_id IS NOT NULL AND root_person_id NOT IN '
        '(SELECT id FROM genealogy_persons)',
      );
    }

    if (await _tableExists('families_v2')) {
      // Duplicate couples / duplicate single-parent families.
      await customStatement(
        'DELETE FROM families_v2 WHERE id NOT IN '
        "(SELECT MIN(id) FROM families_v2 "
        " GROUP BY COALESCE(husband_id, ''), COALESCE(wife_id, ''))",
      );
      // Partner slots pointing at people that no longer exist.
      await customStatement(
        'UPDATE families_v2 SET husband_id = NULL '
        'WHERE husband_id IS NOT NULL AND husband_id NOT IN '
        '(SELECT id FROM genealogy_persons)',
      );
      await customStatement(
        'UPDATE families_v2 SET wife_id = NULL '
        'WHERE wife_id IS NOT NULL AND wife_id NOT IN '
        '(SELECT id FROM genealogy_persons)',
      );
      await customStatement(
        "UPDATE families_v2 SET tree_id = '${AppConstants.defaultTreeId}' "
        "WHERE tree_id IS NULL OR tree_id NOT IN (SELECT id FROM family_trees)",
      );
    }

    if (await _tableExists('genealogy_persons')) {
      await customStatement(
        "UPDATE genealogy_persons SET tree_id = '${AppConstants.defaultTreeId}' "
        "WHERE tree_id IS NULL OR tree_id NOT IN (SELECT id FROM family_trees)",
      );      await customStatement(
        'UPDATE genealogy_persons SET merged_into_id = NULL '
        'WHERE merged_into_id IS NOT NULL AND merged_into_id NOT IN '
        '(SELECT id FROM genealogy_persons)',
      );
    }

    if (await _tableExists('family_children_v2')) {
      await customStatement(
        'DELETE FROM family_children_v2 WHERE family_id NOT IN '
        '(SELECT id FROM families_v2) OR child_id NOT IN '
        '(SELECT id FROM genealogy_persons)',
      );
    }

    if (await _tableExists('duplicate_markers')) {
      await customStatement(
        'DELETE FROM duplicate_markers WHERE person_a_id = person_b_id '
        'OR person_a_id NOT IN (SELECT id FROM genealogy_persons) '
        'OR person_b_id NOT IN (SELECT id FROM genealogy_persons)',
      );
      // Store the pair in a canonical order so UNIQUE covers both directions.
      await customStatement(
        'UPDATE duplicate_markers SET person_a_id = person_b_id, '
        'person_b_id = person_a_id WHERE person_a_id > person_b_id',
      );
      await customStatement(
        'DELETE FROM duplicate_markers WHERE id NOT IN '
        '(SELECT MIN(id) FROM duplicate_markers '
        ' GROUP BY person_a_id, person_b_id)',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Legacy absorption (raw SQL: these tables are not part of the model)
  // ---------------------------------------------------------------------------

  Future<bool> _tableExists(String table) async {
    final rows = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable<String>(table)],
    ).get();
    return rows.isNotEmpty;
  }

  Future<int> _rowCount(String table) async {
    final row = await customSelect('SELECT COUNT(*) AS c FROM $table').getSingle();
    return row.data['c'] as int? ?? 0;
  }

  /// Copies `persons` into `genealogy_persons` (schema < 8 databases).
  Future<void> _absorbLegacyPersons() async {
    if (!await _tableExists('persons')) return;
    if (await _rowCount('persons') == 0) return;
    if (await _rowCount('genealogy_persons') > 0) return;

    await _ensureDefaultTreeRow();

    await customStatement('''
      INSERT INTO genealogy_persons (
        id, first_name, middle_name, last_name, birth_surname, married_surname,
        prefix, suffix, nickname, display_name_format, custom_display_name,
        gender, birth_date, birth_place, current_place, death_date, is_living,
        profile_photo_path, biography, notes, is_private, privacy_level,
        tree_id, uuid, is_deleted, created_at, updated_at
      )
      SELECT
        p.id,
        COALESCE(p.first_name, ''),
        p.middle_name,
        p.last_name,
        COALESCE(p.birth_surname, p.last_name),
        CASE WHEN p.gender = 'female' THEN p.married_surname ELSE NULL END,
        p.prefix, p.suffix, p.nickname,
        'birth_married',
        p.full_name,
        p.gender, p.birth_date, p.birth_place, p.current_place, p.death_date,
        p.is_living, p.profile_photo_path, p.bio, p.notes, p.private, 0,
        p.tree_id, p.id, 0, p.created_at, p.updated_at
      FROM persons p
    ''');

    // Surname history implied by the legacy birth/married surname columns.
    await customStatement('''
      INSERT OR IGNORE INTO surname_events (
        id, person_id, surname, surname_type, sort_order, is_primary,
        uuid, created_at, updated_at
      )
      SELECT
        p.id || '-birth-surname', p.id,
        TRIM(COALESCE(p.birth_surname, p.last_name)), 'birth', 0, 1,
        p.id || '-birth-surname', p.created_at, p.updated_at
      FROM persons p
      WHERE TRIM(COALESCE(p.birth_surname, p.last_name, '')) <> ''
    ''');
    await customStatement('''
      INSERT OR IGNORE INTO surname_events (
        id, person_id, surname, surname_type, sort_order, is_primary,
        uuid, created_at, updated_at
      )
      SELECT
        p.id || '-married-surname', p.id, TRIM(p.married_surname),
        'marriage', 0, 0, p.id || '-married-surname',
        p.created_at, p.updated_at
      FROM persons p
      WHERE p.married_surname IS NOT NULL
        AND TRIM(p.married_surname) <> ''
        AND TRIM(p.married_surname) <> TRIM(COALESCE(p.birth_surname, ''))
    ''');
  }

  /// Copies `relationships` into `families_v2` / `family_children_v2`
  /// (schema < 10 databases).
  ///
  /// Fixes two defects of the previous implementation:
  ///  * legacy partner rows are stored as `'spouse'`, but only `'marriage'` was
  ///    accepted, so every marriage was silently dropped before the source table
  ///    was deleted. Both literals are accepted now;
  ///  * the single-parent lookup used `getSingleOrNull()` and threw as soon as a
  ///    parent had more than one family, aborting the upgrade halfway. The
  ///    resolution below is explicit and deterministic.
  Future<void> _absorbLegacyRelationships() async {
    if (!await _tableExists('relationships')) return;
    if (await _rowCount('families_v2') > 0) return;

    await _ensureDefaultTreeRow();

    final rows = await customSelect(
      'SELECT id, tree_id, person_id, related_person_id, relationship_type, '
      'created_at FROM relationships ORDER BY rowid',
    ).get();
    if (rows.isEmpty) return;

    final genderById = <String, String>{};
    for (final person in await customSelect(
      'SELECT id, gender FROM genealogy_persons',
    ).get()) {
      genderById[person.data['id'] as String] =
          (person.data['gender'] as String? ?? '').toLowerCase();
    }

    bool isFemale(String personId) =>
        genderById[personId] == 'female' || genderById[personId] == 'f';

    /// Fills the partner slots in a deterministic order so the same couple is
    /// never stored twice (the table has UNIQUE(husband_id, wife_id)).
    ({String husband, String wife}) slotsFor(String a, String b) {
      return isFemale(a)
          ? (husband: b, wife: a)
          : (husband: a, wife: b);
    }

    Future<void> insertFamily({
      required String id,
      required String husband,
      required String? wife,
      required int createdAt,
    }) async {
      await customStatement(
        'INSERT OR IGNORE INTO families_v2 '
        '(id, tree_id, husband_id, wife_id, relationship_type, '
        ' is_primary_marriage, uuid, is_deleted, created_at, updated_at) '
        "VALUES (?, ?, ?, ?, 'marriage', 0, ?, 0, ?, ?)",
        [id, AppConstants.defaultTreeId, husband, wife, 'family-uuid-$id',
          createdAt, createdAt],
      );
    }

    Future<String?> findFamily(String husband, String? wife) async {
      final result = wife == null
          ? await customSelect(
              'SELECT id FROM families_v2 WHERE (husband_id = ? AND wife_id IS NULL) '
              'OR (wife_id = ? AND husband_id IS NULL) '
              'ORDER BY created_at, id LIMIT 1',
              variables: [
                Variable<String>(husband),
                Variable<String>(husband),
              ],
            ).get()
          : await customSelect(
              'SELECT id FROM families_v2 WHERE husband_id = ? AND wife_id = ? '
              'LIMIT 1',
              variables: [Variable<String>(husband), Variable<String>(wife)],
            ).get();
      return result.isEmpty ? null : result.first.data['id'] as String;
    }

    Future<void> linkChild(String familyId, String childId, int createdAt) async {
      await customStatement(
        'INSERT OR IGNORE INTO family_children_v2 '
        '(id, family_id, child_id, relationship_type, is_deleted, '
        ' uuid, created_at, updated_at) '
        "VALUES (?, ?, ?, 'biological', 0, ?, ?, ?)",
        ['link-$familyId-$childId', familyId, childId,
          'link-uuid-$familyId-$childId', createdAt, createdAt],
      );
    }

    // 1. Partner rows (both historical literals).
    final spouseTypes = {'spouse', 'marriage'};
    for (final row in rows) {
      final type = row.data['relationship_type'] as String? ?? '';
      if (!spouseTypes.contains(type)) continue;
      final a = row.data['person_id'] as String;
      final b = row.data['related_person_id'] as String;
      if (a == b) continue;
      if (!genderById.containsKey(a) || !genderById.containsKey(b)) continue;
      final slots = slotsFor(a, b);
      await insertFamily(
        id: 'family-${row.data['id']}',
        husband: slots.husband,
        wife: slots.wife,
        createdAt: (row.data['created_at'] as int?) ?? 0,
      );
    }

    // 2. Parent-child rows, grouped by child in source order.
    final childToParents = <String, List<String>>{};
    for (final row in rows) {
      if ((row.data['relationship_type'] as String?) != 'parent_child') {
        continue;
      }
      final parent = row.data['person_id'] as String;
      final child = row.data['related_person_id'] as String;
      if (parent == child) continue;
      if (!genderById.containsKey(parent) ||
          !genderById.containsKey(child)) {
        continue;
      }
      childToParents.putIfAbsent(child, () => []).add(parent);
    }

    var sequence = 0;
    for (final entry in childToParents.entries) {
      final childId = entry.key;
      final parents = entry.value.toSet().toList();
      if (parents.isEmpty) continue;

      final String husband;
      final String? wife;
      if (parents.length == 1) {
        husband = parents.single;
        wife = null;
      } else {
        final slots = slotsFor(parents[0], parents[1]);
        husband = slots.husband;
        wife = slots.wife;
      }

      var familyId = await findFamily(husband, wife);
      familyId ??= 'family-imported-${sequence++}';
      if (await findFamily(husband, wife) == null) {
        await insertFamily(
          id: familyId,
          husband: husband,
          wife: wife,
          createdAt: 0,
        );
      }
      await linkChild(familyId, childId, 0);
    }
  }
}
