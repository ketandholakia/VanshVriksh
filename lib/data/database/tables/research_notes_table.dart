import 'package:drift/drift.dart';

import 'genealogy_persons_table.dart';

class ResearchNotes extends Table {
  TextColumn get id => text()();

  TextColumn get personId => text().nullable().references(GenealogyPersons, #id)();

  TextColumn get noteText => text()();

  TextColumn get researchQuestion => text().nullable()();

  RealColumn get noteDateSort => real().nullable()();

  TextColumn get noteDateDisplay => text().nullable()();

  BoolColumn get resolved => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
