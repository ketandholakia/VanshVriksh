import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/persons_table.dart';

part 'person_dao.g.dart';

@DriftAccessor(tables: [Persons])
class PersonDao extends DatabaseAccessor<AppDatabase> with _$PersonDaoMixin {
  PersonDao(super.db);

  Future<void> createPerson(PersonsCompanion person) {
    return into(persons).insert(person);
  }

  Future<bool> updatePerson(PersonsCompanion person) {
    return update(persons).replace(person);
  }

  Future<int> deletePerson(String personId) {
    return (delete(persons)..where((tbl) => tbl.id.equals(personId))).go();
  }

  Future<Person?> getPersonById(String personId) {
    return (select(persons)..where((tbl) => tbl.id.equals(personId)))
        .getSingleOrNull();
  }

  Stream<Person?> watchPersonById(String personId) {
    return (select(persons)..where((tbl) => tbl.id.equals(personId)))
        .watchSingleOrNull();
  }

  Stream<List<Person>> watchPeopleByTree(String treeId) {
    return (select(persons)
          ..where((tbl) => tbl.treeId.equals(treeId))
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.fullName),
          ]))
        .watch();
  }

  Future<List<Person>> getPeopleByTree(String treeId) {
    return (select(persons)
          ..where((tbl) => tbl.treeId.equals(treeId))
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.fullName),
          ]))
        .get();
  }

  Future<List<Person>> searchPeople({
    required String treeId,
    required String query,
  }) {
    final searchText = '%${query.trim()}%';
    return (select(persons)
          ..where(
            (tbl) =>
                tbl.treeId.equals(treeId) &
                (tbl.fullName.like(searchText) |
                    tbl.firstName.like(searchText) |
                    tbl.middleName.like(searchText) |
                    tbl.lastName.like(searchText) |
                    tbl.nickname.like(searchText) |
                    tbl.birthPlace.like(searchText) |
                    tbl.currentPlace.like(searchText)),
          )
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.fullName),
          ]))
        .get();
  }
}
