import 'package:drift/drift.dart';

import 'genealogy_persons_table.dart';

/// A "these two people are the same person" note.
///
/// * Both person references are integrity checked and `CASCADE`: a marker is
///   metadata about a pair, so it must not survive a purge of either person.
/// * There is no `tree_id`: the tree is the pair's tree, derived through the
///   people, and storing it again would be a second source of truth.
/// * The pair is stored in a canonical order (`Repository` normalises it) and
///   constrained `UNIQUE`, so the same pair cannot be marked twice in either
///   argument order.
@TableIndex(name: 'idx_duplicate_markers_person_b', columns: {#personBId})
class DuplicateMarkers extends Table {
  TextColumn get id => text()();

  TextColumn get personAId => text().references(GenealogyPersons, #id, onDelete: KeyAction.cascade)();

  TextColumn get personBId => text().references(GenealogyPersons, #id, onDelete: KeyAction.cascade)();

  TextColumn get reason => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'UNIQUE(person_a_id, person_b_id)',
      ];
}
