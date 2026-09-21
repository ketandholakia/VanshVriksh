import 'package:drift/drift.dart';

class SyncChangeLog extends Table {
  TextColumn get id => text()();

  TextColumn get sourceTableName => text()();

  TextColumn get recordUuid => text()();

  TextColumn get changeType => text()();

  TextColumn get changeData => text().nullable()();

  DateTimeColumn get changedAt => dateTime()();

  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  TextColumn get deviceId => text().withDefault(const Constant('local'))();

  @override
  Set<Column> get primaryKey => {id};
}
