import 'package:drift/drift.dart';

import '../app_database.dart';

class MediaDao {
  MediaDao(this._database);

  final AppDatabase _database;

  Future<void> createMediaItem(MediaItemsCompanion mediaItem) {
    return _database.into(_database.mediaItems).insert(mediaItem);
  }

  Future<int> deleteMediaItem(String mediaId) {
    return (_database.delete(
      _database.mediaItems,
    )..where((tbl) => tbl.id.equals(mediaId))).go();
  }

  Future<MediaItem?> getMediaItemById(String mediaId) {
    return (_database.select(
      _database.mediaItems,
    )..where((tbl) => tbl.id.equals(mediaId))).getSingleOrNull();
  }

  Stream<List<MediaItem>> watchMediaByPerson(String personId) {
    return (_database.select(_database.mediaItems)
          ..where((tbl) => tbl.personId.equals(personId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .watch();
  }

  Future<List<MediaItem>> getMediaByPerson(String personId) {
    return (_database.select(_database.mediaItems)
          ..where((tbl) => tbl.personId.equals(personId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();
  }
}
