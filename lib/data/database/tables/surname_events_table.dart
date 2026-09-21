import 'package:drift/drift.dart';

import 'genealogy_persons_table.dart';

class SurnameEvents extends Table {
  TextColumn get id => text()();
  TextColumn get personId => text().references(GenealogyPersons, #id)();
  TextColumn get surname => text()();
  TextColumn get surnameType => text()();
  TextColumn get startDate => text().nullable()();
  TextColumn get startDateQualifier => text().nullable()();
  TextColumn get endDate => text().nullable()();
  TextColumn get endDateQualifier => text().nullable()();
  TextColumn get relatedEventId => text().nullable()();
  TextColumn get relatedPersonId => text().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get legalDocument => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  TextColumn get uuid => text().unique()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
