import 'package:drift/drift.dart';

import 'genealogy_persons_table.dart';

/// A family tree: the ownership root of the model.
///
/// Everything genealogical belongs to exactly one tree. People and families
/// carry `tree_id` directly; every other entity is owned through its parent row
/// (a child link through its family, an event/media/note through its person).
///
/// Deleting a tree is refused while it still holds people or families
/// (`RESTRICT`), so a tree can never be deleted into an orphaned state.
@TableIndex(name: 'idx_family_trees_root_person', columns: {#rootPersonId})
class FamilyTrees extends Table {
  TextColumn get id => text()();

  TextColumn get treeName => text()();

  TextColumn get description => text().nullable()();

  /// The person the tree is conceptually rooted at.
  ///
  /// Integrity checked and cleared on delete (`SET NULL`): if the person row is
  /// ever hard-deleted the root is emptied rather than left dangling.
  ///
  /// This reference points back at `genealogy_persons` from `family_trees`, the
  /// same pair of tables the mandatory ownership key on people points across. The
  /// two together form a cycle, and drift drops one reference when it sees a
  /// cycle — so the ownership key is declared as a raw table constraint instead
  /// (see `genealogy_persons_table.dart`). Both are enforced; neither is dropped.
  @ReferenceName('rootOfTrees')
  TextColumn get rootPersonId => text().nullable().references(
    GenealogyPersons,
    #id,
    onDelete: KeyAction.setNull,
  )();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
