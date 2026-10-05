import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

import '../data/database/app_database.dart';
import 'backup_container.dart';

/// Creates and restores VanshVriksh backups.
///
/// A backup is a ZIP of the database file plus the photo/media directories.
/// With a password it is wrapped in the `VVBK1` container — see
/// [BackupContainerCodec] for the format and the crypto.
class BackupService {
  BackupService({AppDatabase? database}) : _database = database;

  /// The live connection, used only to checkpoint the WAL so the database
  /// file on disk is complete before it is copied or replaced. Optional:
  /// without it the service still works, just without the checkpoint.
  final AppDatabase? _database;

  static const String databaseFileName = 'vanshvriksh.db';
  static const String profilePhotosFolderName = 'profile_photos';
  static const String personMediaFolderName = 'person_media';
  static const String backupHistoryKey = 'backup_history';
  static const String lastBackupAtKey = 'last_backup_at';
  static const String lastBackupLocationKey = 'last_backup_location';
  static const String lastBackupFileKey = 'last_backup_file';

  Future<File> createBackup({String? password}) async {
    // Flush any write-ahead log into the database file so the copy captures
    // every committed transaction.
    await _checkpointLiveDatabase();

    final backupFile = await _createZipBackup();
    if (password == null || password.isEmpty) {
      await _recordBackup(
        location: 'local',
        fileName: p.basename(backupFile.path),
        filePath: backupFile.path,
        encrypted: false,
      );
      return backupFile;
    }

    final encryptedFile = await _encryptBackupFile(backupFile, password);
    // The password protects nothing if the plaintext zip stays behind.
    try {
      await backupFile.delete();
    } catch (_) {
      // Best effort; the encrypted file is already safely written.
    }
    await _recordBackup(
      location: 'local',
      fileName: p.basename(encryptedFile.path),
      filePath: encryptedFile.path,
      encrypted: true,
    );
    return encryptedFile;
  }

