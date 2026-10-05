import 'package:drift/drift.dart';

import 'genealogy_persons_table.dart';

/// A genogram relationship dynamic between two people — close, conflict,
/// estranged, distant — the lines that sit on top of lineage in a genogram.
///
/// The pair is stored **canonically ordered** (`person_a_id < person_b_id` as
/// strings), which makes `UNIQUE(person_a_id, person_b_id)` mean "this pair
/// has one bond" regardless of who was picked first in the UI. Bonds are
/// undirected: "A conflicts with B" is the same line as "B conflicts with A".
///
/// There is no soft delete: a removed bond is gone. Bonds are annotations,
/// not evidence of a relationship — deleting one loses nothing that parentage
/// or partnerships depend on.
@TableIndex(name: 'idx_person_bonds_person_a', columns: {#personAId})
@TableIndex(name: 'idx_person_bonds_person_b', columns: {#personBId})
class PersonBonds extends Table {
  TextColumn get id => text()();

  /// Lexicographically smaller id of the pair.
  @ReferenceName('bondsAsA')
  TextColumn get personAId =>
      text().references(GenealogyPersons, #id, onDelete: KeyAction.cascade)();

  /// Lexicographically larger id of the pair.
  @ReferenceName('bondsAsB')
  TextColumn get personBId =>
      text().references(GenealogyPersons, #id, onDelete: KeyAction.cascade)();

  /// `close`, `conflict`, `estranged` or `distant`.
  TextColumn get bondType => text()();

  /// Free-text context — when the dynamic started, what is known about it.
  TextColumn get notes => text().nullable()();

  TextColumn get treeId => text()();

  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE (person_a_id, person_b_id)'];
}
