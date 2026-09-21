import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageStorageService {
  Future<String> saveProfilePhoto({
    required File sourceFile,
    required String personId,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();

    final profileDir = Directory(p.join(appDir.path, 'profile_photos'));
    if (!await profileDir.exists()) {
      await profileDir.create(recursive: true);
    }

    final extension = p.extension(sourceFile.path).toLowerCase();
    final safeExtension = extension.isEmpty ? '.jpg' : extension;
    final fileName =
        '${personId}_${DateTime.now().millisecondsSinceEpoch}$safeExtension';
    final destinationPath = p.join(profileDir.path, fileName);

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