  Future<void> restoreBackup(File backupFile, {String? password}) async {
    final appDir = await getApplicationDocumentsDirectory();
    final bytes = await _resolveBackupBytes(backupFile, password);
    final archive = ZipDecoder().decodeBytes(bytes);

    final hasDatabase = archive.files.any(
      (file) => file.name == databaseFileName,
    );
    if (!hasDatabase) {
      throw Exception('Invalid backup file. Database not found in backup.');
    }

    // Stage everything in a scratch directory first. Nothing in the app
    // directory is touched until every entry has passed the path check and
    // the staged database has passed an integrity check.
    final stagingDir = Directory(
      p.join(
        appDir.path,
        'backups',
        'restore_staging_${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
    await stagingDir.create(recursive: true);
    try {
      for (final file in archive.files) {
        // Refuses absolute paths and `..` segments (zip slip) before the
        // name is ever joined onto a directory.
        final destination = safeRestoreDestination(appDir.path, file.name);
        final stagedPath = p.join(
          stagingDir.path,
          p.relative(destination, from: appDir.path),
        );
        if (file.isFile) {
          final outputFile = File(stagedPath);
          if (!await outputFile.parent.exists()) {
            await outputFile.parent.create(recursive: true);
          }
          await outputFile.writeAsBytes(file.content as List<int>);
        } else {
          final outputDir = Directory(stagedPath);
          if (!await outputDir.exists()) {
            await outputDir.create(recursive: true);
          }
        }
      }

      _verifyStagedDatabase(p.join(stagingDir.path, databaseFileName));

      // Snapshot the current state first, so restoring a wrong or broken
      // file is recoverable.
      final snapshot = await _createZipBackup(
        fileNamePrefix: 'vanshvriksh_pre_restore',
      );
      await _recordBackup(
        location: 'pre-restore',
        fileName: p.basename(snapshot.path),
        filePath: snapshot.path,
        encrypted: false,
      );

      await _checkpointLiveDatabase();

      // Copy the verified staged files into place.
      await for (final entity in stagingDir.list(recursive: true)) {
        final relative = p.relative(entity.path, from: stagingDir.path);
        final target = p.join(appDir.path, relative);
        if (entity is File) {
          final targetFile = File(target);
          if (!await targetFile.parent.exists()) {
            await targetFile.parent.create(recursive: true);
          }
          await entity.copy(target);
        } else if (entity is Directory) {
          final targetDir = Directory(target);
          if (!await targetDir.exists()) {
            await targetDir.create(recursive: true);
          }
        }
      }

      // Stale journal companions of the replaced database would corrupt the
      // freshly copied file on next open.
      for (final companion in ['-wal', '-shm']) {
        final companionFile = File(
          '${p.join(appDir.path, databaseFileName)}$companion',
        );
        if (await companionFile.exists()) {
          try {
            await companionFile.delete();
          } catch (_) {
            // The connection may hold it open; the checkpoint above has
            // already folded its contents into the database file.
          }
        }
      }
    } finally {
      try {
        await stagingDir.delete(recursive: true);
      } catch (_) {
        // Best effort cleanup.
      }
    }
  }

  /// Resolves [entryName] (a ZIP entry path) to a path inside [rootDir],
  /// refusing anything that would escape it: absolute paths, drive letters,
  /// backslash tricks, and `..` segments.
  static String safeRestoreDestination(String rootDir, String entryName) {
    final normalized = entryName.replaceAll('\\', '/');
    if (normalized.startsWith('/') ||
        RegExp(r'^[A-Za-z]:').hasMatch(normalized)) {
      throw FormatException('Unsafe backup entry (absolute path): $entryName');
    }
    final segments = normalized
        .split('/')
        .where((segment) => segment.isNotEmpty && segment != '.')
        .toList();
    if (segments.isEmpty) {
      throw FormatException('Unsafe backup entry (empty path): $entryName');
    }
    if (segments.contains('..')) {
      throw FormatException('Unsafe backup entry (path traversal): $entryName');
    }
    return p.joinAll([rootDir, ...segments]);
  }

  /// Opens the staged database read-only and runs SQLite's integrity check,
  /// so a corrupt restore fails before overwriting the live data.
  void _verifyStagedDatabase(String path) {
    final db = sql.sqlite3.open(path, mode: sql.OpenMode.readOnly);
    try {
      final rows = db.select('PRAGMA integrity_check');
      final status = rows.isEmpty
          ? ''
          : (rows.first.values.first?.toString() ?? '');
      if (status != 'ok') {
        throw Exception(
          'The backup database failed the integrity check ($status). '
          'The live data was not modified.',
        );
      }
    } finally {
      db.close();
    }
  }

  Future<void> _checkpointLiveDatabase() async {
    final db = _database;
    if (db == null) return;
    try {
      db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    } catch (_) {
      // The connection may be closing; the file copy still captures the
      // last committed state.
    }
  }

  Future<List<BackupRecord>> getBackupHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(backupHistoryKey) ?? const [];
    return raw.map(BackupRecord.fromEncoded).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<BackupRecord?> getLastBackup() async {
    final history = await getBackupHistory();
    return history.isEmpty ? null : history.first;
  }

  Future<File> _createZipBackup({
    String fileNamePrefix = 'vanshvriksh_backup',
  }) async {
    final appDir = await getApplicationDocumentsDirectory();

    final dbFile = File(p.join(appDir.path, databaseFileName));
    if (!await dbFile.exists()) {
      throw Exception('Database file not found.');
    }

    final backupDir = Directory(p.join(appDir.path, 'backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final now = DateTime.now();
    final fileName =
        '${fileNamePrefix}_${now.year}_${_two(now.month)}_${_two(now.day)}_${_two(now.hour)}_${_two(now.minute)}.zip';
    final backupPath = p.join(backupDir.path, fileName);

    final encoder = ZipFileEncoder();
    encoder.create(backupPath);
    encoder.addFile(dbFile, databaseFileName);

    final profilePhotosDir = Directory(
      p.join(appDir.path, profilePhotosFolderName),
    );
    if (await profilePhotosDir.exists()) {
      encoder.addDirectory(profilePhotosDir, includeDirName: true);
    }

    final personMediaDir = Directory(
      p.join(appDir.path, personMediaFolderName),
    );
    if (await personMediaDir.exists()) {
      encoder.addDirectory(personMediaDir, includeDirName: true);
    }

    encoder.close();
    return File(backupPath);
  }

  Future<File> _encryptBackupFile(File backupFile, String password) async {
    final encryptedBytes = BackupContainerCodec.encrypt(
      await backupFile.readAsBytes(),
      password,
    );
    final encryptedPath = backupFile.path.replaceAll('.zip', '.enc');
    final encryptedFile = File(encryptedPath);
    await encryptedFile.writeAsBytes(encryptedBytes, flush: true);
    return encryptedFile;
  }

  Future<List<int>> _resolveBackupBytes(
    File backupFile,
    String? password,
  ) async {
    final bytes = await backupFile.readAsBytes();
    // Encrypted files are recognised by extension and by the container
    // magic, so a renamed backup still asks for its password.
    final encrypted =
        _isEncryptedFile(backupFile) || BackupContainerCodec.hasMagic(bytes);
    if (!encrypted) {
      return bytes;
    }

    if (password == null || password.isEmpty) {
      throw Exception(
        'This backup is encrypted. Please enter the backup password.',
      );
    }

    return BackupContainerCodec.decrypt(bytes, password);
  }

  bool _isEncryptedFile(File file) =>
      p.extension(file.path).toLowerCase() == '.enc';

  Future<void> _recordBackup({
    required String location,
    required String fileName,
    required String filePath,
    required bool encrypted,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getBackupHistory();
    final record = BackupRecord(
      location: location,
      fileName: fileName,
      filePath: filePath,
      timestamp: DateTime.now(),
      status: 'success',
      encrypted: encrypted,
    );
    final nextHistory = [record, ...history].take(20).toList();
    await prefs.setStringList(
      backupHistoryKey,
      nextHistory.map((item) => item.encode()).toList(),
    );
    await prefs.setString(lastBackupAtKey, record.timestamp.toIso8601String());
    await prefs.setString(lastBackupLocationKey, location);
    await prefs.setString(lastBackupFileKey, fileName);
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}

class BackupRecord {
  const BackupRecord({
    required this.location,
    required this.fileName,
    required this.filePath,
    required this.timestamp,
    required this.status,
    this.encrypted = false,
  });

  final String location;
  final String fileName;
  final String filePath;
  final DateTime timestamp;
  final String status;
  final bool encrypted;

  String encode() => jsonEncode({
    'location': location,
    'fileName': fileName,
    'filePath': filePath,
    'timestamp': timestamp.toIso8601String(),
    'status': status,
    'encrypted': encrypted,
  });

  factory BackupRecord.fromEncoded(String encoded) {
    final data = jsonDecode(encoded) as Map<String, dynamic>;
    return BackupRecord(
      location: data['location'] as String? ?? 'local',
      fileName: data['fileName'] as String? ?? 'backup.zip',
      filePath: data['filePath'] as String? ?? '',
      timestamp:
          DateTime.tryParse(data['timestamp'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: data['status'] as String? ?? 'success',
      encrypted: data['encrypted'] as bool? ?? false,
    );
  }
}
