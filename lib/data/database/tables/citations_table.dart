import 'package:drift/drift.dart';

import 'media_items_table.dart';

/// A source citation.
///
/// Note: this subsystem has no producer or consumer in the app yet; it is kept
/// because the schema is sound and the feature is intended. Its relationships are
/// nonetheless enforced like every other table's.
@TableIndex(name: 'idx_citations_image_media_id', columns: {#imageMediaId})
class Citations extends Table {
  TextColumn get id => text()();

  TextColumn get sourceTitle => text()();

  TextColumn get sourceType => text().nullable()();

  TextColumn get repository => text().nullable()();

  TextColumn get citationText => text()();

  TextColumn get url => text().nullable()();

  /// Auxiliary pointer to a scanned image: cleared rather than blocking the
  /// media row's removal.
  TextColumn get imageMediaId => text().nullable().references(
        MediaItems,
        #id,
        onDelete: KeyAction.setNull,
      )();

  TextColumn get accessedDate => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
