import 'package:drift/drift.dart';

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
  /// Deliberately **not** a foreign key: `genealogy_persons.tree_id` already
  /// references this table, and drift resolves that table-level cycle by
  /// dropping one of the two constraints — which silently removed the mandatory
  /// ownership key on people. Ownership is the constraint that matters, so this
  /// optional pointer is validated in the repository/migration instead.
  TextColumn get rootPersonId => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
