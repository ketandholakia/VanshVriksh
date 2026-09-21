import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/media_storage_service.dart';

final mediaStorageServiceProvider = Provider<MediaStorageService>((ref) {
  return MediaStorageService();
});
