import 'package:drift/drift.dart';

import 'citations_table.dart';

class CitationLinks extends Table {
  TextColumn get citationId => text().references(Citations, #id)();

  TextColumn get entityType => text()();

  TextColumn get entityId => text()();

  IntColumn get confidence => integer().nullable()();

  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {citationId, entityType, entityId};
}
