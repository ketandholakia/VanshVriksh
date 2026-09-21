import 'package:drift/drift.dart';

import 'family_trees_table.dart';
import 'genealogy_persons_table.dart';

/// Canonical family (a partnership) in the genealogy model.
///
/// A family **is** the partnership: there is no separate spouse/partner table
/// and no generic relationship edge list. The genealogy shape is
///
/// ```
/// FamilyTree ──► Family ──┬─► partner (husband_id  ─┐ nullable, both FK to a person
///                         │   partner (wife_id     ─┘
///                         └─► child  (family_children_v2, UNIQUE(family, child))
/// ```
///
/// * [treeId] is mandatory, so a family can never be orphaned from its tree.
/// * The two partner slots are named for historical reasons but hold any two
///   partners; slot assignment is deterministic (see
///   `RelationshipRepository.addSpouseRelationship`) so the same couple cannot
///   be stored twice.
@TableIndex(name: 'idx_families_v2_tree_id', columns: {#treeId})
@TableIndex(name: 'idx_families_v2_husband_id', columns: {#husbandId})
@TableIndex(name: 'idx_families_v2_wife_id', columns: {#wifeId})
class FamiliesV2 extends Table {
  TextColumn get id => text()();

  @ReferenceName('familiesInTree')
  TextColumn get treeId => text().references(FamilyTrees, #id, onDelete: KeyAction.restrict)();

  @ReferenceName('husbandFamilies')
  TextColumn get husbandId => text().nullable().references(
        GenealogyPersons,
        #id,
        onDelete: KeyAction.restrict,
      )();

  @ReferenceName('wifeFamilies')
  TextColumn get wifeId => text().nullable().references(
        GenealogyPersons,
        #id,
        onDelete: KeyAction.restrict,
      )();

  DateTimeColumn get marriageDate => dateTime().nullable()();
  TextColumn get marriageDateQualifier => text().nullable()();
  TextColumn get marriagePlace => text().nullable()();
  RealColumn get marriagePlaceLat => real().nullable()();
  RealColumn get marriagePlaceLng => real().nullable()();

  BoolColumn get wifeTookHusbandName => boolean().withDefault(const Constant(false))();
  BoolColumn get husbandTookWifeName => boolean().withDefault(const Constant(false))();
  BoolColumn get hyphenatedSurname => boolean().withDefault(const Constant(false))();
  BoolColumn get noNameChange => boolean().withDefault(const Constant(false))();
  TextColumn get customSurnameChange => text().nullable()();
  TextColumn get wifeMarriedSurname => text().nullable()();
  TextColumn get wifeNameChangeType => text().nullable()();
  TextColumn get husbandMarriedSurname => text().nullable()();
  TextColumn get husbandNameChangeType => text().nullable()();

  DateTimeColumn get divorceDate => dateTime().nullable()();
  TextColumn get divorceDateQualifier => text().nullable()();
  TextColumn get divorcePlace => text().nullable()();
  BoolColumn get wifeRevertedToMaiden => boolean().withDefault(const Constant(false))();
  BoolColumn get husbandRevertedName => boolean().withDefault(const Constant(false))();

  /// Partnership kind. Reserved for distinguishing marriage / partnership /
  /// cohabitation; currently always the default.
  TextColumn get relationshipType => text().withDefault(const Constant('marriage'))();

  BoolColumn get isPrimaryMarriage => boolean().withDefault(const Constant(false))();

  TextColumn get notes => text().nullable()();
  TextColumn get privateNotes => text().nullable()();


  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        // The same couple must not be recorded twice. SQLite treats NULLs as
        // distinct in a UNIQUE constraint, so this covers couples only; that at
        // most one single-parent family exists per partner is enforced by
        // `RelationshipRepository` (drift 2.33 `@TableIndex` cannot declare a
        // partial index).
        'UNIQUE(husband_id, wife_id)',
      ];
}
