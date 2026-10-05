import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/backup_service.dart';
import 'database_provider.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  // The live connection lets the service checkpoint the WAL before the
  // database file is copied (backup) or replaced (restore).
  return BackupService(database: ref.watch(databaseProvider));
});
