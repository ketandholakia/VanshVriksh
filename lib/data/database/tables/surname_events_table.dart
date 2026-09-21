import 'package:drift/drift.dart';

import 'events_table.dart';
import 'genealogy_persons_table.dart';

/// The surname history of a person (birth surname, marriage surname, ...).
///
/// Owned through [personId]. [relatedPersonId] / [relatedEventId] are auxiliary
/// pointers: `SET NULL`, because losing the person an event relates to must not
/// destroy the surname record itself.
@TableIndex(name: 'idx_surname_events_person_id', columns: {#personId})
@TableIndex(
  name: 'idx_surname_events_related_person_id',
  columns: {#relatedPersonId},
)
@TableIndex(
  name: 'idx_surname_events_related_event_id',
  columns: {#relatedEventId},
)
class SurnameEvents extends Table {
  TextColumn get id => text()();

  TextColumn get personId => text().references(GenealogyPersons, #id, onDelete: KeyAction.restrict)();

  TextColumn get surname => text()();

  TextColumn get surnameType => text()();

  TextColumn get startDate => text().nullable()();
  TextColumn get startDateQualifier => text().nullable()();
  TextColumn get endDate => text().nullable()();
  TextColumn get endDateQualifier => text().nullable()();

  @ReferenceName('surnameEventsAbout')
  TextColumn get relatedPersonId => text().nullable().references(
        GenealogyPersons,
        #id,
        onDelete: KeyAction.setNull,
      )();

  @ReferenceName('surnameEventsFrom')
  TextColumn get relatedEventId => text().nullable().references(
        Events,
        #id,
        onDelete: KeyAction.setNull,
      )();

  TextColumn get location => text().nullable()();
  TextColumn get legalDocument => text().nullable()();
  TextColumn get notes => text().nullable()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();


  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
