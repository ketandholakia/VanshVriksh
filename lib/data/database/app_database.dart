import 'package:drift/drift.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/relationship_types.dart';
import '../models/relationship_edges.dart';
import 'tables/duplicate_markers_table.dart';
import 'tables/events_table.dart';
import 'tables/families_v2_table.dart';
import 'tables/family_children_v2_table.dart';
import 'tables/family_trees_table.dart';
import 'tables/genealogy_persons_table.dart';
import 'tables/media_items_table.dart';
import 'tables/research_notes_table.dart';
import 'tables/surname_events_table.dart';
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
    ResearchNotes,
  ],
  daos: [GenealogyPersonDao, EventsDao, ResearchNotesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 14;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // One consolidated path. Every pre-v12 database — including the very
      // old ones that still carry the legacy `persons` / `relationships`
      // tables — is upgraded by the same deterministic routine, so there is
      // exactly one migration to reason about and to test.
      //
      // See scratch/audit/migration-strategy.md: schema v12 is the canonical
      // baseline; earlier versions are supported as import paths only.
      await _upgradeToCanonicalSchema(m);
    },
    beforeOpen: (details) async {
      // Enable foreign keys on EVERY connection, not just first create.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  // ---------------------------------------------------------------------------
  // Migration to the canonical schema (v13)
  // ---------------------------------------------------------------------------

  /// Brings **any** pre-v12 database to the canonical model, atomically.
  ///
  /// Steps:
  ///  1. create any canonical table the incoming database lacks, so a very old
  ///     database does not have to replay years of incremental steps;
  ///  2. make sure the legacy `persons` columns the import reads exist;
  ///  3. import the legacy `persons` / `relationships` tables (if present);
  ///  4. ensure the ownership root exists and repair states the new constraints
  ///     would reject;
  ///  5. rebuild every canonical table (this is what drops obsolete columns,
  ///     applies the foreign keys and re-creates the schema-declared indexes);
  ///  6. drop the legacy tables;
  ///  7. verify that nothing the import claimed to preserve was lost.
  ///
  /// Drift already runs `onUpgrade` inside a transaction (an explicit `BEGIN`
  /// here fails with "cannot start a transaction within a transaction"), so the
  /// routine is atomic: a verification failure throws, drift rolls the
  /// transaction back, and the database keeps its previous version and contents
  /// instead of ending up half-migrated.
  Future<void> _upgradeToCanonicalSchema(Migrator m) async {
    await _ensureCanonicalTablesExist(m);
    await _ensureLegacyColumns();
    final importedPeople = await _absorbLegacyPersons();
    final importedLinks = await _absorbLegacyRelationships();
    await _ensureDefaultTreeRow();
    await _repairPreExistingData();
    await _rebuildCanonicalTables(m);
    await customStatement('DROP TABLE IF EXISTS persons');
    await customStatement('DROP TABLE IF EXISTS relationships');
    await customStatement('DROP TABLE IF EXISTS sync_change_log');
    // Tables that earlier versions carried but that no code ever used.
    await customStatement('DROP TABLE IF EXISTS citations');
    await customStatement('DROP TABLE IF EXISTS citation_links');
    await customStatement('DROP TABLE IF EXISTS todos');
    await _verifyUpgrade(
      importedPeople: importedPeople,
      importedLinks: importedLinks,
    );
  }

  /// Creates any canonical table the incoming database does not have yet.
  Future<void> _ensureCanonicalTablesExist(Migrator m) async {
    Future<void> ensure(String name, Future<void> Function() create) async {
      if (await _tableExists(name)) return;
      await create();
    }

    await ensure('family_trees', () => m.createTable(familyTrees));
    await ensure('genealogy_persons', () => m.createTable(genealogyPersons));
    await ensure('surname_events', () => m.createTable(surnameEvents));
    await ensure('families_v2', () => m.createTable(familiesV2));
    await ensure('family_children_v2', () => m.createTable(familyChildrenV2));
    await ensure('media_items', () => m.createTable(mediaItems));
    await ensure('events', () => m.createTable(events));
    await ensure('duplicate_markers', () => m.createTable(duplicateMarkers));
    await ensure('research_notes', () => m.createTable(researchNotes));
  }

  /// Rebuilds every canonical table so the physical schema matches the model:
  /// obsolete columns go, foreign keys and delete actions arrive, and the
  /// indexes declared on the tables are re-created.
  Future<void> _rebuildCanonicalTables(Migrator m) async {
    await m.alterTable(TableMigration(familyTrees));
    await m.alterTable(TableMigration(genealogyPersons));
    await m.alterTable(
      TableMigration(
        familiesV2,
        // `tree_id` is mandatory in the canonical model and every pre-v12 row
        // belongs to the application's single tree. If that tree were missing
        // the foreign key would make the copy fail loudly rather than invent an
        // owner.
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
  }

  /// Older `persons` tables lack columns that later versions added. They are
  /// added before the import reads them, so the same query works from any
  /// version instead of failing on an ancient database.
  Future<void> _ensureLegacyColumns() async {
    if (!await _tableExists('persons')) return;
    final columns = await _columnsOf('persons');
    if (!columns.contains('birth_surname')) {
      await customStatement(
        'ALTER TABLE persons ADD COLUMN birth_surname TEXT',
      );
    }
    if (!columns.contains('married_surname')) {
      await customStatement(
        'ALTER TABLE persons ADD COLUMN married_surname TEXT',
      );
    }
  }

  /// Proves that the import preserved what it claims to have preserved.
  ///
  /// A failure throws, which rolls the whole upgrade back — a database that
  /// cannot be migrated correctly is left untouched rather than silently
  /// missing relationships.
  Future<void> _verifyUpgrade({
    required int importedPeople,
    required ImportedRelationships importedLinks,
  }) async {
    final failures = <String>[];

    if (importedPeople > 0) {
      final migrated = await _rowCount('genealogy_persons');
      if (migrated < importedPeople) {
        failures.add(
          'imported $importedPeople legacy people but only $migrated exist',
        );
      }
    }

    for (final pair in importedLinks.parentChildPairs) {
      final linked = await customSelect(
        'SELECT 1 FROM family_children_v2 l '
        'JOIN families_v2 f ON f.id = l.family_id '
        'WHERE l.child_id = ? AND l.is_deleted = 0 AND f.is_deleted = 0 '
        'AND (f.husband_id = ? OR f.wife_id = ?) LIMIT 1',
        variables: [
          Variable<String>(pair.childId),
          Variable<String>(pair.parentId),
          Variable<String>(pair.parentId),
        ],
      ).get();
      if (linked.isEmpty) {
        failures.add(
          'legacy parentage ${pair.parentId} -> ${pair.childId} has no link',
        );
      }
    }

    if (importedLinks.spouseRows > 0 && await _rowCount('families_v2') == 0) {
      failures.add(
        'imported ${importedLinks.spouseRows} legacy partner rows but no '
        'partnership exists',
      );
    }

    if (failures.isNotEmpty) {
      throw StateError(
        'Migration verification failed, the upgrade was rolled back:\n'
        '${failures.join('\n')}',
      );
    }
  }

  Future<Set<String>> _columnsOf(String table) async {
    final rows = await customSelect('PRAGMA table_info($table)').get();
    return rows.map((row) => row.data['name'] as String).toSet();
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
      );
      await customStatement(
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
    final row = await customSelect(
      'SELECT COUNT(*) AS c FROM $table',
    ).getSingle();
    return row.data['c'] as int? ?? 0;
  }

  /// Copies `persons` into `genealogy_persons` (schema < 8 databases).
  /// Copies `persons` into `genealogy_persons` (schema < 8 databases) and returns
  /// how many people were copied.
  Future<int> _absorbLegacyPersons() async {
    if (!await _tableExists('persons')) return 0;
    final legacyCount = await _rowCount('persons');
    if (legacyCount == 0) return 0;
    if (await _rowCount('genealogy_persons') > 0) return 0;

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
        created_at, updated_at
      )
      SELECT
        p.id || '-birth-surname', p.id,
        TRIM(COALESCE(p.birth_surname, p.last_name)), 'birth', 0, 1,
        p.created_at, p.updated_at
      FROM persons p
      WHERE TRIM(COALESCE(p.birth_surname, p.last_name, '')) <> ''
    ''');
    await customStatement('''
      INSERT OR IGNORE INTO surname_events (
        id, person_id, surname, surname_type, sort_order, is_primary,
        created_at, updated_at
      )
      SELECT
        p.id || '-married-surname', p.id, TRIM(p.married_surname),
        'marriage', 0, 0,
        p.created_at, p.updated_at
      FROM persons p
      WHERE p.married_surname IS NOT NULL
        AND TRIM(p.married_surname) <> ''
        AND TRIM(p.married_surname) <> TRIM(COALESCE(p.birth_surname, ''))
    ''');

    return legacyCount;
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
  ///
  ///  * a child with more than two recorded parents keeps **all** of them: the
  ///    first two share a family and every further parent gets their own
  ///    single-parent family, whose `notes` records why. Nothing is dropped and
  ///    no record is chosen arbitrarily;
  ///  * every parentage that was migrated is returned so the caller can verify
  ///    it survived.
  Future<ImportedRelationships> _absorbLegacyRelationships() async {
    const nothingImported = (
      parentChildPairs: <({String parentId, String childId})>[],
      spouseRows: 0,
      unresolvedRows: 0,
    );

    if (!await _tableExists('relationships')) return nothingImported;
    if (await _rowCount('families_v2') > 0) return nothingImported;

    await _ensureDefaultTreeRow();

    final rows = await customSelect(
      'SELECT id, tree_id, person_id, related_person_id, relationship_type, '
      'created_at FROM relationships ORDER BY rowid',
    ).get();
    if (rows.isEmpty) return nothingImported;

    final genderById = <String, String>{};
    for (final person in await customSelect(
      'SELECT id, gender FROM genealogy_persons',
    ).get()) {
      genderById[person.data['id'] as String] =
          (person.data['gender'] as String? ?? '').toLowerCase();
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
        ' is_primary_marriage, is_deleted, created_at, updated_at) '
        "VALUES (?, ?, ?, ?, 'marriage', 0, 0, ?, ?)",
        [id, AppConstants.defaultTreeId, husband, wife, createdAt, createdAt],
      );
    }

    Future<String?> findFamily(String husband, String? wife) async {
      final result = wife == null
          ? await customSelect(
              'SELECT id FROM families_v2 WHERE (husband_id = ? AND wife_id IS NULL) '
              'OR (wife_id = ? AND husband_id IS NULL) '
              'ORDER BY created_at, id LIMIT 1',
              variables: [Variable<String>(husband), Variable<String>(husband)],
            ).get()
          : await customSelect(
              'SELECT id FROM families_v2 WHERE husband_id = ? AND wife_id = ? '
              'LIMIT 1',
              variables: [Variable<String>(husband), Variable<String>(wife)],
            ).get();
      return result.isEmpty ? null : result.first.data['id'] as String;
    }

    Future<void> linkChild(
      String familyId,
      String childId,
      int createdAt,
    ) async {
      await customStatement(
        'INSERT OR IGNORE INTO family_children_v2 '
        '(id, family_id, child_id, relationship_type, is_deleted, '
        ' created_at, updated_at) '
        "VALUES (?, ?, ?, 'biological', 0, ?, ?)",
        ['link-$familyId-$childId', familyId, childId, createdAt, createdAt],
      );
    }

    var sequence = 0;

    /// A single-parent family for [parentId], in the slot their recorded gender
    /// implies.
    Future<String> insertSingleParentFamily(String parentId) async {
      final familyId = 'family-imported-${sequence++}';
      final isFemale = isFemaleGender(genderById[parentId] ?? '');
      await customStatement(
        'INSERT OR IGNORE INTO families_v2 '
        '(id, tree_id, husband_id, wife_id, relationship_type, '
        ' is_primary_marriage, is_deleted, created_at, updated_at) '
        "VALUES (?, ?, ?, ?, 'marriage', 0, 0, 0, 0)",
        [
          familyId,
          AppConstants.defaultTreeId,
          isFemale ? null : parentId,
          isFemale ? parentId : null,
        ],
      );
      return familyId;
    }

    /// Records, in the row itself, that a legacy child had more parents than a
    /// family can hold. The extra parentage is preserved rather than dropped.
    Future<void> markAdditionalParentFamily(
      String familyId,
      String childId,
      int recordedParents,
    ) async {
      await customStatement('UPDATE families_v2 SET notes = ? WHERE id = ?', [
        'Imported from legacy data: $childId was recorded with '
            '$recordedParents parents, but a family holds two. This family '
            'keeps one of the additional parents so no parentage is lost.',
        familyId,
      ]);
    }

    var spouseRows = 0;
    var unresolvedRows = 0;
    final parentChildPairs = <({String parentId, String childId})>[];

    // 1. Partner rows. Every confirmed partner value is accepted.
    for (final row in rows) {
      final type = row.data['relationship_type'] as String? ?? '';
      if (!RelationshipTypes.partnerTypes.contains(type)) continue;
      final a = row.data['person_id'] as String;
      final b = row.data['related_person_id'] as String;
      if (a == b) continue;
      if (!genderById.containsKey(a) || !genderById.containsKey(b)) {
        unresolvedRows++;
        continue;
      }
      spouseRows++;
      // The partner slots are decided by the shared canonical rule, so the
      // migration and the repository order couples identically.
      final slots = canonicalPartnerSlots(
        firstId: a,
        firstGender: genderById[a] ?? '',
        secondId: b,
        secondGender: genderById[b] ?? '',
      );
      await insertFamily(
        id: 'family-${row.data['id']}',
        husband: slots.husbandId,
        wife: slots.wifeId,
        createdAt: (row.data['created_at'] as int?) ?? 0,
      );
    }

    // 2. Parent-child rows, grouped by child in source order.
    final childToParents = <String, List<String>>{};
    for (final row in rows) {
      final type = row.data['relationship_type'] as String? ?? '';
      if (!RelationshipTypes.parentChildTypes.contains(type)) {
        if (!RelationshipTypes.partnerTypes.contains(type)) unresolvedRows++;
        continue;
      }
      final parent = row.data['person_id'] as String;
      final child = row.data['related_person_id'] as String;
      if (parent == child) {
        unresolvedRows++;
        continue;
      }
      if (!genderById.containsKey(parent) || !genderById.containsKey(child)) {
        unresolvedRows++;
        continue;
      }
      childToParents.putIfAbsent(child, () => []).add(parent);
    }

    for (final entry in childToParents.entries) {
      final childId = entry.key;
      final parents = entry.value.toSet().toList();
      if (parents.isEmpty) continue;

      final primary = parents.take(2).toList();
      final additional = parents.skip(2).toList();

      final String husband;
      final String? wife;
      if (primary.length == 1) {
        husband = primary.single;
        wife = null;
      } else {
        final slots = canonicalPartnerSlots(
          firstId: primary[0],
          firstGender: genderById[primary[0]] ?? '',
          secondId: primary[1],
          secondGender: genderById[primary[1]] ?? '',
        );
        husband = slots.husbandId;
        wife = slots.wifeId;
      }

      var familyId = await findFamily(husband, wife);
      if (familyId == null) {
        familyId = 'family-imported-${sequence++}';
        await insertFamily(
          id: familyId,
          husband: husband,
          wife: wife,
          createdAt: 0,
        );
      }
      await linkChild(familyId, childId, 0);
      for (final parentId in primary) {
        parentChildPairs.add((parentId: parentId, childId: childId));
      }

      for (final extraParentId in additional) {
        final extraFamilyId = await insertSingleParentFamily(extraParentId);
        await markAdditionalParentFamily(
          extraFamilyId,
          childId,
          parents.length,
        );
        await linkChild(extraFamilyId, childId, 0);
        parentChildPairs.add((parentId: extraParentId, childId: childId));
      }
    }

    return (
      parentChildPairs: parentChildPairs,
      spouseRows: spouseRows,
      unresolvedRows: unresolvedRows,
    );
  }
}

/// What a legacy import produced, so the upgrade can verify it afterwards.
typedef ImportedRelationships = ({
  List<({String parentId, String childId})> parentChildPairs,
  int spouseRows,
  int unresolvedRows,
});
