import 'package:drift/drift.dart';

import '../../core/utils/id_generator.dart';
import '../database/app_database.dart';
import '../database/daos/media_dao.dart';

class MediaRepository {
  MediaRepository(this._database);

  final AppDatabase _database;

  MediaDao get _mediaDao => MediaDao(_database);

  Future<void> addMediaItem({
    required String personId,
    required String filePath,
    required String mediaType,
    String? title,
    String? description,
  }) {
    return _mediaDao.createMediaItem(
      MediaItemsCompanion.insert(
        id: IdGenerator.newId(),
        personId: personId,
        filePath: filePath,
        mediaType: mediaType,
        title: Value(title?.trim()),
        description: Value(description?.trim()),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<int> deleteMediaItem(String mediaId) {
    return _mediaDao.deleteMediaItem(mediaId);
  }

  Future<MediaItem?> getMediaItemById(String mediaId) {
    return _mediaDao.getMediaItemById(mediaId);
  }

  Stream<List<MediaItem>> watchMediaByPerson(String personId) {
    return _mediaDao.watchMediaByPerson(personId);
  }

  Future<List<MediaItem>> getMediaByPerson(String personId) {
    return _mediaDao.getMediaByPerson(personId);
  }
}
