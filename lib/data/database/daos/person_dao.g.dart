// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person_dao.dart';

// ignore_for_file: type=lint
mixin _$PersonDaoMixin on DatabaseAccessor<AppDatabase> {
  $FamilyTreesTable get familyTrees => attachedDatabase.familyTrees;
  $PersonsTable get persons => attachedDatabase.persons;
  PersonDaoManager get managers => PersonDaoManager(this);
}

class PersonDaoManager {
  final _$PersonDaoMixin _db;
  PersonDaoManager(this._db);
  $$FamilyTreesTableTableManager get familyTrees =>
      $$FamilyTreesTableTableManager(_db.attachedDatabase, _db.familyTrees);
  $$PersonsTableTableManager get persons =>
      $$PersonsTableTableManager(_db.attachedDatabase, _db.persons);
}
