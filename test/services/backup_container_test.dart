// The backup container crypto and the restore path-traversal guard.
//
// The container is tested as pure byte transformations: round-trip, wrong
// password rejection, tamper detection, and backward compatibility with both
// historical formats.

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pointycastle/export.dart' as pc;

import 'package:vanshvriksh/services/backup_container.dart';
import 'package:vanshvriksh/services/backup_service.dart';

void main() {
  group('BackupContainerCodec', () {
    test('round-trips the plaintext', () {
      final plaintext = utf8.encode('zip bytes would go here — 123');
      final sealed = BackupContainerCodec.encrypt(plaintext, 'correct horse');

      expect(BackupContainerCodec.hasMagic(sealed), isTrue);
      final opened = BackupContainerCodec.decrypt(sealed, 'correct horse');
      expect(opened, plaintext);
    });

    test('uses a fresh salt per call', () {
      final plaintext = utf8.encode('same input');
      final first = BackupContainerCodec.encrypt(plaintext, 'pw');
      final second = BackupContainerCodec.encrypt(plaintext, 'pw');
      expect(first, isNot(second));
    });

    test('rejects a wrong password before touching the ciphertext', () {
      final sealed = BackupContainerCodec.encrypt(
        utf8.encode('secret'),
        'right password',
      );
      expect(
        () => BackupContainerCodec.decrypt(sealed, 'wrong password'),
        throwsStateError,
      );
    });

    test('detects tampering with the ciphertext', () {
      final sealed = BackupContainerCodec.encrypt(utf8.encode('secret'), 'pw');
      final tampered = Uint8List.fromList(sealed);
      tampered[tampered.length - 1] ^= 0x01;

      expect(
        () => BackupContainerCodec.decrypt(tampered, 'pw'),
        throwsStateError,
      );
    });

    test('reads the historical PBKDF2-with-static-salt format', () {
      // Reproduce the previous container: iv(16) + AES-CBC ciphertext with a
      // PBKDF2 key over the hard-coded salt.
      final plaintext = Uint8List.fromList(utf8.encode('old backup bytes'));
      final iv = encrypt.IV.fromSecureRandom(16);
      final key = encrypt.Key(
        _pbkdf2(
          'old password',
          utf8.encode('vanshvriksh_backup_salt'),
          100000,
          32,
        ),
      );
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );
      final legacy = [
        ...iv.bytes,
        ...encrypter.encryptBytes(plaintext, iv: iv).bytes,
      ];

      final opened = BackupContainerCodec.decrypt(legacy, 'old password');
      expect(opened, plaintext);
    });

    test('reads the v1 bare-SHA-256 key format', () {
      final plaintext = Uint8List.fromList(utf8.encode('v1 backup'));
      final iv = encrypt.IV.fromSecureRandom(16);
      final digest = sha256.convert(utf8.encode('v1 password'));
      final key = encrypt.Key(Uint8List.fromList(digest.bytes));
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );
      final legacy = [
        ...iv.bytes,
        ...encrypter.encryptBytes(plaintext, iv: iv).bytes,
      ];

      final opened = BackupContainerCodec.decrypt(legacy, 'v1 password');
      expect(opened, plaintext);
    });

    test('refuses a legacy file with no working key', () {
      final legacy = Uint8List.fromList([
        ...List<int>.filled(16, 0),
        ...List<int>.filled(32, 1),
      ]);
      expect(
        () => BackupContainerCodec.decrypt(legacy, 'anything'),
        throwsStateError,
      );
    });
  });

  group('restore path traversal guard', () {
    const root = '/data/user/0/app/files';
    // The guard joins with the host path package, so expectations are built
    // the same way to stay platform-neutral in the test suite.
    String inside(String relative) => p.joinAll([root, ...relative.split('/')]);

    test('accepts ordinary relative entries', () {
      expect(
        BackupService.safeRestoreDestination(root, 'vanshvriksh.db'),
        inside('vanshvriksh.db'),
      );
      expect(
        BackupService.safeRestoreDestination(root, 'profile_photos/p.jpg'),
        inside('profile_photos/p.jpg'),
      );
      expect(
        BackupService.safeRestoreDestination(root, 'person_media/./x/y.pdf'),
        inside('person_media/x/y.pdf'),
      );
    });

    test('refuses .. traversal', () {
      expect(
        () => BackupService.safeRestoreDestination(root, '../evil.txt'),
        throwsFormatException,
      );
      expect(
        () => BackupService.safeRestoreDestination(
          root,
          'profile_photos/../../../evil.txt',
        ),
        throwsFormatException,
      );
    });

    test('refuses absolute and drive-letter paths', () {
      expect(
        () => BackupService.safeRestoreDestination(root, '/etc/passwd'),
        throwsFormatException,
      );
      expect(
        () => BackupService.safeRestoreDestination(root, r'C:\evil.txt'),
        throwsFormatException,
      );
    });

    test('normalises backslash separators without letting them escape', () {
      // Backslashes are separators in some zip writers; treated as such, but
      // a disguised traversal is still refused.
      expect(
        BackupService.safeRestoreDestination(root, r'profile_photos\a.jpg'),
        inside('profile_photos/a.jpg'),
      );
      expect(
        () => BackupService.safeRestoreDestination(root, r'..\..\evil'),
        throwsFormatException,
      );
    });
  });
}

Uint8List _pbkdf2(String password, List<int> salt, int iterations, int length) {
  final derivator = pc.KeyDerivator('SHA-256/HMAC/PBKDF2');
  derivator.init(
    pc.Pbkdf2Parameters(Uint8List.fromList(salt), iterations, length),
  );
  return derivator.process(Uint8List.fromList(utf8.encode(password)));
}
