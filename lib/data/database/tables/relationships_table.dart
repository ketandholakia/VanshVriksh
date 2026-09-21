import 'package:drift/drift.dart';

import 'family_trees_table.dart';
import 'persons_table.dart';

class Relationships extends Table {
  TextColumn get id => text()();

  TextColumn get treeId => text().references(FamilyTrees, #id)();

  /// For parent_child:
  /// personId = parent
  /// relatedPersonId = child
  ///
  /// For spouse:
  /// personId = spouse 1
  /// relatedPersonId = spouse 2
  @ReferenceName('personAsSubjectRelations')
  TextColumn get personId => text().references(Persons, #id)();

  @ReferenceName('personAsObjectRelations')
  TextColumn get relatedPersonId => text().references(Persons, #id)();

  /// Allowed values:
  /// parent_child
  /// spouse
  TextColumn get relationshipType => text()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
