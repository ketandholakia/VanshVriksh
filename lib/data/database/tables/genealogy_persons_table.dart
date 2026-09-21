import 'package:drift/drift.dart';

import 'family_trees_table.dart';

/// Canonical person record.
///
/// Identity and lifecycle rules:
/// * [id] is the immutable database identity, assigned once at insert.
/// * [uuid] is a stable external identity (survives export/import and merges).
/// * [treeId] is mandatory ownership: a person can never exist outside a tree,
///   and the tree cannot be deleted while it still holds people.
/// * Deletion is a **soft delete** ([isDeleted]); hard deletes are rejected by
///   the `RESTRICT` actions on every table that references a person.
/// * [mergedIntoId] records a merge (this person was folded into another one)
///   and is an integrity-checked self reference.
///
/// There are deliberately no `sync_status` / `version` / `last_synced_at`
/// columns: no sync engine exists, so they would be write-only fields that
/// invite the false impression that sync works.
@TableIndex(name: 'idx_genealogy_persons_tree_id', columns: {#treeId})
@TableIndex(
  name: 'idx_genealogy_persons_merged_into',
  columns: {#mergedIntoId},
)
class GenealogyPersons extends Table {
  TextColumn get id => text()();

  TextColumn get firstName => text()();
  TextColumn get middleName => text().nullable()();
  TextColumn get lastName => text().nullable()();
  TextColumn get birthSurname => text().nullable()();
  TextColumn get marriedSurname => text().nullable()();
  TextColumn get suffix => text().nullable()();
  TextColumn get prefix => text().nullable()();
  TextColumn get nickname => text().nullable()();

  TextColumn get displayNameFormat => text().withDefault(const Constant('birth_married'))();
  TextColumn get customDisplayName => text().nullable()();

  TextColumn get gender => text()();

  DateTimeColumn get birthDate => dateTime().nullable()();
  TextColumn get birthDateQualifier => text().nullable()();
  TextColumn get birthPlace => text().nullable()();
  RealColumn get birthPlaceLat => real().nullable()();
  RealColumn get birthPlaceLng => real().nullable()();

  DateTimeColumn get deathDate => dateTime().nullable()();
  TextColumn get deathDateQualifier => text().nullable()();
  TextColumn get deathPlace => text().nullable()();
  RealColumn get deathPlaceLat => real().nullable()();
  RealColumn get deathPlaceLng => real().nullable()();

  TextColumn get currentPlace => text().nullable()();
  BoolColumn get isLiving => boolean().withDefault(const Constant(true))();

  TextColumn get profilePhotoPath => text().nullable()();

  TextColumn get biography => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get occupation => text().nullable()();
  TextColumn get religion => text().nullable()();
  TextColumn get ethnicity => text().nullable()();

  BoolColumn get isPrivate => boolean().withDefault(const Constant(false))();
  IntColumn get privacyLevel => integer().withDefault(const Constant(0))();

  /// Owning tree. Mandatory, integrity checked.
  @ReferenceName('personsInTree')
  TextColumn get treeId => text().references(FamilyTrees, #id, onDelete: KeyAction.restrict)();

  /// Stable external identity.
  TextColumn get uuid => text().unique()();

  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Set when this person was merged into another person.
  @ReferenceName('mergedDuplicates')
  TextColumn get mergedIntoId => text().nullable().references(
        GenealogyPersons,
        #id,
        onDelete: KeyAction.setNull,
      )();

  @override
  Set<Column> get primaryKey => {id};
}
