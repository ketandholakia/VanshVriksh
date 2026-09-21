import 'package:drift/drift.dart';

import 'genealogy_persons_table.dart';

/// A media item attached to a person. Owned through [personId].
///
/// `RESTRICT` on delete: the row points at a file on disk, so dropping it
/// silently would leave an orphaned file with nothing referencing it.
@TableIndex(name: 'idx_media_items_person_id', columns: {#personId})
class MediaItems extends Table {
  TextColumn get id => text()();

  TextColumn get personId => text().references(GenealogyPersons, #id, onDelete: KeyAction.restrict)();

  TextColumn get filePath => text()();

  /// photo / document / audio / video
  TextColumn get mediaType => text()();

  TextColumn get title => text().nullable()();

  TextColumn get description => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
