import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/events_table.dart';

part 'events_dao.g.dart';

@DriftAccessor(tables: [Events])
class EventsDao extends DatabaseAccessor<AppDatabase> with _$EventsDaoMixin {
  EventsDao(super.db);

  Future<void> createEvent(EventsCompanion event) {
    return into(events).insert(event);
  }

  Future<bool> updateEvent(EventsCompanion event) {
    return update(events).replace(event);
  }

  Future<int> deleteEvent(String eventId) {
    return (delete(events)..where((tbl) => tbl.id.equals(eventId))).go();
  }

  Stream<List<Event>> watchEventsForPerson(String personId) {
    return (select(events)
          ..where((tbl) => tbl.personId.equals(personId))
          ..orderBy([
            (tbl) => OrderingTerm.desc(tbl.createdAt),
          ]))
        .watch();
  }

  Future<Event?> getEventById(String eventId) {
    return (select(events)..where((tbl) => tbl.id.equals(eventId)))
        .getSingleOrNull();
  }
}
