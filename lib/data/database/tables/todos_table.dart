import 'package:drift/drift.dart';

import 'genealogy_persons_table.dart';

/// A research to-do, optionally attached to a person.
///
/// `RESTRICT` on delete, like the other person-scoped records.
@TableIndex(name: 'idx_todos_person_id', columns: {#personId})
class Todos extends Table {
  TextColumn get id => text()();

  TextColumn get personId => text().nullable().references(
        GenealogyPersons,
        #id,
        onDelete: KeyAction.restrict,
      )();

  TextColumn get taskText => text()();

  TextColumn get dueDate => text().nullable()();

  IntColumn get priority => integer().withDefault(const Constant(1))();

  BoolColumn get completed => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
