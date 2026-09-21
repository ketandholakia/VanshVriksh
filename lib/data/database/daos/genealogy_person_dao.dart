import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/families_v2_table.dart';
import '../tables/family_children_v2_table.dart';
import '../tables/genealogy_persons_table.dart';
import '../tables/surname_events_table.dart';

part 'genealogy_person_dao.g.dart';

/// CRUD and query primitives for the V2 person / family tables.
///
/// Deliberately primitive: this DAO must not carry business rules or
/// multi-step operations. Callers use [GenealogyRepository] /
/// [RelationshipRepository], which own transactions and invariants.
///
/// Write methods are **keyed partial updates** (`write()`). Do not reintroduce
/// `update(...).replace(companion)`: drift validates `replace()` as an INSERT,
/// so an incomplete companion throws, and every column the caller omits is
/// rewritten to its schema default.
@DriftAccessor(
  tables: [GenealogyPersons, SurnameEvents, FamiliesV2, FamilyChildrenV2],
)
class GenealogyPersonDao extends DatabaseAccessor<AppDatabase>
    with _$GenealogyPersonDaoMixin {
  GenealogyPersonDao(super.db);

  // ---------------------------------------------------------------------------
  // Persons
  // ---------------------------------------------------------------------------

  Future<void> createPerson(GenealogyPersonsCompanion person) {
    return into(genealogyPersons).insert(person);
  }

  /// Applies [changes] to the person with [id]. Absent companion fields are
  /// left untouched; explicitly `Value(null)` fields are cleared.
  Future<int> updatePersonFields(
    String id,
    GenealogyPersonsCompanion changes,
  ) {
    return (update(genealogyPersons)..where((tbl) => tbl.id.equals(id)))
        .write(changes);
  }

  Future<int> markPersonDeleted(String id, DateTime at) {
    return (update(genealogyPersons)..where((tbl) => tbl.id.equals(id))).write(
      GenealogyPersonsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(at),
      ),
    );
  }

  Future<int> restorePerson(String id, DateTime at) {
    return (update(genealogyPersons)..where((tbl) => tbl.id.equals(id))).write(
      GenealogyPersonsCompanion(
        isDeleted: const Value(false),
        mergedIntoId: const Value(null),
        updatedAt: Value(at),
      ),
    );
  }

  /// Reads a person regardless of soft-delete state.
  Future<GenealogyPerson?> getPersonById(String id) {
    return (select(genealogyPersons)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Stream<GenealogyPerson?> watchPersonById(String id) {
    return (select(genealogyPersons)..where((tbl) => tbl.id.equals(id)))
        .watchSingleOrNull();
  }

  /// People in [treeId] that are not soft-deleted.
  Stream<List<GenealogyPerson>> watchPeopleByTree(String treeId) {
    return (select(genealogyPersons)
          ..where(
            (tbl) => tbl.treeId.equals(treeId) & tbl.isDeleted.equals(false),
          )
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.firstName)]))
        .watch();
  }

  /// People in [treeId] that are not soft-deleted.
  Future<List<GenealogyPerson>> getPeopleByTree(String treeId) {
    return (select(genealogyPersons)
          ..where(
            (tbl) => tbl.treeId.equals(treeId) & tbl.isDeleted.equals(false),
          )
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.firstName)]))
        .get();
  }

  /// People referenced by [ids] that are not soft-deleted.
  Future<List<GenealogyPerson>> getLivePeopleByIds(Iterable<String> ids) {
    final unique = ids.toSet().toList();
    if (unique.isEmpty) return Future.value(const []);
    return (select(genealogyPersons)
          ..where((tbl) => tbl.id.isIn(unique) & tbl.isDeleted.equals(false)))
        .get();
  }

  Future<List<GenealogyPerson>> searchPeople({
    required String treeId,
    required String query,
  }) {
    final searchText = '%${query.trim()}%';
    return (select(genealogyPersons)
          ..where(
            (tbl) =>
                tbl.treeId.equals(treeId) &
                tbl.isDeleted.equals(false) &
                (tbl.firstName.like(searchText) |
                    tbl.middleName.like(searchText) |
                    tbl.lastName.like(searchText) |
                    tbl.birthSurname.like(searchText) |
                    tbl.marriedSurname.like(searchText) |
                    tbl.nickname.like(searchText) |
                    tbl.birthPlace.like(searchText) |
                    tbl.currentPlace.like(searchText) |
                    tbl.customDisplayName.like(searchText)),
          ))
        .get();
  }

  Stream<List<SurnameEvent>> watchSurnameHistory(String personId) {
    return (select(surnameEvents)
          ..where((tbl) => tbl.personId.equals(personId))
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.sortOrder),
            (tbl) => OrderingTerm.asc(tbl.createdAt),
          ]))
        .watch();
  }

  // ---------------------------------------------------------------------------
  // Families
  // ---------------------------------------------------------------------------

  Future<void> createFamily(FamiliesV2Companion family) {
    return into(familiesV2).insert(family);
  }

  /// Applies [changes] to the family with [id]. Keyed partial update.
  Future<int> updateFamilyFields(String id, FamiliesV2Companion changes) {
    return (update(familiesV2)..where((tbl) => tbl.id.equals(id))).write(changes);
  }

  Future<int> markFamilyDeleted(String id, DateTime at) {
    return (update(familiesV2)..where((tbl) => tbl.id.equals(id))).write(
      FamiliesV2Companion(
        isDeleted: const Value(true),
        updatedAt: Value(at),
      ),
    );
  }

  Future<int> restoreFamily(String id, DateTime at) {
    return (update(familiesV2)..where((tbl) => tbl.id.equals(id))).write(
      FamiliesV2Companion(
        isDeleted: const Value(false),
        updatedAt: Value(at),
      ),
    );
  }

  /// Families of [personId] where the person is a partner, excluding
  /// soft-deleted families.
  Stream<List<FamiliesV2Data>> watchFamiliesForPerson(String personId) {
    return (select(familiesV2)
          ..where(
            (tbl) =>
                tbl.isDeleted.equals(false) &
                (tbl.husbandId.equals(personId) | tbl.wifeId.equals(personId)),
          )
          ..orderBy([
            (tbl) => OrderingTerm.desc(tbl.isPrimaryMarriage),
            (tbl) => OrderingTerm.asc(tbl.marriageDate),
          ]))
        .watch();
  }

  /// Families of [personId] where the person is a partner, excluding
  /// soft-deleted families.
  Future<List<FamiliesV2Data>> getFamiliesForPerson(String personId) {
    return (select(familiesV2)
          ..where(
            (tbl) =>
                tbl.isDeleted.equals(false) &
                (tbl.husbandId.equals(personId) | tbl.wifeId.equals(personId)),
          )
          ..orderBy([
            (tbl) => OrderingTerm.desc(tbl.isPrimaryMarriage),
            (tbl) => OrderingTerm.asc(tbl.marriageDate),
          ]))
        .get();
  }

  Future<FamiliesV2Data?> getFamilyById(String familyId) {
    return (select(familiesV2)..where((tbl) => tbl.id.equals(familyId)))
        .getSingleOrNull();
  }

  // ---------------------------------------------------------------------------
  // Family children
  // ---------------------------------------------------------------------------

  Future<void> createFamilyChild(FamilyChildrenV2Companion child) {
    return into(familyChildrenV2).insert(child);
  }

  /// Applies [changes] to the child link with [id]. Keyed partial update.
  Future<int> updateFamilyChildFields(
    String id,
    FamilyChildrenV2Companion changes,
  ) {
    return (update(familyChildrenV2)..where((tbl) => tbl.id.equals(id)))
        .write(changes);
  }

  Future<int> markFamilyChildDeleted(String id, DateTime at) {
    return (update(familyChildrenV2)..where((tbl) => tbl.id.equals(id))).write(
      FamilyChildrenV2Companion(
        isDeleted: const Value(true),
        updatedAt: Value(at),
      ),
    );
  }

  Future<int> restoreFamilyChild(String id, DateTime at) {
    return (update(familyChildrenV2)..where((tbl) => tbl.id.equals(id))).write(
      FamilyChildrenV2Companion(
        isDeleted: const Value(false),
        updatedAt: Value(at),
      ),
    );
  }

  /// Child links of [familyId] that are not soft-deleted.
  Stream<List<FamilyChildrenV2Data>> watchChildrenForFamily(String familyId) {
    return (select(familyChildrenV2)
          ..where(
            (tbl) =>
                tbl.familyId.equals(familyId) & tbl.isDeleted.equals(false),
          )
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.birthOrder),
            (tbl) => OrderingTerm.asc(tbl.createdAt),
          ]))
        .watch();
  }

  /// Child links of [familyId] that are not soft-deleted.
  Future<List<FamilyChildrenV2Data>> getChildrenForFamily(String familyId) {
    return (select(familyChildrenV2)
          ..where(
            (tbl) =>
                tbl.familyId.equals(familyId) & tbl.isDeleted.equals(false),
          )
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.birthOrder),
            (tbl) => OrderingTerm.asc(tbl.createdAt),
          ]))
        .get();
  }

  /// Child links of [familyId], including soft-deleted ones.
  Future<List<FamilyChildrenV2Data>> getAnyChildrenForFamily(
    String familyId,
  ) {
    return (select(familyChildrenV2)
          ..where((tbl) => tbl.familyId.equals(familyId)))
        .get();
  }

  /// The link row for ([familyId], [childId]) regardless of soft-delete state.
  ///
  /// Safe to call with `getSingleOrNull`: `UNIQUE(family_id, child_id)`
  /// guarantees at most one row.
  Future<FamilyChildrenV2Data?> getFamilyChildLink(
    String familyId,
    String childId,
  ) {
    return (select(familyChildrenV2)
          ..where(
            (tbl) =>
                tbl.familyId.equals(familyId) & tbl.childId.equals(childId),
          ))
        .getSingleOrNull();
  }

  /// Hard-deletes a link row. Only for collapsing exact duplicates while
  /// merging; prefer [markFamilyChildDeleted] elsewhere.
  Future<int> removeFamilyChildLinkRow(String id) {
    return (delete(familyChildrenV2)..where((tbl) => tbl.id.equals(id))).go();
  }
}
