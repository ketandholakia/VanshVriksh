import 'package:drift/drift.dart';

class FamilyTrees extends Table {
  TextColumn get id => text()();

  TextColumn get treeName => text()();

  TextColumn get description => text().nullable()();

  TextColumn get rootPersonId => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
