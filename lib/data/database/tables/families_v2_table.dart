import 'package:drift/drift.dart';

import 'genealogy_persons_table.dart';

class FamiliesV2 extends Table {
  TextColumn get id => text()();
  @ReferenceName('husbandFamilies')
  TextColumn get husbandId => text().nullable().references(
        GenealogyPersons,
        #id,
      )();
  @ReferenceName('wifeFamilies')
  TextColumn get wifeId => text().nullable().references(
        GenealogyPersons,
        #id,
      )();
  DateTimeColumn get marriageDate => dateTime().nullable()();
  TextColumn get marriageDateQualifier => text().nullable()();
  TextColumn get marriagePlace => text().nullable()();
  RealColumn get marriagePlaceLat => real().nullable()();
  RealColumn get marriagePlaceLng => real().nullable()();
  BoolColumn get wifeTookHusbandName => boolean().withDefault(const Constant(false))();
  BoolColumn get husbandTookWifeName => boolean().withDefault(const Constant(false))();
  BoolColumn get hyphenatedSurname => boolean().withDefault(const Constant(false))();
  TextColumn get customSurnameChange => text().nullable()();
  BoolColumn get noNameChange => boolean().withDefault(const Constant(false))();
  TextColumn get wifeMarriedSurname => text().nullable()();
  TextColumn get wifeNameChangeType => text().nullable()();
  TextColumn get husbandMarriedSurname => text().nullable()();
  TextColumn get husbandNameChangeType => text().nullable()();
  DateTimeColumn get divorceDate => dateTime().nullable()();
  TextColumn get divorceDateQualifier => text().nullable()();
  TextColumn get divorcePlace => text().nullable()();
  BoolColumn get wifeRevertedToMaiden => boolean().withDefault(const Constant(false))();
  BoolColumn get husbandRevertedName => boolean().withDefault(const Constant(false))();
  TextColumn get relationshipType => text().withDefault(const Constant('marriage'))();
  BoolColumn get isPrimaryMarriage => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  TextColumn get privateNotes => text().nullable()();
  TextColumn get uuid => text().unique()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
