import 'dart:convert';
import 'dart:io';

/// Decodes GEDCOM bytes to lines, honouring the encodings real-world files
/// actually use.
///
/// Detection order:
///  1. Byte-order marks: UTF-8, UTF-16 LE/BE.
///  2. The `HEAD → CHAR` record: `UTF-8`, `UNICODE`, `ANSEL`, `ANSI`,
///     `IBMPC`, `ASCII`, `ISO-8859-1`, `LATIN1` and variants.
///  3. Otherwise: UTF-8 if the bytes are valid UTF-8, else Latin-1 (which
///     never fails).
///
/// ANSEL (the classic GEDCOM 5.5.1 charset) is decoded best-effort as Latin-1:
/// the common letters land correctly, a few extended glyphs may look off. The
/// decoded result says which encoding was applied so callers can surface it.
class GedcomDecoding {
  static List<String> decodeLinesSync(List<int> bytes) {
    final decoded = decodeToString(bytes);
    return const LineSplitter().convert(decoded.text);
  }

  static Future<List<String>> decodeLines(File file) async {
    final bytes = await file.readAsBytes();
    return decodeLinesSync(bytes);
  }

  /// Decodes [bytes] and reports which encoding won.
  static ({String text, String encoding}) decodeToString(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return (
        text: utf8.decode(bytes.sublist(3), allowMalformed: true),
        encoding: 'UTF-8 (BOM)',
      );
    }
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
      return (
        text: _decodeUtf16(bytes.sublist(2), littleEndian: true),
        encoding: 'UTF-16LE (BOM)',
      );
    }
    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      return (
        text: _decodeUtf16(bytes.sublist(2), littleEndian: false),
        encoding: 'UTF-16BE (BOM)',
      );
    }

    // Latin-1 maps every byte to one code unit, so it is a lossless probe
    // for reading the CHAR line.
    final latin1Probe = latin1.decode(bytes);

    final declared = _declaredEncoding(latin1Probe);
    if (declared != null) {
      switch (declared) {
        case 'UTF-8':
        case 'UNICODE':
          return (
            text: utf8.decode(bytes, allowMalformed: true),
            encoding: 'UTF-8 (CHAR)',
          );
        case 'ANSEL':
        case 'ANSI':
        case 'IBMPC':
        case 'ASCII':
        case 'ISO-8859-1':
        case 'LATIN1':
          return (text: latin1Probe, encoding: declared);
      }
    }

    try {
      final strict = utf8.decode(bytes);
      return (text: strict, encoding: 'UTF-8');
    } on FormatException {
      return (text: latin1Probe, encoding: 'Latin-1 (fallback)');
    }
  }

  /// The value of the `CHAR` line in the header, normalised, or null.
  static String? _declaredEncoding(String latin1Text) {
    for (final rawLine in const LineSplitter().convert(latin1Text)) {
      final line = rawLine.trim();
      // Matches both `1 CHAR UTF-8` and `1 CHAR <xref> CHAR UTF-8` shapes.
      final match = RegExp(
        r'^\d+\s+(?:@\S+@\s+)?CHAR\s+(.+)$',
        caseSensitive: false,
      ).firstMatch(line);
      if (match == null) continue;

      final value = match.group(1)!.trim().toUpperCase();
      if (value.contains('ANSEL')) return 'ANSEL';
      if (value.contains('UTF-8') || value.contains('UTF8')) return 'UTF-8';
      if (value.contains('UNICODE')) return 'UNICODE';
      if (value.contains('IBM')) return 'IBMPC';
      if (value.contains('8859') || value.contains('LATIN')) return 'LATIN1';
      if (value.contains('ANSI')) return 'ANSI';
      if (value.contains('ASCII')) return 'ASCII';
      return value;
    }
    return null;
  }

  /// Dart strings are UTF-16 internally, so the code units map directly.
  static String _decodeUtf16(List<int> bytes, {required bool littleEndian}) {
    final units = <int>[];
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      units.add(
        littleEndian
            ? bytes[i] | (bytes[i + 1] << 8)
            : (bytes[i] << 8) | bytes[i + 1],
      );
    }
    return String.fromCharCodes(units);
  }
}
