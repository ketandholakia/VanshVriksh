import 'dart:async';
import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';

import '../../core/utils/id_generator.dart';
import '../../features/people/person_relationship_models.dart';
import '../database/app_database.dart';
import '../database/daos/genealogy_person_dao.dart';
import '../database/daos/relationship_dao.dart';
import '../models/family_graph.dart';
import '../models/relationship_edges.dart';

class RelationshipRepository {
  RelationshipRepository(this._database);

  final AppDatabase _database;

  RelationshipDao get _relationshipDao => RelationshipDao(_database);
  GenealogyPersonDao get _personDao => _database.genealogyPersonDao;

  /// Records [parentId] as a parent of [childId].
  ///
  /// Domain rules:
  ///  * a person cannot be their own parent;
  ///  * both people must exist and be live (not deleted);
  ///  * a child cannot be linked twice into the same family (the existing row is
  ///    restored instead of duplicated — `UNIQUE(family_id, child_id)`);
  ///  * a child cannot acquire the same parent through a second family.
  ///
  /// When [parentId] already belongs to exactly one family the child joins it;
  /// with no family a single-parent family is created. A parent with **several**
  /// families is ambiguous, so the caller must name the family with [familyId]
  /// instead of the repository picking one.
  ///
  /// [relationshipType] records how the parentage works — `biological`
  /// (default), `adopted`, `foster`, `step`. The model and this API support
  /// them; the app has no screen for choosing one yet.
  Future<void> addParentChildRelationship({
    required String treeId,
    required String parentId,
    required String childId,
    String? familyId,
    String relationshipType = 'biological',
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

      final targetFamilyId = familyId ?? await _familyForNewChild(treeId, parent);
      final targetFamily = await _personDao.getFamilyById(targetFamilyId);
      if (targetFamily == null || targetFamily.isDeleted) {
        throw ArgumentError('Family not found: $targetFamilyId');
      }
      if (targetFamily.treeId != treeId) {
        throw ArgumentError(
          'Family $targetFamilyId belongs to tree ${targetFamily.treeId}, '
          'not to $treeId.',
        );
      }

      final existing =
          await _personDao.getFamilyChildLink(targetFamilyId, childId);
      if (existing != null) {
        if (existing.isDeleted) {
          await _personDao.restoreFamilyChild(existing.id, DateTime.now());
        }
        return;
      }

      await _assertParentNotAlreadyLinked(
        childId: childId,
        targetFamily: targetFamily,
      );

      final now = DateTime.now();
      await _personDao.createFamilyChild(
        FamilyChildrenV2Companion.insert(
          id: IdGenerator.newId(),
          familyId: targetFamilyId,
          childId: childId,
          relationshipType: Value(relationshipType),
          uuid: IdGenerator.newId(),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    });
  }

  /// Refuses a parentage that already exists through a different family, so the
  /// same parent cannot appear twice for one child.
  Future<void> _assertParentNotAlreadyLinked({
    required String childId,
    required FamiliesV2Data targetFamily,
  }) async {
    final targetPartnerIds = [
      if (targetFamily.husbandId != null) targetFamily.husbandId!,
      if (targetFamily.wifeId != null) targetFamily.wifeId!,
    ];
    if (targetPartnerIds.isEmpty) return;

    final links = await (_database.select(_database.familyChildrenV2)
          ..where(
            (t) => t.childId.equals(childId) & t.isDeleted.equals(false),
          ))
        .get();

    for (final link in links) {
      if (link.familyId == targetFamily.id) continue;
      final otherFamily = await _personDao.getFamilyById(link.familyId);
      if (otherFamily == null || otherFamily.isDeleted) continue;
      for (final partnerId in [otherFamily.husbandId, otherFamily.wifeId]) {
        if (partnerId != null && targetPartnerIds.contains(partnerId)) {
          throw StateError(
            'Person $partnerId is already a parent of $childId through family '
            '${otherFamily.id}. The same parent cannot be recorded twice for one '
            'child.',
          );
        }
      }
    }
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

  /// Records a partnership between two people.
  ///
  /// Domain rules:
  ///  * a person cannot be their own partner;
  ///  * both people must exist and be live;
  ///  * the pair is stored **canonically** — when the two records have different
  ///    genders the one recorded as female takes the `wife` slot (the tree views
  ///    label the slots), and otherwise the pair is ordered by id. That makes the
  ///    stored pair independent of argument order, so
  ///    `UNIQUE(husband_id, wife_id)` really does prevent the same couple twice;
  ///  * re-adding an existing partnership is a no-op;
  ///  * a further partnership for someone who already has one is allowed:
  ///    remarriage and multiple families are part of the domain.
  ///
  /// Gender is used only to choose a display slot. Same-sex couples and people
  /// with an unknown gender are supported; nothing here requires a male and a
  /// female partner.
  Future<void> addSpouseRelationship({
    required String treeId,
    required String personAId,
    required String personBId,
    bool isPrimary = false,
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
      if (a.treeId != treeId || b.treeId != treeId) {
        throw ArgumentError(
          'Both people must belong to tree $treeId.',
        );
      }

      if (await _familyForPair(personAId, personBId) != null) {
        return; // already partners
      }

      final slots = canonicalPartnerSlots(
        firstId: a.id,
        firstGender: a.gender,
        secondId: b.id,
        secondGender: b.gender,
      );

      final now = DateTime.now();
      await _personDao.createFamily(
        FamiliesV2Companion.insert(
          id: IdGenerator.newId(),
          treeId: treeId,
          husbandId: Value(slots.husbandId),
          wifeId: Value(slots.wifeId),
          isPrimaryMarriage: Value(isPrimary),
          uuid: IdGenerator.newId(),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    });
  }

  // The partner-slot rule lives in `lib/data/models/relationship_edges.dart`
  // (`canonicalPartnerSlots`), so this repository and the migration share one
  // definition instead of two copies that can drift apart.

  /// Ends a partnership. Idempotent: returns 1 when a partnership was ended,
  /// 0 when the two people are not partners.
  ///
  /// The partnership and the child relationships of the same family share one
  /// row, so children have to be accounted for:
  ///  * [removeChildRelationships] false (default) — refuse while the couple
  ///    still has child relationships, so parentage is never deleted by
  ///    accident;
  ///  * true — remove those child relationships first, then the partnership.
  ///
  /// The people themselves are never touched.
  Future<int> removeSpouseRelationship({
    required String treeId,
    required String personAId,
    required String personBId,
    bool removeChildRelationships = false,
  }) async {
    if (personAId == personBId) {
      throw ArgumentError('A person has no spouse relationship with themselves.');
    }

    return _database.transaction(() async {
      final family = await _familyForPair(personAId, personBId);
      if (family == null) return 0;

      final children = await _personDao.getChildrenForFamily(family.id);
      if (children.isNotEmpty && !removeChildRelationships) {
        throw StateError(
          'This partnership still records ${children.length} child '
          'relationship(s). Pass removeChildRelationships: true to remove '
          'those as well.',
        );
      }
      return _dissolveFamily(
        family.id,
        removeChildLinks: removeChildRelationships,
      );
    });
  }

  /// Removes [parentId] as a parent of [childId]. Idempotent: returns the number
  /// of links removed (0 when they are not related).
  ///
  /// A child is linked to a *family*, so when the parent has a partner in that
  /// family the removal would drop the partner's parentage too. That is refused
  /// unless [removeCoParent] is true, which acknowledges it explicitly.
  ///
  /// Neither the child, the parent nor the family is deleted.
  Future<int> removeParentChildRelationship({
    required String treeId,
    required String parentId,
    required String childId,
    bool removeCoParent = false,
  }) async {
    if (parentId == childId) {
      throw ArgumentError('A person has no parent relationship with themselves.');
    }

    return _database.transaction(() async {
      final families = await _personDao.getFamiliesForPerson(parentId);
      final matched = <({FamiliesV2Data family, FamilyChildrenV2Data link})>[];
      for (final family in families) {
        final link = await _personDao.getFamilyChildLink(family.id, childId);
        if (link != null && !link.isDeleted) {
          matched.add((family: family, link: link));
        }
      }
      if (matched.isEmpty) return 0;

      final now = DateTime.now();
      var removed = 0;
      for (final entry in matched) {
        final coParentId = entry.family.husbandId == parentId
            ? entry.family.wifeId
            : entry.family.husbandId;
        if (coParentId != null && !removeCoParent) {
          throw StateError(
            '$childId is recorded as a child of $parentId and $coParentId in '
            'the same family, so removing this relationship would also drop '
            '$coParentId as a parent. Pass removeCoParent: true to do that, or '
            'end the partnership instead.',
          );
        }
        removed += await _personDao.markFamilyChildDeleted(entry.link.id, now);
      }
      return removed;
    });
  }

  /// Live partnerships of [personId], as rows rather than projections.
  Future<List<FamiliesV2Data>> getFamiliesForPerson(String personId) {
    return _personDao.getFamiliesForPerson(personId);
  }

  /// The live partnership family of the pair, or null when they are not
  /// partners.
  Future<FamiliesV2Data?> _familyForPair(
    String personAId,
    String personBId,
  ) async {
    for (final family in await _personDao.getFamiliesForPerson(personAId)) {
      if (family.husbandId == personBId || family.wifeId == personBId) {
        return family;
      }
    }
    return null;
  }

  /// Soft-deletes a partnership family. Private: callers use
  /// [removeSpouseRelationship], which resolves the family from the people.
  Future<int> _dissolveFamily(
    String familyId, {
    required bool removeChildLinks,
  }) async {
    final family = await _personDao.getFamilyById(familyId);
    if (family == null) return 0;
    if (family.isDeleted) return 0;

    final now = DateTime.now();
    final links = await _personDao.getChildrenForFamily(familyId);
    if (links.isNotEmpty) {
      if (!removeChildLinks) {
        throw StateError(
          'Family $familyId still has ${links.length} child link(s).',
        );
      }
      for (final link in links) {
        await _personDao.markFamilyChildDeleted(link.id, now);
      }
    }
    return _personDao.markFamilyDeleted(familyId, now);
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
        treeId: treeId,
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

  /// Loads one tree's whole family structure in **three** queries.
  ///
  /// The tree and fan-chart views traverse the family graph repeatedly; asking
  /// the database for parents/spouses/children once per node turns a single
  /// rebuild into hundreds of queries. This returns the graph those views walk.
  Future<FamilyGraph> loadFamilyGraph(String treeId) async {
    final people = await (_database.select(_database.genealogyPersons)
          ..where(
            (t) => t.treeId.equals(treeId) & t.isDeleted.equals(false),
          ))
        .get();
    final families = await (_database.select(_database.familiesV2)
          ..where(
            (t) => t.treeId.equals(treeId) & t.isDeleted.equals(false),
          ))
        .get();

    final familyIds = families.map((family) => family.id).toList();
    final childLinks = familyIds.isEmpty
        ? const <FamilyChildrenV2Data>[]
        : await (_database.select(_database.familyChildrenV2)
              ..where(
                (t) =>
                    t.familyId.isIn(familyIds) &
                    t.isDeleted.equals(false),
              ))
            .get();

    return FamilyGraph(
      people: {for (final person in people) person.id: person},
      families: families,
      childLinks: childLinks,
    );
  }

  /// Ticks whenever the families of [personId] change. Typed as the rows it
  /// actually carries, not as `void`.
  Stream<List<FamiliesV2Data>> watchRelationshipsForPerson(String personId) {
    return _personDao.watchFamiliesForPerson(personId);
  }

  /// Streams the partnership rows of [treeId] (one per `families_v2` row).
  ///
  /// Only partnerships of live people are exposed: a family whose partners are
  /// all deleted belongs to nobody left in the tree.
  Stream<List<Partnership>> watchPartnerships(String treeId) {
    final familiesQuery = (_database.select(_database.familiesV2)
          ..where(
            (t) => t.treeId.equals(treeId) & t.isDeleted.equals(false),
          ));
    final peopleQuery = (_database.select(_database.genealogyPersons)
          ..where(
            (t) => t.treeId.equals(treeId) & t.isDeleted.equals(false),
          ));

    return Rx.combineLatest2<
        List<FamiliesV2Data>,
        List<GenealogyPerson>,
        List<Partnership>>(
      familiesQuery.watch(),
      peopleQuery.watch(),
      (families, people) =>
          _toPartnerships(families, {for (final p in people) p.id}),
    );
  }

  /// Streams the parent→child edges of [treeId].
  ///
  /// One edge per recorded parent, so a child with two parents yields two edges
  /// that share a [ParentChildRelationship.linkId]. Edges touching a deleted
  /// person are omitted.
  Stream<List<ParentChildRelationship>> watchParentChildRelationships(
    String treeId,
  ) {
    final familiesQuery = (_database.select(_database.familiesV2)
          ..where(
            (t) => t.treeId.equals(treeId) & t.isDeleted.equals(false),
          ));
    // Only this tree's links are read: the previous version watched the whole
    // child-link table and filtered in Dart, so any change anywhere rebuilt the
    // tree from a full table scan.
    final linksQuery = (_database.select(_database.familyChildrenV2).join([
      innerJoin(
        _database.familiesV2,
        _database.familiesV2.id.equalsExp(_database.familyChildrenV2.familyId),
      ),
    ])
          ..where(
            _database.familiesV2.treeId.equals(treeId) &
                _database.familyChildrenV2.isDeleted.equals(false),
          ))
        .map((row) => row.readTable(_database.familyChildrenV2));
    final peopleQuery = (_database.select(_database.genealogyPersons)
          ..where(
            (t) => t.treeId.equals(treeId) & t.isDeleted.equals(false),
          ));

    return Rx.combineLatest3<
        List<FamiliesV2Data>,
        List<FamilyChildrenV2Data>,
        List<GenealogyPerson>,
        List<ParentChildRelationship>>(
      familiesQuery.watch(),
      linksQuery.watch(),
      peopleQuery.watch(),
      (families, links, people) => _toParentChildRelationships(
        (families: families, links: links),
        {for (final person in people) person.id},
      ),
    );
  }

  Future<List<Partnership>> getPartnerships(String treeId) async {
    final families = await (_database.select(_database.familiesV2)
          ..where(
            (t) => t.treeId.equals(treeId) & t.isDeleted.equals(false),
          ))
        .get();
    if (families.isEmpty) return const [];
    return _toPartnerships(families, await _livePersonIdsInTree(treeId));
  }

  Future<List<ParentChildRelationship>> getParentChildRelationships(
    String treeId,
  ) async {
    final families = await (_database.select(_database.familiesV2)
          ..where(
            (t) => t.treeId.equals(treeId) & t.isDeleted.equals(false),
          ))
        .get();
    if (families.isEmpty) return const [];

    final links = await (_database.select(_database.familyChildrenV2)
          ..where(
            (t) =>
                t.familyId.isIn(families.map((f) => f.id).toList()) &
                t.isDeleted.equals(false),
          ))
        .get();
    return _toParentChildRelationships(
      (families: families, links: links),
      await _livePersonIdsInTree(treeId),
    );
  }

  Future<Set<String>> _livePersonIdsInTree(String treeId) async {
    final people = await (_database.select(_database.genealogyPersons)
          ..where(
            (t) => t.treeId.equals(treeId) & t.isDeleted.equals(false),
          ))
        .get();
    return {for (final person in people) person.id};
  }

  static List<Partnership> _toPartnerships(
    List<FamiliesV2Data> families,
    Set<String> livePersonIds,
  ) {
    final partnerships = <Partnership>[];
    for (final family in families) {
      final husbandId = family.husbandId;
      final wifeId = family.wifeId;
      final liveHusband =
          husbandId != null && livePersonIds.contains(husbandId)
              ? husbandId
              : null;
      final liveWife =
          wifeId != null && livePersonIds.contains(wifeId) ? wifeId : null;
      // A family with no live partner belongs to nobody left in the tree.
      if (liveHusband == null && liveWife == null) continue;

      partnerships.add(
        Partnership(
          familyId: family.id,
          treeId: family.treeId,
          husbandId: liveHusband,
          wifeId: liveWife,
          marriageDate: family.marriageDate,
          isPrimary: family.isPrimaryMarriage,
        ),
      );
    }
    return partnerships;
  }

  /// Expands child links into one edge per recorded parent, skipping anyone who
  /// is no longer in the tree.
  static List<ParentChildRelationship> _toParentChildRelationships(
    ({List<FamiliesV2Data> families, List<FamilyChildrenV2Data> links})
        snapshot,
    Set<String> livePersonIds,
  ) {
    final parentIdsByFamily = <String, List<String>>{};
    for (final family in snapshot.families) {
      parentIdsByFamily[family.id] = [
        if (family.husbandId != null) family.husbandId!,
        if (family.wifeId != null) family.wifeId!,
      ].where(livePersonIds.contains).toList();
    }

    final edges = <ParentChildRelationship>[];
    for (final link in snapshot.links) {
      final parentIds = parentIdsByFamily[link.familyId];
      if (parentIds == null) continue; // family belongs to another tree
      if (!livePersonIds.contains(link.childId)) continue;
      for (final parentId in parentIds) {
        edges.add(
          ParentChildRelationship(
            linkId: link.id,
            familyId: link.familyId,
            parentId: parentId,
            childId: link.childId,
            relationshipType: link.relationshipType,
            birthOrder: link.birthOrder,
          ),
        );
      }
    }
    return edges;
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
