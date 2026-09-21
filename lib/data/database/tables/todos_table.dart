import 'package:drift/drift.dart';

import 'genealogy_persons_table.dart';

class Todos extends Table {
  TextColumn get id => text()();

  TextColumn get personId => text().nullable().references(GenealogyPersons, #id)();

  TextColumn get taskText => text()();

  TextColumn get dueDate => text().nullable()();

  IntColumn get priority => integer().withDefault(const Constant(1))();

  BoolColumn get completed => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
