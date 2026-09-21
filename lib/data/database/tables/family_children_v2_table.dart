import 'package:drift/drift.dart';

import 'families_v2_table.dart';
import 'genealogy_persons_table.dart';

class FamilyChildrenV2 extends Table {
  TextColumn get id => text()();
  TextColumn get familyId => text().references(FamiliesV2, #id)();
  @ReferenceName('childFamilyLinks')
  TextColumn get childId => text().references(
        GenealogyPersons,
        #id,
      )();
  IntColumn get birthOrder => integer().nullable()();
  TextColumn get relationshipType => text().withDefault(const Constant('biological'))();
  TextColumn get childSurnameAtBirth => text().nullable()();
  TextColumn get paternalRelationship => text().nullable()();
  TextColumn get maternalRelationship => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get uuid => text().unique()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'UNIQUE(family_id, child_id)',
      ];
}
