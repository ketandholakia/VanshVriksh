import 'package:drift/drift.dart';

import 'genealogy_persons_table.dart';

class MediaItems extends Table {
  TextColumn get id => text()();

  TextColumn get personId => text().references(GenealogyPersons, #id)();

  TextColumn get filePath => text()();

  /// photo / document / audio / video
  TextColumn get mediaType => text()();

  TextColumn get title => text().nullable()();

  TextColumn get description => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
