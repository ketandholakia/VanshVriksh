// The GEDCOM byte decoder and parser edge cases.
//
// Real-world GEDCOM files arrive in UTF-8 (with or without BOM), UTF-16,
// Latin-1, or ANSEL declared in the HEAD/CHAR record. The parser must also
// survive malformed input: it skips what it cannot read instead of throwing,
// and it never crashes on records without cross-reference ids.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:vanshvriksh/features/gedcom/gedcom_decoder.dart';
import 'package:vanshvriksh/features/gedcom/gedcom_parser.dart';

void main() {
  group('GedcomDecoding', () {
    test('decodes plain UTF-8 without a BOM', () {
      const text = '0 HEAD\n1 CHAR UTF-8\n0 INDI\n1 NAME Adam /First/';
      final lines = GedcomDecoding.decodeLinesSync(utf8.encode(text));
      expect(lines, hasLength(4));
      expect(lines.last, contains('Adam'));
    });

    test('decodes a UTF-8 BOM file', () {
      const text = '0 HEAD\n1 NAME Åse /Nordström/';
      final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode(text)];
      final result = GedcomDecoding.decodeToString(bytes);
      expect(result.encoding, contains('UTF-8'));
      expect(result.text, contains('Åse'));
    });

    test('decodes a UTF-16LE BOM file', () {
      const text = '0 HEAD\n1 CHAR UNICODE\n0 INDI\n1 NAME Adam /First/';
      final body = utf8.encode(text).map((b) => b < 128 ? b : 0x3F).toList();
      final bytes = <int>[0xFF, 0xFE];
      for (final unit in body) {
        bytes
          ..add(unit)
          ..add(0);
      }
      final result = GedcomDecoding.decodeToString(bytes);
      expect(result.encoding, contains('UTF-16LE'));
      expect(result.text, contains('Adam'));
    });

    test('honours a CHAR UTF-8 declaration on a BOM-less file', () {
      const text = '0 HEAD\n1 CHAR UTF-8\n1 NAME Émile /Zola/';
      final result = GedcomDecoding.decodeToString(utf8.encode(text));
      expect(result.encoding, 'UTF-8 (CHAR)');
      expect(result.text, contains('Émile'));
    });

    test('falls back to Latin-1 for a CHAR ANSEL declaration', () {
      // 0xE9 in Latin-1 is é.
      const asciiHead = '0 HEAD\n1 CHAR ANSEL\n1 NAME ';
      final bytes = <int>[
        ...asciiHead.codeUnits,
        0xE9,
        ...'mile /Zola/'.codeUnits,
      ];
      final result = GedcomDecoding.decodeToString(bytes);
      expect(result.encoding, 'ANSEL');
      expect(result.text, contains('mile'));
    });

    test('falls back to Latin-1 when the bytes are not valid UTF-8', () {
      final bytes = <int>[
        ...'0 HEAD\n1 NAME '.codeUnits,
        0xE9,
        ...' /X/'.codeUnits,
      ];
      final result = GedcomDecoding.decodeToString(bytes);
      expect(result.encoding, contains('Latin-1'));
      expect(result.text, contains('é'));
    });
  });

  group('GedcomParser edge cases', () {
    test('skips lines it cannot read instead of throwing', () {
      final nodes = GedcomParser.parseLines(const [
        'this is not gedcom',
        '0 HEAD',
        '1 CHAR UTF-8',
      ]);
      expect(nodes, hasLength(1));
      expect(nodes.single.tag, 'HEAD');
    });

    test('survives a level-0 record with an xref but no tag', () {
      final nodes = GedcomParser.parseLines(const [
        '0 HEAD',
        '0 @I1@',
        '0 INDI @I2@',
      ]);
      expect(nodes.map((node) => node.tag), ['HEAD', 'INDI']);
    });

    test('returns nothing for a garbage file', () {
      final nodes = GedcomParser.parseLines(const [
        'PK\u0003\u0004 not a gedcom at all',
        'random text',
      ]);
      expect(nodes, isEmpty);
    });

    test('continuation lines fold into the parent value', () {
      final nodes = GedcomParser.parseLines(const [
        '0 INDI @I1@',
        '1 NOTE line one',
        '2 CONT line two',
        '2 CONC more',
      ]);
      expect(nodes.single.getChild('NOTE')!.value, 'line one\nline twomore');
    });
  });
}
