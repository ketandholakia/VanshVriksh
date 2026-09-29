import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pointycastle/export.dart' as pc;

class BackupService {
  static const String databaseFileName = 'vanshvriksh.db';
  static const String profilePhotosFolderName = 'profile_photos';
  static const String personMediaFolderName = 'person_media';
  static const String backupHistoryKey = 'backup_history';
  static const String lastBackupAtKey = 'last_backup_at';
  static const String lastBackupLocationKey = 'last_backup_location';
  static const String lastBackupFileKey = 'last_backup_file';

  Future<File> createBackup({String? password}) async {
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

    for (final file in archive.files) {
      final outputPath = p.join(appDir.path, file.name);

      if (file.isFile) {
        final outputFile = File(outputPath);
        if (!await outputFile.parent.exists()) {
          await outputFile.parent.create(recursive: true);
        }
        await outputFile.writeAsBytes(file.content as List<int>);
      } else {
        final outputDir = Directory(outputPath);
        if (!await outputDir.exists()) {
          await outputDir.create(recursive: true);
        }
      }
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

  Future<File> _createZipBackup() async {
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
        'vanshvriksh_backup_${now.year}_${_two(now.month)}_${_two(now.day)}_${_two(now.hour)}_${_two(now.minute)}.zip';
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
    final encryptedBytes = _encryptBytes(
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
    final encrypted = _isEncryptedFile(backupFile);
    if (!encrypted) {
      return backupFile.readAsBytes();
    }

    if (password == null || password.isEmpty) {
      throw Exception(
        'This backup is encrypted. Please enter the backup password.',
      );
    }

    return _decryptBytes(await backupFile.readAsBytes(), password);
  }

  bool _isEncryptedFile(File file) =>
      p.extension(file.path).toLowerCase() == '.enc';

  List<int> _encryptBytes(List<int> input, String password) {
    final key = encrypt.Key(_deriveKey(password));
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );
    final encrypted = encrypter.encryptBytes(Uint8List.fromList(input), iv: iv);
    return [...iv.bytes, ...encrypted.bytes];
  }

  List<int> _decryptBytes(List<int> input, String password) {
    if (input.length <= 16) {
      throw Exception('Invalid encrypted backup.');
    }

    final iv = encrypt.IV(Uint8List.fromList(input.sublist(0, 16)));
    final cipherBytes = input.sublist(16);

    // First try with the new PBKDF2 key
    try {
      final key = encrypt.Key(_deriveKey(password));
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );
      return encrypter.decryptBytes(
        encrypt.Encrypted(Uint8List.fromList(cipherBytes)),
        iv: iv,
      );
    } catch (e) {
      // If decryption fails (padding or MAC error), fallback to legacy SHA-256 key
      final legacyKey = encrypt.Key(_deriveLegacyKey(password));
      final encrypter = encrypt.Encrypter(
        encrypt.AES(legacyKey, mode: encrypt.AESMode.cbc),
      );
      return encrypter.decryptBytes(
        encrypt.Encrypted(Uint8List.fromList(cipherBytes)),
        iv: iv,
      );
    }
  }

  Uint8List _deriveKey(String password) {
    // PBKDF2 with 100,000 iterations for secure key derivation
    final salt = utf8.encode('vanshvriksh_backup_salt');
    final derivator = pc.KeyDerivator('SHA-256/HMAC/PBKDF2');
    derivator.init(pc.Pbkdf2Parameters(Uint8List.fromList(salt), 100000, 32));
    return derivator.process(Uint8List.fromList(utf8.encode(password)));
  }

  Uint8List _deriveLegacyKey(String password) {
    // Legacy insecure SHA-256 derivation used in v1 backups
    final digest = sha256.convert(utf8.encode(password));
    return Uint8List.fromList(digest.bytes);
  }

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
