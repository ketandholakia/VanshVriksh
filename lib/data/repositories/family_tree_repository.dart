import 'package:drift/drift.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/id_generator.dart';
import '../database/app_database.dart';
import '../database/daos/family_tree_dao.dart';

/// Everything a tree owns, counted.
typedef TreePurgePreview = ({
  int people,
  int families,
  int childLinks,
  int events,
  int mediaItems,
  int researchNotes,
  int surnameEvents,
  int duplicateMarkers,
});

/// What a purge removed, plus the files it left behind on disk.
typedef TreePurgeResult = ({int people, List<String> orphanedFilePaths});

class FamilyTreeRepository {
  FamilyTreeRepository(this._database);

  final AppDatabase _database;
  FamilyTreeDao get _familyTreeDao => FamilyTreeDao(_database);

  Future<void> ensureDefaultTree() {
    return _familyTreeDao.ensureDefaultFamilyTree(
      treeId: AppConstants.defaultTreeId,
      treeName: 'My Family',
    );
  }

  Future<void> addFamilyTree({required String treeName, String? description}) {
    final now = DateTime.now();
    return _familyTreeDao.createFamilyTree(
      FamilyTreesCompanion.insert(
        id: IdGenerator.newId(),
        treeName: treeName.trim(),
        description: Value(description?.trim()),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<bool> updateFamilyTree({
    required String id,
    required String treeName,
    String? description,
    String? rootPersonId,
    required DateTime createdAt,
  }) {
    final now = DateTime.now();
    return _familyTreeDao.updateFamilyTree(
      FamilyTreesCompanion(
        id: Value(id),
        treeName: Value(treeName.trim()),
        description: Value(description?.trim()),
        rootPersonId: Value(rootPersonId),
        createdAt: Value(createdAt),
        updatedAt: Value(now),
      ),
    );
  }

  Future<FamilyTree?> getFamilyTreeById(String treeId) {
    return _familyTreeDao.getFamilyTreeById(treeId);
  }

  Stream<List<FamilyTree>> watchAllFamilyTrees() {
    return _familyTreeDao.watchAllFamilyTrees();
  }

  Future<List<FamilyTree>> getAllFamilyTrees() {
    return _familyTreeDao.getAllFamilyTrees();
  }

  // ---------------------------------------------------------------------------
  // Deletion
  // ---------------------------------------------------------------------------

  /// Deletes an **empty** tree.
  ///
  /// Refuses while the tree still owns people or families, naming what is in the
  /// way. A populated tree is destroyed only through [previewTreePurge] +
  /// [purgeTree], so no delete can silently orphan a lineage.
  Future<int> deleteFamilyTree(String treeId) async {
    final preview = await previewTreePurge(treeId);
    if (preview.people > 0 || preview.families > 0) {
      throw StateError(
        'Tree $treeId is not empty: ${preview.people} people, '
        '${preview.families} families, ${preview.childLinks} child links, '
        '${preview.events} events, ${preview.mediaItems} media items. '
        'Use purgeTree() to delete it deliberately.',
      );
    }
    return _familyTreeDao.deleteFamilyTree(treeId);
  }

  /// Counts everything [purgeTree] would destroy.
  Future<TreePurgePreview> previewTreePurge(String treeId) async {
    final personIds = await _personIdsInTree(treeId);
    final familyIds = await _familyIdsInTree(treeId);

    return (
      people: personIds.length,
      families: familyIds.length,
      childLinks: await _count(
        (personIds) =>
            _database.select(_database.familyChildrenV2)
              ..where((t) => t.familyId.isIn(familyIds)),
      )(familyIds),
      events: await _count(
        (personIds) =>
            _database.select(_database.events)
              ..where((t) => t.personId.isIn(personIds)),
      )(personIds),
      mediaItems: await _count(
        (personIds) =>
            _database.select(_database.mediaItems)
              ..where((t) => t.personId.isIn(personIds)),
      )(personIds),
      researchNotes: await _count(
        (personIds) =>
            _database.select(_database.researchNotes)
              ..where((t) => t.personId.isIn(personIds)),
      )(personIds),
      surnameEvents: await _count(
        (personIds) =>
            _database.select(_database.surnameEvents)
              ..where((t) => t.personId.isIn(personIds)),
      )(personIds),
      duplicateMarkers: await _count(
        (personIds) => _database.select(_database.duplicateMarkers)
          ..where(
            (t) => t.personAId.isIn(personIds) | t.personBId.isIn(personIds),
          ),
      )(personIds),
    );
  }

  /// Hard-deletes [treeId] and every record it owns, in one transaction.
  ///
  /// Deleting a tree is the one place where records are destroyed rather than
  /// flagged, so the operation is explicit and complete: people (including the
  /// soft-deleted ones), families, child links, events, media rows, research
  /// notes, surname events and duplicate markers.
  ///
  /// Media and profile-photo **files** are not deleted - they are returned in
  /// [TreePurgeResult.orphanedFilePaths] so the storage layer can remove them.
  Future<TreePurgeResult> purgeTree(String treeId) async {
    final tree = await getFamilyTreeById(treeId);
    if (tree == null) {
      throw ArgumentError('Family tree not found: $treeId');
    }

    return _database.transaction(() async {
      final personIds = await _personIdsInTree(treeId);
      final familyIds = await _familyIdsInTree(treeId);

      final people = personIds.isEmpty
          ? const <GenealogyPerson>[]
          : await (_database.select(
              _database.genealogyPersons,
            )..where((t) => t.id.isIn(personIds))).get();
      final mediaItems = personIds.isEmpty
          ? const <MediaItem>[]
          : await (_database.select(
              _database.mediaItems,
            )..where((t) => t.personId.isIn(personIds))).get();

      final orphanedFiles = <String>[
        for (final person in people)
          if ((person.profilePhotoPath ?? '').trim().isNotEmpty)
            person.profilePhotoPath!.trim(),
        for (final item in mediaItems) item.filePath,
      ];

      if (personIds.isNotEmpty) {
        await (_database.delete(_database.duplicateMarkers)..where(
              (t) => t.personAId.isIn(personIds) | t.personBId.isIn(personIds),
            ))
            .go();

        // Detach the purged people from families and child links outside this
        // tree, so a RESTRICT constraint can never leave a half-applied purge.
        await (_database.update(_database.familiesV2)..where(
              (t) =>
                  t.treeId.equals(treeId).not() & t.husbandId.isIn(personIds),
            ))
            .write(const FamiliesV2Companion(husbandId: Value(null)));
        await (_database.update(_database.familiesV2)..where(
              (t) => t.treeId.equals(treeId).not() & t.wifeId.isIn(personIds),
            ))
            .write(const FamiliesV2Companion(wifeId: Value(null)));

        await (_database.delete(
          _database.familyChildrenV2,
        )..where((t) => t.childId.isIn(personIds))).go();
      }

      if (familyIds.isNotEmpty) {
        await (_database.delete(
          _database.familyChildrenV2,
        )..where((t) => t.familyId.isIn(familyIds))).go();
      }

      await (_database.delete(
        _database.familiesV2,
      )..where((t) => t.treeId.equals(treeId))).go();

      if (personIds.isNotEmpty) {
        await (_database.delete(
          _database.events,
        )..where((t) => t.personId.isIn(personIds))).go();
        await (_database.delete(
          _database.mediaItems,
        )..where((t) => t.personId.isIn(personIds))).go();
        await (_database.delete(
          _database.researchNotes,
        )..where((t) => t.personId.isIn(personIds))).go();
        await (_database.delete(
          _database.surnameEvents,
        )..where((t) => t.personId.isIn(personIds))).go();
      }

      await (_database.delete(
        _database.genealogyPersons,
      )..where((t) => t.treeId.equals(treeId))).go();

      await _familyTreeDao.deleteFamilyTree(treeId);

      return (people: people.length, orphanedFilePaths: orphanedFiles);
    });
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<List<String>> _personIdsInTree(String treeId) async {
    final rows = await (_database.select(
      _database.genealogyPersons,
    )..where((t) => t.treeId.equals(treeId))).get();
    return rows.map((person) => person.id).toList();
  }

  Future<List<String>> _familyIdsInTree(String treeId) async {
    final rows = await (_database.select(
      _database.familiesV2,
    )..where((t) => t.treeId.equals(treeId))).get();
    return rows.map((family) => family.id).toList();
  }

  /// Counts the rows selected by [build], or 0 when [ids] is empty (an empty
  /// `IN ()` is not valid SQL).
  Future<int> Function(List<String> ids) _count(
    Selectable<dynamic> Function(List<String> ids) build,
  ) {
    return (ids) async {
      if (ids.isEmpty) return 0;
      return (await build(ids).get()).length;
    };
  }
}
