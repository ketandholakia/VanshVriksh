import 'package:drift/drift.dart';

import '../../core/utils/id_generator.dart';
import '../database/app_database.dart';
import '../database/daos/events_dao.dart';

class EventsRepository {
  EventsRepository(this._database);

  final AppDatabase _database;

  EventsDao get _eventsDao => _database.eventsDao;

  Future<String> addEvent({
    required String personId,
    required String eventType,
    DateTime? eventDate,
    String? dateDisplay,
    String? place,
    String? description,
    bool isPrimary = true,
    double? latitude,
    double? longitude,
  }) async {
    final id = IdGenerator.newId();
    final now = DateTime.now();

    await _eventsDao.createEvent(
      EventsCompanion.insert(
        id: id,
        personId: personId,
        eventType: eventType,
        dateSort: Value(eventDate?.millisecondsSinceEpoch.toDouble()),
        dateDisplay: Value(dateDisplay?.trim()),
        place: Value(place?.trim()),
        description: Value(description?.trim()),
        isPrimary: Value(isPrimary),
        latitude: Value(latitude),
        longitude: Value(longitude),
        createdAt: now,
        updatedAt: now,
      ),
    );

    return id;
  }

  Stream<List<Event>> watchEventsForPerson(String personId) {
    return _eventsDao.watchEventsForPerson(personId);
  }

  Future<bool> updateEvent({
    required String id,
    required String personId,
    required String eventType,
    DateTime? eventDate,
    String? dateDisplay,
    String? place,
    String? description,
    bool isPrimary = true,
    double? latitude,
    double? longitude,
    required DateTime createdAt,
  }) {
    return _eventsDao.updateEvent(
      EventsCompanion(
        id: Value(id),
        personId: Value(personId),
        eventType: Value(eventType),
        dateSort: Value(eventDate?.millisecondsSinceEpoch.toDouble()),
        dateDisplay: Value(dateDisplay?.trim()),
        place: Value(place?.trim()),
        description: Value(description?.trim()),
        isPrimary: Value(isPrimary),
        latitude: Value(latitude),
        longitude: Value(longitude),
        createdAt: Value(createdAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<Event?> getEventById(String eventId) {
    return _eventsDao.getEventById(eventId);
  }

  Future<int> deleteEvent(String eventId) {
    return _eventsDao.deleteEvent(eventId);
  }
}
