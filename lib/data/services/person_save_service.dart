import '../database/app_database.dart';
import '../models/person_save_data.dart';
import '../repositories/genealogy_repository.dart';
import '../repositories/relationship_repository.dart';

/// Application-level person-save commands.
///
/// Each method is one logical user operation — person creation together with
/// the relationship/family/child-link writes the user asked for — executed
/// inside exactly ONE [AppDatabase.transaction]. Success commits everything;
/// any failure rolls everything back, so there is never a half-saved person.
///
/// The service never calls the repositories' public transactional methods from
/// inside its transaction. Person writes go through
/// [GenealogyRepository.createPersonFromSave] (a single statement that joins
/// the ambient transaction) and relationship writes through the
/// `...InTransaction` primitives of [RelationshipRepository]. The public
/// repository methods keep their own standalone transactions for genuinely
/// independent operations.
///
/// Filesystem work (profile photos) is deliberately NOT part of these
/// transactions: the UI runs the database operation first, then handles the
/// photo with safe ordering (never delete the old file before the database
/// update succeeds).
class PersonSaveService {
  PersonSaveService(this._database);

  final AppDatabase _database;

  GenealogyRepository get _people => GenealogyRepository(_database);
  RelationshipRepository get _relationships =>
      RelationshipRepository(_database);

  /// Creates a person and records them as a parent of [childId], atomically.
  ///
  /// If the parent link fails (unknown/deleted child, ambiguous family,
  /// duplicate parentage, ...) the new person does not remain.
  Future<String> createPersonAsParent({
    required String treeId,
    required PersonSaveData person,
    required String childId,
    String relationshipType = 'biological',
  }) {
    return _database.transaction(() async {
      final newId = await _people.createPersonFromSave(person, treeId);
      await _relationships.addParentChildRelationshipInTransaction(
        treeId: treeId,
        parentId: newId,
        childId: childId,
        relationshipType: relationshipType,
      );
      return newId;
    });
  }

  /// Creates a person as a child of [parentId] plus every requested co-parent,
  /// atomically.
  ///
  /// Co-parents come from [coParentIds], with the live spouses of [parentId]
  /// additionally included when [includeParentSpouses] is true. Every link
  /// uses strict fail-fast semantics: a failure in any co-parent link rolls
  /// back the person, the first link, and any family created by this
  /// operation. The only accepted no-ops are the ones already idempotent in
  /// the relationship rules (same-family re-link, existing partnership).
  Future<String> createPersonAsChild({
    required String treeId,
    required PersonSaveData person,
    required String parentId,
    List<String> coParentIds = const [],
    bool includeParentSpouses = false,
    String? familyId,
    String relationshipType = 'biological',
  }) {
    return _database.transaction(() async {
      final newId = await _people.createPersonFromSave(person, treeId);
      await _relationships.addParentChildRelationshipInTransaction(
        treeId: treeId,
        parentId: parentId,
        childId: newId,
        familyId: familyId,
        relationshipType: relationshipType,
      );
      await _linkCoParentsInTransaction(
        treeId: treeId,
        childId: newId,
        primaryParentId: parentId,
        coParentIds: coParentIds,
        includeParentSpouses: includeParentSpouses,
        relationshipType: relationshipType,
      );
      return newId;
    });
  }

  /// Creates a person and records them as the spouse of [partnerId],
  /// atomically.
  ///
  /// If the partnership fails (unknown/deleted/cross-tree partner, ...) the
  /// new person does not remain.
  Future<String> createPersonAsSpouse({
    required String treeId,
    required PersonSaveData person,
    required String partnerId,
    bool isPrimary = false,
  }) {
    return _database.transaction(() async {
      final newId = await _people.createPersonFromSave(person, treeId);
      await _relationships.addSpouseRelationshipInTransaction(
        treeId: treeId,
        personAId: partnerId,
        personBId: newId,
        isPrimary: isPrimary,
      );
      return newId;
    });
  }

  /// Creates a person as a sibling via the given [parentIds], atomically.
  ///
  /// An empty parent list fails BEFORE anything is written: a "sibling" with
  /// no established parentage would be a misleading partial save. A failure in
  /// any parent link rolls back the person and every earlier link.
  Future<String> createPersonAsSibling({
    required String treeId,
    required PersonSaveData person,
    required List<String> parentIds,
    String relationshipType = 'biological',
  }) {
    final uniqueParents = parentIds.toSet().toList();
    if (uniqueParents.isEmpty) {
      throw ArgumentError(
        'Cannot create a sibling without at least one parent link: the '
        'sibling relationship could not be established.',
      );
    }
    return _database.transaction(() async {
      final newId = await _people.createPersonFromSave(person, treeId);
      for (final parentId in uniqueParents) {
        await _relationships.addParentChildRelationshipInTransaction(
          treeId: treeId,
          parentId: parentId,
          childId: newId,
          relationshipType: relationshipType,
        );
      }
      return newId;
    });
  }

  /// Links an existing child to [parentId] plus every requested co-parent, in
  /// one transaction.
  ///
  /// Replaces the old UI pattern of N independent `addParentChildRelationship`
  /// calls: if any co-parent link fails, the first link rolls back too, so
  /// there is never asymmetric partial parentage. Re-linking an already
  /// recorded parentage stays a no-op per the relationship rules.
  Future<void> addExistingChildWithCoParents({
    required String treeId,
    required String parentId,
    required String childId,
    List<String> coParentIds = const [],
    bool includeParentSpouses = false,
    String? familyId,
    String relationshipType = 'biological',
  }) {
    return _database.transaction(() async {
      await _relationships.addParentChildRelationshipInTransaction(
        treeId: treeId,
        parentId: parentId,
        childId: childId,
        familyId: familyId,
        relationshipType: relationshipType,
      );
      await _linkCoParentsInTransaction(
        treeId: treeId,
        childId: childId,
        primaryParentId: parentId,
        coParentIds: coParentIds,
        includeParentSpouses: includeParentSpouses,
        relationshipType: relationshipType,
      );
    });
  }

  /// Links each co-parent of [childId] strictly: any failure propagates and
  /// rolls back the enclosing transaction. Exact-duplicate ids (the primary
  /// parent repeated, or the same co-parent twice) are input redundancy, not
  /// domain outcomes, so they are de-duplicated before linking.
  Future<void> _linkCoParentsInTransaction({
    required String treeId,
    required String childId,
    required String primaryParentId,
    required List<String> coParentIds,
    required bool includeParentSpouses,
    required String relationshipType,
  }) async {
    final ordered = <String>[];
    void addIfNew(String id) {
      if (id != primaryParentId && !ordered.contains(id)) ordered.add(id);
    }

    for (final id in coParentIds) {
      addIfNew(id);
    }
    if (includeParentSpouses) {
      for (final spouse in await _relationships.getSpouses(primaryParentId)) {
        addIfNew(spouse.id);
      }
    }
    for (final coParentId in ordered) {
      await _relationships.addParentChildRelationshipInTransaction(
        treeId: treeId,
        parentId: coParentId,
        childId: childId,
        relationshipType: relationshipType,
      );
    }
  }
}
