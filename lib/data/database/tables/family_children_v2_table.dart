import 'package:drift/drift.dart';

import 'families_v2_table.dart';
import 'genealogy_persons_table.dart';

/// Explicit family → child link.
///
/// There is no tree column here on purpose: ownership is
/// `family_children_v2.family_id → families_v2.tree_id`, which is mandatory and
/// enforced, so the path is unambiguous. [childId] is checked against the same
/// tree by `RelationshipRepository`.
///
/// Delete behaviour: `RESTRICT` in both directions. Removing a family that
/// still claims children, or a person who is still someone's child, must be an
/// explicit operation (dissolve the family, or soft-delete the link), never a
/// silent cascade.
@TableIndex(name: 'idx_family_children_v2_child_id', columns: {#childId})
class FamilyChildrenV2 extends Table {
  TextColumn get id => text()();

  TextColumn get familyId => text().references(FamiliesV2, #id, onDelete: KeyAction.restrict)();

  @ReferenceName('childFamilyLinks')
  TextColumn get childId => text().references(
        GenealogyPersons,
        #id,
        onDelete: KeyAction.restrict,
      )();

  IntColumn get birthOrder => integer().nullable()();

  /// biological / adopted / foster / step / unknown
  TextColumn get relationshipType => text().withDefault(const Constant('biological'))();

  TextColumn get childSurnameAtBirth => text().nullable()();
  TextColumn get paternalRelationship => text().nullable()();
  TextColumn get maternalRelationship => text().nullable()();

  TextColumn get notes => text().nullable()();


  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        // A child can appear at most once in the same family.
        'UNIQUE(family_id, child_id)',
      ];
}
