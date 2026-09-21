import 'package:drift/drift.dart';

import 'citations_table.dart';

/// Links a citation to whatever it supports.
///
/// The `(citation_id, entity_type, entity_id)` primary key keeps it to one
/// citation per target. [entityId] is polymorphic by design (`entity_type` says
/// what it refers to), so it cannot be a foreign key; it is indexed because it is
/// looked up per entity.
@TableIndex(name: 'idx_citation_links_entity_id', columns: {#entityId})
class CitationLinks extends Table {
  /// CASCADE: a link has no meaning without the citation it belongs to.
  TextColumn get citationId => text().references(
        Citations,
        #id,
        onDelete: KeyAction.cascade,
      )();

  TextColumn get entityType => text()();

  TextColumn get entityId => text()();

  IntColumn get confidence => integer().nullable()();

  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {citationId, entityType, entityId};
}
