import 'package:drift/drift.dart';

import '../app_database.dart';

/// Read-side queries over the V2 family model.
///
/// Two rules hold for every method here:
///  * a soft-deleted person must never surface as a parent, child, sibling or
///    spouse;
///  * a query anchored on a soft-deleted person returns nothing at all — the
///    person is no longer part of the tree, so relationship questions about
///    them have no answer even though the family rows that name them survive
///    for the surviving partner and the children.
class RelationshipDao {
  RelationshipDao(this._database);

  final AppDatabase _database;

  /// Returns the live parents of [childId].
  Future<List<GenealogyPerson>> getParentPersonsOfChild(String childId) async {
    if (!await _personIsLive(childId)) return const [];

    final familyLinks = await (_database.select(_database.familyChildrenV2)
          ..where((t) => t.childId.equals(childId) & t.isDeleted.equals(false)))
        .get();
    final familyIds = familyLinks.map((e) => e.familyId).toList();
    if (familyIds.isEmpty) return const [];

    final families = await (_database.select(_database.familiesV2)
          ..where((t) => t.id.isIn(familyIds) & t.isDeleted.equals(false)))
        .get();

    return _livePeople(_partnerIdsOf(families));
  }

  /// Returns the live children of [parentId].
  Future<List<GenealogyPerson>> getChildPersonsOfParent(String parentId) async {
    if (!await _personIsLive(parentId)) return const [];

    final families = await _liveFamiliesOf(parentId);
    final familyIds = families.map((e) => e.id).toList();
    if (familyIds.isEmpty) return const [];

    final childLinks = await (_database.select(_database.familyChildrenV2)
          ..where(
            (t) => t.familyId.isIn(familyIds) & t.isDeleted.equals(false),
          ))
        .get();

    return _livePeople(childLinks.map((e) => e.childId).toSet());
  }

  /// Returns the live spouses of [personId].
  Future<List<GenealogyPerson>> getSpousePersonsOf(String personId) async {
    if (!await _personIsLive(personId)) return const [];

    final families = await _liveFamiliesOf(personId);
    final spouseIds = <String>{};
    for (final family in families) {
      if (family.husbandId == personId && family.wifeId != null) {
        spouseIds.add(family.wifeId!);
      }
      if (family.wifeId == personId && family.husbandId != null) {
        spouseIds.add(family.husbandId!);
      }
    }
    if (spouseIds.isEmpty) return const [];

    return _livePeople(spouseIds);
  }

  /// Returns the live siblings of [personId] (people who share a family).
  Future<List<GenealogyPerson>> getSiblingPersonsOf(String personId) async {
    if (!await _personIsLive(personId)) return const [];

    final myFamilyLinks = await (_database.select(_database.familyChildrenV2)
          ..where(
            (t) => t.childId.equals(personId) & t.isDeleted.equals(false),
          ))
        .get();
    final familyIds = myFamilyLinks.map((e) => e.familyId).toList();
    if (familyIds.isEmpty) return const [];

    final siblingLinks = await (_database.select(_database.familyChildrenV2)
          ..where(
            (t) =>
                t.familyId.isIn(familyIds) &
                t.childId.isNotValue(personId) &
                t.isDeleted.equals(false),
          ))
        .get();

    return _livePeople(siblingLinks.map((e) => e.childId).toSet());
  }

  /// Live parents of [childId], each paired with the link that connects them.
  Future<List<({GenealogyPerson person, String relationshipId})>>
      getParentPersonItemsOfChild(String childId) async {
    if (!await _personIsLive(childId)) return const [];

    final familyLinks = await (_database.select(_database.familyChildrenV2)
          ..where((t) => t.childId.equals(childId) & t.isDeleted.equals(false)))
        .get();
    final familyIds = familyLinks.map((e) => e.familyId).toList();
    if (familyIds.isEmpty) return const [];

    final families = await (_database.select(_database.familiesV2)
          ..where((t) => t.id.isIn(familyIds) & t.isDeleted.equals(false)))
        .get();

    final persons = await _livePeople(_partnerIdsOf(families));
    if (persons.isEmpty) return const [];

    // relationshipId = the family_children_v2 link that ties this parent to the
    // child, so callers can target the exact row they mean.
    return persons.map((person) {
      final familyIdsForPerson = families
          .where((f) => f.husbandId == person.id || f.wifeId == person.id)
          .map((f) => f.id)
          .toSet();
      final link = familyLinks.firstWhere(
        (l) => familyIdsForPerson.contains(l.familyId),
        orElse: () => familyLinks.first,
      );
      return (person: person, relationshipId: link.id);
    }).toList();
  }

