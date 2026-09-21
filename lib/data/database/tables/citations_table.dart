import 'package:drift/drift.dart';

import 'media_items_table.dart';

class Citations extends Table {
  TextColumn get id => text()();

  TextColumn get sourceTitle => text()();

  TextColumn get sourceType => text().nullable()();

  TextColumn get repository => text().nullable()();

  TextColumn get citationText => text()();

  TextColumn get url => text().nullable()();

  TextColumn get imageMediaId => text().nullable().references(MediaItems, #id)();

  TextColumn get accessedDate => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
