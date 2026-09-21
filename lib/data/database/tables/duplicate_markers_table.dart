import 'package:drift/drift.dart';

class DuplicateMarkers extends Table {
  TextColumn get id => text()();
  TextColumn get treeId => text()();
  TextColumn get personAId => text()();
  TextColumn get personBId => text()();
  TextColumn get reason => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