  /// Live children of [parentId], each paired with their link.
  Future<List<({GenealogyPerson person, String relationshipId})>>
      getChildPersonItemsOfParent(String parentId) async {
    if (!await _personIsLive(parentId)) return const [];

    final families = await _liveFamiliesOf(parentId);
    final familyIds = families.map((e) => e.id).toList();
    if (familyIds.isEmpty) return const [];

    final childLinks = await (_database.select(_database.familyChildrenV2)
          ..where(
            (t) => t.familyId.isIn(familyIds) & t.isDeleted.equals(false),
          ))
        .get();
    if (childLinks.isEmpty) return const [];

    final persons = await _livePeople(childLinks.map((l) => l.childId).toSet());
    if (persons.isEmpty) return const [];

    // Prefer the link from the family that includes this parent, so removing a
    // child link never targets a link from another family.
    final familyById = {for (final f in families) f.id: f};
    return persons.map((person) {
      final candidates =
          childLinks.where((l) => l.childId == person.id).toList();
      final link = candidates.firstWhere(
        (l) =>
            familyById[l.familyId]?.husbandId == parentId ||
            familyById[l.familyId]?.wifeId == parentId,
        orElse: () => candidates.first,
      );
      return (person: person, relationshipId: link.id);
    }).toList();
  }

  /// Live spouses of [personId], each paired with the family that links them.
  Future<List<({GenealogyPerson person, String relationshipId})>>
      getSpousePersonItemsOf(String personId) async {
    if (!await _personIsLive(personId)) return const [];

    final families = await _liveFamiliesOf(personId);
    final spouseIds = <String>{};
    for (final family in families) {
      final spouseId =
          family.husbandId == personId ? family.wifeId : family.husbandId;
      if (spouseId != null) spouseIds.add(spouseId);
    }
    if (spouseIds.isEmpty) return const [];

    final spouses = {
      for (final person in await _livePeople(spouseIds)) person.id: person,
    };

    final result = <({GenealogyPerson person, String relationshipId})>[];
    for (final family in families) {
      final spouseId =
          family.husbandId == personId ? family.wifeId : family.husbandId;
      final spouse = spouseId == null ? null : spouses[spouseId];
      if (spouse != null) {
        result.add((person: spouse, relationshipId: family.id));
      }
    }
    return result;
  }

  /// Live families in which [personId] is a partner.
  Future<List<FamiliesV2Data>> _liveFamiliesOf(String personId) {
    return (_database.select(_database.familiesV2)
          ..where(
            (t) =>
                t.isDeleted.equals(false) &
                (t.husbandId.equals(personId) | t.wifeId.equals(personId)),
          ))
        .get();
  }

  Set<String> _partnerIdsOf(List<FamiliesV2Data> families) {
    final ids = <String>{};
    for (final family in families) {
      if (family.husbandId != null) ids.add(family.husbandId!);
      if (family.wifeId != null) ids.add(family.wifeId!);
    }
    return ids;
  }

  /// True when the person exists and is not soft-deleted.
  Future<bool> _personIsLive(String personId) async {
    final person = await (_database.select(_database.genealogyPersons)
          ..where((t) => t.id.equals(personId)))
        .getSingleOrNull();
    return person != null && !person.isDeleted;
  }

  /// Fetches the people in [ids] that are not soft-deleted.
  Future<List<GenealogyPerson>> _livePeople(Set<String> ids) {
    if (ids.isEmpty) return Future.value(const []);
    return (_database.select(_database.genealogyPersons)
          ..where((t) => t.id.isIn(ids.toList()) & t.isDeleted.equals(false)))
        .get();
  }
}
