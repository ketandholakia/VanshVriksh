import 'package:drift/drift.dart';

import 'genealogy_persons_table.dart';

/// A research note. May be person-scoped ([personId] nullable) or tree-level.
///
/// `RESTRICT` on delete: notes are the user's own working record.
@TableIndex(name: 'idx_research_notes_person_id', columns: {#personId})
class ResearchNotes extends Table {
  TextColumn get id => text()();

  TextColumn get personId => text().nullable().references(
        GenealogyPersons,
        #id,
        onDelete: KeyAction.restrict,
      )();

  TextColumn get noteText => text()();

  TextColumn get researchQuestion => text().nullable()();

  RealColumn get noteDateSort => real().nullable()();

  TextColumn get noteDateDisplay => text().nullable()();

  BoolColumn get resolved => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
