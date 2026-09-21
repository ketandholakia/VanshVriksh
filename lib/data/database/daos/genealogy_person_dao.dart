import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/families_v2_table.dart';
import '../tables/family_children_v2_table.dart';
import '../tables/genealogy_persons_table.dart';
import '../tables/surname_events_table.dart';

part 'genealogy_person_dao.g.dart';

@DriftAccessor(
  tables: [GenealogyPersons, SurnameEvents, FamiliesV2, FamilyChildrenV2],
)
class GenealogyPersonDao extends DatabaseAccessor<AppDatabase>
    with _$GenealogyPersonDaoMixin {
  GenealogyPersonDao(super.db);

  Future<void> createPerson(GenealogyPersonsCompanion person) {
    return into(genealogyPersons).insert(person);
  }

  Future<bool> updatePerson(GenealogyPersonsCompanion person) {
    return update(genealogyPersons).replace(person);
  }

  Future<int> deletePerson(String id) {
    return (delete(genealogyPersons)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> createFamily(FamiliesV2Companion family) {
    return into(familiesV2).insert(family);
  }

  Future<void> updateFamily(FamiliesV2Companion family) {
    return update(familiesV2).replace(family);
  }

  Future<void> createFamilyChild(FamilyChildrenV2Companion child) {
    return into(familyChildrenV2).insert(child);
  }

  Future<void> updateFamilyChild(FamilyChildrenV2Companion child) {
    return update(familyChildrenV2).replace(child);
  }

  Future<GenealogyPerson?> getPersonById(String id) {
    return (select(genealogyPersons)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Stream<GenealogyPerson?> watchPersonById(String id) {
    return (select(genealogyPersons)..where((tbl) => tbl.id.equals(id)))
        .watchSingleOrNull();
  }

  Stream<List<GenealogyPerson>> watchPeopleByTree(String treeId) {
    return (select(genealogyPersons)
          ..where((tbl) => tbl.treeId.equals(treeId) & tbl.isDeleted.equals(false))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.firstName)]))
        .watch();
  }

  Future<List<GenealogyPerson>> getPeopleByTree(String treeId) {
    return (select(genealogyPersons)
          ..where((tbl) => tbl.treeId.equals(treeId) & tbl.isDeleted.equals(false))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.firstName)]))
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

  Stream<List<FamilyChildrenV2Data>> watchChildrenForFamily(String familyId) {
    return (select(familyChildrenV2)
          ..where(
            (tbl) => tbl.familyId.equals(familyId) & tbl.isDeleted.equals(false),
          )
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.birthOrder),
            (tbl) => OrderingTerm.asc(tbl.createdAt),
          ]))
        .watch();
  }

  Future<List<FamilyChildrenV2Data>> getChildrenForFamily(String familyId) {
    return (select(familyChildrenV2)
          ..where(
            (tbl) => tbl.familyId.equals(familyId) & tbl.isDeleted.equals(false),
          )
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.birthOrder),
            (tbl) => OrderingTerm.asc(tbl.createdAt),
          ]))
        .get();
  }

}
