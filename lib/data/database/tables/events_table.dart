import 'package:drift/drift.dart';

import 'genealogy_persons_table.dart';

class Events extends Table {
  TextColumn get id => text()();

  TextColumn get personId => text().references(GenealogyPersons, #id)();

  TextColumn get eventType => text()();

  RealColumn get dateSort => real().nullable()();

  TextColumn get dateDisplay => text().nullable()();

  TextColumn get place => text().nullable()();

  TextColumn get description => text().nullable()();

  BoolColumn get isPrimary => boolean().withDefault(const Constant(true))();

  RealColumn get latitude => real().nullable()();

  RealColumn get longitude => real().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
