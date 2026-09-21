import 'package:drift/drift.dart';

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

  TextColumn get treeId => text()();

  TextColumn get uuid => text().unique()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get mergedIntoId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
