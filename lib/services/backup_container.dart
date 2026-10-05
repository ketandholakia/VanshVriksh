import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as aes;
import 'package:pointycastle/export.dart' as pc;

/// The `VVBK1` encryption container for VanshVriksh backups.
///
/// ```text
/// 'VVBK1' | salt (16) | iterations (u32 BE) | iv (16) | hmac (32) | AES-256-CBC ciphertext
/// ```
///
/// The keys come from PBKDF2-HMAC-SHA256 over the password with a **random
/// per-backup salt**, split into an encryption key and an HMAC key. The HMAC
/// (encrypt-then-MAC) makes wrong passwords and tampering detectable before
/// any ciphertext is touched.
///
/// [decrypt] also reads the two historical formats, kept readable:
///  * iv-prefixed AES-CBC with a PBKDF2 key over a hard-coded salt;
///  * v1: iv-prefixed AES-CBC with a bare SHA-256 of the password.
class BackupContainerCodec {
  static const int _saltLength = 16;
  static const int _ivLength = 16;
  static const int _hmacLength = 32;
  static const int _pbkdf2Iterations = 100000;
  static final List<int> _magic = utf8.encode('VVBK1');

  static bool hasMagic(List<int> bytes) {
    if (bytes.length < _magic.length) return false;
    for (var i = 0; i < _magic.length; i++) {
      if (bytes[i] != _magic[i]) return false;
    }
    return true;
  }

  static List<int> encrypt(List<int> input, String password) {
    final random = Random.secure();
    final salt = Uint8List.fromList(
      List<int>.generate(_saltLength, (_) => random.nextInt(256)),
    );
    final iv = Uint8List.fromList(
      List<int>.generate(_ivLength, (_) => random.nextInt(256)),
    );

    final keys = _deriveKeyPair(password, salt, _pbkdf2Iterations);
    final encrypter = aes.Encrypter(
      aes.AES(aes.Key(keys.encryptionKey), mode: aes.AESMode.cbc),
    );
    final encrypted = encrypter.encryptBytes(
      Uint8List.fromList(input),
      iv: aes.IV(iv),
    );

    final macInput = [
      ...salt,
      ..._u32be(_pbkdf2Iterations),
      ...iv,
      ...encrypted.bytes,
    ];
    final mac = Hmac(sha256, keys.macKey).convert(macInput).bytes;

    return [
      ..._magic,
      ...salt,
      ..._u32be(_pbkdf2Iterations),
      ...iv,
      ...mac,
      ...encrypted.bytes,
    ];
  }

  static List<int> decrypt(List<int> input, String password) {
    if (hasMagic(input)) {
      return _decryptContainer(input, password);
    }
    return _decryptLegacy(input, password);
  }

  static List<int> _decryptContainer(List<int> input, String password) {
    final saltStart = _magic.length;
    final iterationsStart = saltStart + _saltLength;
    final ivStart = iterationsStart + 4;
    final macStart = ivStart + _ivLength;
    final cipherStart = macStart + _hmacLength;
    if (input.length <= cipherStart || (input.length - cipherStart) % 16 != 0) {
      throw const FormatException('Invalid encrypted backup.');
    }

    final salt = Uint8List.fromList(input.sublist(saltStart, iterationsStart));
    final iterations = _u32beValue(input.sublist(iterationsStart, ivStart));
    final iv = Uint8List.fromList(input.sublist(ivStart, macStart));
    final expectedMac = input.sublist(macStart, cipherStart);
    final cipherBytes = input.sublist(cipherStart);

    final keys = _deriveKeyPair(password, salt, iterations);
    final actualMac = Hmac(
      sha256,
      keys.macKey,
    ).convert([...salt, ..._u32be(iterations), ...iv, ...cipherBytes]).bytes;

    if (!_constantTimeEquals(expectedMac, actualMac)) {
      throw StateError(
        'Unable to decrypt this backup: the password is wrong or the file '
        'was modified.',
      );
    }

    final encrypter = aes.Encrypter(
      aes.AES(aes.Key(keys.encryptionKey), mode: aes.AESMode.cbc),
    );
    return encrypter.decryptBytes(
      aes.Encrypted(Uint8List.fromList(cipherBytes)),
      iv: aes.IV(iv),
    );
  }

  static List<int> _decryptLegacy(List<int> input, String password) {
    if (input.length <= 16) {
      throw const FormatException('Invalid encrypted backup.');
    }

    final iv = aes.IV(Uint8List.fromList(input.sublist(0, 16)));
    final cipherBytes = input.sublist(16);

    final attempts = <aes.Key Function()>[
      // PBKDF2 over the historical hard-coded salt.
      () => aes.Key(
        _pbkdf2(
          password,
          Uint8List.fromList(utf8.encode('vanshvriksh_backup_salt')),
          100000,
          32,
        ),
      ),
      // v1: a bare SHA-256 of the password.
      () {
        final digest = sha256.convert(utf8.encode(password));
        return aes.Key(Uint8List.fromList(digest.bytes));
      },
    ];
    for (final attempt in attempts) {
      try {
        final encrypter = aes.Encrypter(
          aes.AES(attempt(), mode: aes.AESMode.cbc),
        );
        return encrypter.decryptBytes(
          aes.Encrypted(Uint8List.fromList(cipherBytes)),
          iv: iv,
        );
      } catch (_) {
        // Try the next legacy derivation.
      }
    }
    throw StateError(
      'Unable to decrypt this backup. The password may be wrong, or the '
      'file is not a VanshVriksh backup.',
    );
  }

  static ({Uint8List encryptionKey, Uint8List macKey}) _deriveKeyPair(
    String password,
    Uint8List salt,
    int iterations,
  ) {
    final derived = _pbkdf2(password, salt, iterations, 64);
    return (
      encryptionKey: Uint8List.sublistView(derived, 0, 32),
      macKey: Uint8List.sublistView(derived, 32, 64),
    );
  }

  static Uint8List _pbkdf2(
    String password,
    Uint8List salt,
    int iterations,
    int length,
  ) {
    final derivator = pc.KeyDerivator('SHA-256/HMAC/PBKDF2');
    derivator.init(pc.Pbkdf2Parameters(salt, iterations, length));
    return derivator.process(Uint8List.fromList(utf8.encode(password)));
  }

  static Uint8List _u32be(int value) => Uint8List(4)
    ..[0] = (value >> 24) & 0xFF
    ..[1] = (value >> 16) & 0xFF
    ..[2] = (value >> 8) & 0xFF
    ..[3] = value & 0xFF;

  static int _u32beValue(List<int> bytes) =>
      (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
