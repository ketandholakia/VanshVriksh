import 'dart:async';
import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';

import '../../core/constants/relationship_types.dart';
import '../../core/utils/id_generator.dart';
import '../../features/people/person_relationship_models.dart';
import '../database/app_database.dart';
import '../database/daos/genealogy_person_dao.dart';
import '../database/daos/relationship_dao.dart';

class RelationshipRepository {
  RelationshipRepository(this._database);

  final AppDatabase _database;

  RelationshipDao get _relationshipDao => RelationshipDao(_database);
  GenealogyPersonDao get _personDao => _database.genealogyPersonDao;

  /// Creates a parent-child link via the V2 family model.
  ///
  /// When [parentId] already belongs to exactly one family, the child is
  /// attached to it; when the parent has no family, a single-parent family is
  /// created. A parent with **several** families is ambiguous, so the caller
  /// must name the family explicitly with [familyId] instead of the code
  /// picking one arbitrarily.
  Future<void> addParentChildRelationship({
    required String treeId,
    required String parentId,
    required String childId,
    String? familyId,
  }) async {
    if (parentId == childId) {
      throw ArgumentError('A person cannot be their own parent.');
    }

    await _database.transaction(() async {
      final parent = await _personDao.getPersonById(parentId);
      if (parent == null || parent.isDeleted) {
        throw ArgumentError('Parent person not found: $parentId');
      }
      final child = await _personDao.getPersonById(childId);
      if (child == null || child.isDeleted) {
        throw ArgumentError('Child person not found: $childId');
      }

      final targetFamilyId =
          familyId ?? await _familyForNewChild(treeId, parent);

      final existing =
          await _personDao.getFamilyChildLink(targetFamilyId, childId);
      if (existing != null) {
        if (existing.isDeleted) {
          // Re-adding a previously removed link restores it rather than
          // violating UNIQUE(family_id, child_id).
          await _personDao.restoreFamilyChild(
            existing.id,
            DateTime.now(),
          );
        }
        return;
      }

      await _personDao.createFamilyChild(
        FamilyChildrenV2Companion.insert(
          id: IdGenerator.newId(),
          familyId: targetFamilyId,
          childId: childId,
          relationshipType: const Value('biological'),
          uuid: IdGenerator.newId(),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  /// Resolves which family a new child of [parent] belongs to.
  Future<String> _familyForNewChild(
    String treeId,
    GenealogyPerson parent,
  ) async {
    final families = await _personDao.getFamiliesForPerson(parent.id);
    if (families.isEmpty) {
      return _createSingleParentFamily(treeId, parent);
    }
    if (families.length == 1) {
      return families.single.id;
    }
    throw StateError(
      '${parent.firstName} belongs to ${families.length} families, so the '
      'child cannot be attached unambiguously. Pass familyId explicitly.',
    );
  }

  /// Creates a spouse/partnership family between two people. No-op when the
  /// pair is already linked. Husband/wife slots are filled gender-aware so the
  /// tree renderers can distinguish the partners; same-sex pairs still occupy
  /// both slots.
  Future<void> addSpouseRelationship({
    required String treeId,
    required String personAId,
    required String personBId,
  }) async {
    if (personAId == personBId) {
      throw ArgumentError('A person cannot be their own spouse.');
    }

    await _database.transaction(() async {
      final a = await _personDao.getPersonById(personAId);
      final b = await _personDao.getPersonById(personBId);
      if (a == null || a.isDeleted || b == null || b.isDeleted) {
        throw ArgumentError(
          'Both people must exist to create a spouse relationship.',
        );
      }

      final aFamilies = await _personDao.getFamiliesForPerson(personAId);
      for (final family in aFamilies) {
        if (family.husbandId == personBId || family.wifeId == personBId) {
          return; // already partners
        }
      }

      final isAFemale = _isFemale(a.gender);
      final isBFemale = _isFemale(b.gender);
      final String husbandId;
      final String wifeId;
      if (isAFemale == isBFemale) {
        // Same sex (or both unknown): keep both partners in slots for
        // rendering.
        husbandId = a.id;
        wifeId = b.id;
      } else if (isAFemale) {
        husbandId = b.id;
        wifeId = a.id;
      } else {
        husbandId = a.id;
        wifeId = b.id;
      }

      final now = DateTime.now();
      await _personDao.createFamily(
        FamiliesV2Companion.insert(
          id: IdGenerator.newId(),
          husbandId: Value(husbandId),
          wifeId: Value(wifeId),
          isPrimaryMarriage: const Value(false),
          uuid: IdGenerator.newId(),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    });
  }

  /// Removes a parent/child link (soft delete).
  ///
  /// Returns 1 when a live link was removed, 0 when the link does not exist or
  /// has already been removed.
  Future<int> removeParentChildLink(String linkId) async {
    final link = await (_database.select(_database.familyChildrenV2)
          ..where((t) => t.id.equals(linkId)))
        .getSingleOrNull();
    if (link == null || link.isDeleted) return 0;
    return _personDao.markFamilyChildDeleted(linkId, DateTime.now());
  }

  /// Dissolves a spousal/partnership family (soft delete) in one transaction.
  ///
  /// Child links keep the family alive, so the caller has to state what happens
  /// to the children:
  ///  * [removeChildLinks] false (default) — refuse while the family still has
  ///    live child links, so parentage is never deleted by accident;
  ///  * [removeChildLinks] true — soft-delete the child links first, then the
  ///    family.
  ///
  /// Returns 1 when the family was dissolved, 0 when it was already gone.
  Future<int> dissolveFamily(
    String familyId, {
    bool removeChildLinks = false,
  }) async {
    return _database.transaction(() async {
      final family = await _personDao.getFamilyById(familyId);
      if (family == null) {
        throw ArgumentError('Family not found: $familyId');
      }
      if (family.isDeleted) return 0;

      final links = await _personDao.getChildrenForFamily(familyId);
      if (links.isNotEmpty && !removeChildLinks) {
        throw StateError(
          'Family $familyId still has ${links.length} child link(s). Pass '
          'removeChildLinks: true to dissolve it and remove them too.',
        );
      }

      final now = DateTime.now();
      for (final link in links) {
        await _personDao.markFamilyChildDeleted(link.id, now);
      }
      return _personDao.markFamilyDeleted(familyId, now);
    });
  }

  Future<String> _createSingleParentFamily(
    String treeId,
    GenealogyPerson parent,
  ) async {
    final id = IdGenerator.newId();
    final now = DateTime.now();
    final isFemale = _isFemale(parent.gender);
    await _personDao.createFamily(
      FamiliesV2Companion.insert(
        id: id,
        husbandId: Value(isFemale ? null : parent.id),
        wifeId: Value(isFemale ? parent.id : null),
        isPrimaryMarriage: const Value(false),
        uuid: IdGenerator.newId(),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    return id;
  }

  static bool _isFemale(String gender) {
    final g = gender.trim().toUpperCase();
    return g == 'F' || g == 'FEMALE';
  }

  // Instead of Stream<List<Relationship>>, we return a generic Stream that ticks when families change
  Stream<void> watchRelationshipsForPerson(String personId) {
    return _personDao.watchFamiliesForPerson(personId);
  }

  /// Streams all spouse + parent-child relationships in a tree as legacy
  /// [Relationship] objects, derived from the V2 families_v2/family_children_v2
  /// tables (the legacy `relationships` table was dropped in schema v10).
  Stream<List<Relationship>> watchRelationshipsByTree(String treeId) {
    final peopleQuery = (_database.select(_database.genealogyPersons)
          ..where((t) => t.treeId.equals(treeId) & t.isDeleted.equals(false)));
    final familiesQuery = (_database.select(_database.familiesV2)
          ..where((t) => t.isDeleted.equals(false)));
    final linksQuery = (_database.select(_database.familyChildrenV2)
          ..where((t) => t.isDeleted.equals(false)));

    return Rx.combineLatest3<
        List<GenealogyPerson>,
        List<FamiliesV2Data>,
        List<FamilyChildrenV2Data>,
        List<Relationship>>(
      peopleQuery.watch(),
      familiesQuery.watch(),
      linksQuery.watch(),
      (people, families, links) => _buildRelationships(
        treeId,
        _familiesInTree(people, families),
        links,
      ),
    );
  }

  Future<List<Relationship>> getRelationshipsByTree(String treeId) async {
    final people = await _personDao.getPeopleByTree(treeId);
    final families = await (_database.select(_database.familiesV2)
          ..where((t) => t.isDeleted.equals(false)))
        .get();
    final links = await (_database.select(_database.familyChildrenV2)
          ..where((t) => t.isDeleted.equals(false)))
        .get();

    return _buildRelationships(
      treeId,
      _familiesInTree(people, families),
      links,
    );
  }

  Future<List<Relationship>> getRelationshipsForPerson(
    String personId,
  ) async {
    final families = await _personDao.getFamiliesForPerson(personId);
    final links = await (_database.select(_database.familyChildrenV2)
          ..where((t) => t.isDeleted.equals(false)))
        .get();

    return _buildRelationships('', families, links);
  }

  List<FamiliesV2Data> _familiesInTree(
    List<GenealogyPerson> people,
    List<FamiliesV2Data> families,
  ) {
    final ids = {for (final person in people) person.id};
    return families
        .where(
          (f) =>
              (f.husbandId != null && ids.contains(f.husbandId)) ||
              (f.wifeId != null && ids.contains(f.wifeId)),
        )
        .toList();
  }

  /// Flattens the V2 family model into legacy [Relationship] edges:
  /// one `spouse` edge per couple and one `parent_child` edge per parent-child
  /// link, so consumers (dashboard stats, integrity checker) can stay on the
  /// legacy model without the dropped `relationships` table.
  List<Relationship> _buildRelationships(
    String treeId,
    List<FamiliesV2Data> families,
    List<FamilyChildrenV2Data> links,
  ) {
    final relationships = <Relationship>[];
    final linksByFamily = <String, List<FamilyChildrenV2Data>>{};
    for (final link in links) {
      linksByFamily.putIfAbsent(link.familyId, () => []).add(link);
    }

    for (final family in families) {
      if (family.husbandId != null && family.wifeId != null) {
        relationships.add(
          Relationship(
            id: family.id,
            treeId: treeId,
            personId: family.husbandId!,
            relatedPersonId: family.wifeId!,
            relationshipType: 'spouse',
            createdAt: family.createdAt,
          ),
        );
      }

      final parentIds = [
        if (family.husbandId != null) family.husbandId!,
        if (family.wifeId != null) family.wifeId!,
      ];
      for (final link in linksByFamily[family.id] ?? const <FamilyChildrenV2Data>[]) {
        for (final parentId in parentIds) {
          relationships.add(
            Relationship(
              id: link.id,
              treeId: treeId,
              personId: parentId,
              relatedPersonId: link.childId,
              relationshipType: 'parent_child',
              createdAt: link.createdAt,
            ),
          );
        }
      }
    }
    return relationships;
  }

  Future<List<GenealogyPerson>> getParents(String childId) {
    return _relationshipDao.getParentPersonsOfChild(childId);
  }

  Future<List<GenealogyPerson>> getChildren(String parentId) {
    return _relationshipDao.getChildPersonsOfParent(parentId);
  }

  Future<List<GenealogyPerson>> getSpouses(String personId) {
    return _relationshipDao.getSpousePersonsOf(personId);
  }

  Future<List<GenealogyPerson>> getSiblings(String personId) {
    return _relationshipDao.getSiblingPersonsOf(personId);
  }

  Future<List<PersonRelationItem>> getParentItems(String childId) async {
    final items = await _relationshipDao.getParentPersonItemsOfChild(childId);
    return items
        .map(
          (item) => PersonRelationItem(
            person: item.person,
            groupType: PersonRelationGroupType.parents,
            relationshipId: item.relationshipId,
          ),
        )
        .toList();
  }

  Future<List<PersonRelationItem>> getChildItems(String parentId) async {
    final items = await _relationshipDao.getChildPersonItemsOfParent(parentId);
    return items
        .map(
          (item) => PersonRelationItem(
            person: item.person,
            groupType: PersonRelationGroupType.children,
            relationshipId: item.relationshipId,
          ),
        )
        .toList();
  }

  Future<List<PersonRelationItem>> getSpouseItems(String personId) async {
    final items = await _relationshipDao.getSpousePersonItemsOf(personId);
    return items
        .map(
          (item) => PersonRelationItem(
            person: item.person,
            groupType: PersonRelationGroupType.spouses,
            relationshipId: item.relationshipId,
          ),
        )
        .toList();
  }

  Future<List<PersonRelationItem>> getSiblingItems(String personId) async {
    final siblings = await _relationshipDao.getSiblingPersonsOf(personId);
    return siblings
        .map(
          (person) => PersonRelationItem(
            person: person,
            groupType: PersonRelationGroupType.siblings,
            relationshipId: '',
          ),
        )
        .toList();
  }
}
