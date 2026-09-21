// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'events_dao.dart';

// ignore_for_file: type=lint
mixin _$EventsDaoMixin on DatabaseAccessor<AppDatabase> {
  $GenealogyPersonsTable get genealogyPersons =>
      attachedDatabase.genealogyPersons;
  $EventsTable get events => attachedDatabase.events;
  EventsDaoManager get managers => EventsDaoManager(this);
}

class EventsDaoManager {
  final _$EventsDaoMixin _db;
  EventsDaoManager(this._db);
  $$GenealogyPersonsTableTableManager get genealogyPersons =>
      $$GenealogyPersonsTableTableManager(
        _db.attachedDatabase,
        _db.genealogyPersons,
      );
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db.attachedDatabase, _db.events);
}
