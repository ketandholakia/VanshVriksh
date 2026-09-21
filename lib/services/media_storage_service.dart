import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MediaStorageService {
  Future<String> savePersonMedia({
    required File sourceFile,
    required String personId,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();

    final mediaDir = Directory(p.join(appDir.path, 'person_media', personId));
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    final extension = p.extension(sourceFile.path).toLowerCase();
    final safeExtension = extension.isEmpty ? '.dat' : extension;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$safeExtension';
    final destinationPath = p.join(mediaDir.path, fileName);

    final savedFile = await sourceFile.copy(destinationPath);
    return savedFile.path;
  }

  Future<void> deleteFileIfExists(String? filePath) async {
    if (filePath == null || filePath.trim().isEmpty) return;

    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
