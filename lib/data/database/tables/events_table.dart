import 'package:drift/drift.dart';

import 'genealogy_persons_table.dart';

/// A dated, person-scoped life event (birth, marriage, baptism, residence...).
///
/// Owned through [personId]. `RESTRICT` on delete: an event must never be
/// silently destroyed with its person; the person delete path is a soft delete
/// and keeps these rows.
@TableIndex(name: 'idx_events_person_id', columns: {#personId})
class Events extends Table {
  TextColumn get id => text()();

  TextColumn get personId =>
      text().references(GenealogyPersons, #id, onDelete: KeyAction.restrict)();

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
