import 'package:drift/drift.dart';

import '../../../core/constants/relationship_types.dart';
import '../app_database.dart';

class RelationshipDao {
  RelationshipDao(this._database);

  final AppDatabase _database;

  // We can leave delete/add out or implement them directly in GenealogyRepository.
  // Actually, let's keep the read methods so that RelationshipRepository continues to work.

  /// Returns the parent Person rows for a child.
  Future<List<GenealogyPerson>> getParentPersonsOfChild(String childId) async {
    // 1. Find all families where this child belongs
    final familyLinks = await (_database.select(_database.familyChildrenV2)
          ..where((t) => t.childId.equals(childId)))
        .get();
        
    final familyIds = familyLinks.map((e) => e.familyId).toList();
    if (familyIds.isEmpty) return [];

    // 2. Get families
    final families = await (_database.select(_database.familiesV2)
          ..where((t) => t.id.isIn(familyIds)))
        .get();

    final parentIds = <String>{};
    for (final f in families) {
      if (f.husbandId != null) parentIds.add(f.husbandId!);
      if (f.wifeId != null) parentIds.add(f.wifeId!);
    }
    if (parentIds.isEmpty) return [];

    return (_database.select(_database.genealogyPersons)
          ..where((t) => t.id.isIn(parentIds)))
        .get();
  }

  Future<List<GenealogyPerson>> getChildPersonsOfParent(String parentId) async {
    final families = await (_database.select(_database.familiesV2)
          ..where((t) => t.husbandId.equals(parentId) | t.wifeId.equals(parentId)))
        .get();
    
    final familyIds = families.map((e) => e.id).toList();
    if (familyIds.isEmpty) return [];

    final childLinks = await (_database.select(_database.familyChildrenV2)
          ..where((t) => t.familyId.isIn(familyIds)))
        .get();
    
    final childIds = childLinks.map((e) => e.childId).toList();
    if (childIds.isEmpty) return [];

    return (_database.select(_database.genealogyPersons)
          ..where((t) => t.id.isIn(childIds)))
        .get();
  }

  Future<List<GenealogyPerson>> getSpousePersonsOf(String personId) async {
    final families = await (_database.select(_database.familiesV2)
          ..where((t) => t.husbandId.equals(personId) | t.wifeId.equals(personId)))
        .get();
    
    final spouseIds = <String>{};
    for (final f in families) {
      if (f.husbandId == personId && f.wifeId != null) spouseIds.add(f.wifeId!);
      if (f.wifeId == personId && f.husbandId != null) spouseIds.add(f.husbandId!);
    }
    if (spouseIds.isEmpty) return [];

    return (_database.select(_database.genealogyPersons)
          ..where((t) => t.id.isIn(spouseIds)))
        .get();
  }

  Future<List<GenealogyPerson>> getSiblingPersonsOf(String personId) async {
    // Siblings share a family
    final myFamilyLinks = await (_database.select(_database.familyChildrenV2)
          ..where((t) => t.childId.equals(personId)))
        .get();
    final familyIds = myFamilyLinks.map((e) => e.familyId).toList();
    if (familyIds.isEmpty) return [];

    final siblingLinks = await (_database.select(_database.familyChildrenV2)
          ..where((t) => t.familyId.isIn(familyIds) & t.childId.isNotValue(personId)))
        .get();
    
    final siblingIds = siblingLinks.map((e) => e.childId).toSet().toList();
    if (siblingIds.isEmpty) return [];

    return (_database.select(_database.genealogyPersons)
          ..where((t) => t.id.isIn(siblingIds)))
        .get();
  }

  Future<List<({GenealogyPerson person, String relationshipId})>>
      getParentPersonItemsOfChild(String childId) async {
    final familyLinks = await (_database.select(_database.familyChildrenV2)
          ..where((t) => t.childId.equals(childId)))
        .get();
    final familyIds = familyLinks.map((e) => e.familyId).toList();
    if (familyIds.isEmpty) return [];
    
    final families = await (_database.select(_database.familiesV2)
          ..where((t) => t.id.isIn(familyIds)))
        .get();
    
    final parentIds = <String>{};
    for (final f in families) {
      if (f.husbandId != null) parentIds.add(f.husbandId!);
      if (f.wifeId != null) parentIds.add(f.wifeId!);
    }
    if (parentIds.isEmpty) return [];

    final persons = await (_database.select(_database.genealogyPersons)
          ..where((t) => t.id.isIn(parentIds)))
        .get();

    // relationshipId = family_children_v2 link id that ties this parent to the
    // child. Pick the link of the family this parent actually belongs to so
    // deleteRelationship targets the correct row.
    return persons.map((p) {
      final familyIdsForPerson = families
          .where((f) => f.husbandId == p.id || f.wifeId == p.id)
          .map((f) => f.id)
          .toSet();
      final link = familyLinks.firstWhere(
        (l) => familyIdsForPerson.contains(l.familyId),
        orElse: () => familyLinks.first,
      );
      return (person: p, relationshipId: link.id);
    }).toList();
  }

  Future<List<({GenealogyPerson person, String relationshipId})>>
      getChildPersonItemsOfParent(String parentId) async {
    final families = await (_database.select(_database.familiesV2)
          ..where((t) => t.husbandId.equals(parentId) | t.wifeId.equals(parentId)))
        .get();
    final familyIds = families.map((e) => e.id).toList();
    if (familyIds.isEmpty) return [];
    
    final childLinks = await (_database.select(_database.familyChildrenV2)
          ..where((t) => t.familyId.isIn(familyIds)))
        .get();
    final childIds = childLinks.map((e) => e.childId).toList();
    if (childIds.isEmpty) return [];
    
    final persons = await (_database.select(_database.genealogyPersons)
          ..where((t) => t.id.isIn(childIds)))
        .get();

    // Prefer the link from the family that includes this parent, so deleting a
    // child link does not accidentally remove a link from another family.
    final familyById = {for (final f in families) f.id: f};
    return persons.map((p) {
      final link = childLinks.firstWhere(
        (l) =>
            l.childId == p.id &&
            (familyById[l.familyId]?.husbandId == parentId ||
                familyById[l.familyId]?.wifeId == parentId),
        orElse: () => childLinks.firstWhere((l) => l.childId == p.id),
      );
      return (person: p, relationshipId: link.id);
    }).toList();
  }

  Future<List<({GenealogyPerson person, String relationshipId})>>
      getSpousePersonItemsOf(String personId) async {
    final families = await (_database.select(_database.familiesV2)
          ..where((t) => t.husbandId.equals(personId) | t.wifeId.equals(personId)))
        .get();
    
    final result = <({GenealogyPerson person, String relationshipId})>[];
    for (final f in families) {
      final spouseId = f.husbandId == personId ? f.wifeId : f.husbandId;
      if (spouseId != null) {
        final spouse = await (_database.select(_database.genealogyPersons)..where((t) => t.id.equals(spouseId))).getSingleOrNull();
        if (spouse != null) {
          result.add((person: spouse, relationshipId: f.id));
        }
      }
    }
    return result;
  }
}
