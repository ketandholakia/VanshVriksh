import 'package:drift/drift.dart';

import 'family_trees_table.dart';

class Persons extends Table {
  TextColumn get id => text()();

  TextColumn get treeId => text().references(FamilyTrees, #id)();

  TextColumn get fullName => text()();

  TextColumn get firstName => text().nullable()();

  TextColumn get middleName => text().nullable()();

  TextColumn get lastName => text().nullable()();

  TextColumn get birthSurname => text().nullable()();

  TextColumn get marriedSurname => text().nullable()();

  TextColumn get prefix => text().nullable()();

  TextColumn get suffix => text().nullable()();

  TextColumn get nickname => text().nullable()();

  TextColumn get gender => text()();

  DateTimeColumn get birthDate => dateTime().nullable()();

  TextColumn get birthDateDisplay => text().nullable()();

  RealColumn get birthDateSort => real().nullable()();

  DateTimeColumn get deathDate => dateTime().nullable()();

  TextColumn get deathDateDisplay => text().nullable()();

  RealColumn get deathDateSort => real().nullable()();

  TextColumn get birthPlace => text().nullable()();

  TextColumn get currentPlace => text().nullable()();

  TextColumn get profilePhotoPath => text().nullable()();

  TextColumn get bio => text().nullable()();

  TextColumn get notes => text().nullable()();

  BoolColumn get private => boolean().withDefault(const Constant(false))();

  BoolColumn get isLiving => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
