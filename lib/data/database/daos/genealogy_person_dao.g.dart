// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'genealogy_person_dao.dart';

// ignore_for_file: type=lint
mixin _$GenealogyPersonDaoMixin on DatabaseAccessor<AppDatabase> {
  $GenealogyPersonsTable get genealogyPersons =>
      attachedDatabase.genealogyPersons;
  $SurnameEventsTable get surnameEvents => attachedDatabase.surnameEvents;
  $FamiliesV2Table get familiesV2 => attachedDatabase.familiesV2;
  $FamilyChildrenV2Table get familyChildrenV2 =>
      attachedDatabase.familyChildrenV2;
  GenealogyPersonDaoManager get managers => GenealogyPersonDaoManager(this);
}

class GenealogyPersonDaoManager {
  final _$GenealogyPersonDaoMixin _db;
  GenealogyPersonDaoManager(this._db);
  $$GenealogyPersonsTableTableManager get genealogyPersons =>
      $$GenealogyPersonsTableTableManager(
        _db.attachedDatabase,
        _db.genealogyPersons,
      );
  $$SurnameEventsTableTableManager get surnameEvents =>
      $$SurnameEventsTableTableManager(_db.attachedDatabase, _db.surnameEvents);
  $$FamiliesV2TableTableManager get familiesV2 =>
      $$FamiliesV2TableTableManager(_db.attachedDatabase, _db.familiesV2);
  $$FamilyChildrenV2TableTableManager get familyChildrenV2 =>
      $$FamilyChildrenV2TableTableManager(
        _db.attachedDatabase,
        _db.familyChildrenV2,
      );
}
