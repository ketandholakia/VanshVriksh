import 'package:flutter_test/flutter_test.dart';
import 'package:vanshvriksh/features/gedcom/gedcom_parser.dart';

void main() {
  group('GedcomParser', () {
    test('parses basic INDI record', () {
      final lines = [
        '0 @I1@ INDI',
        '1 NAME John /Doe/',
        '2 GIVN John',
        '2 SURN Doe',
        '1 SEX M',
        '1 BIRT',
        '2 DATE 1 JAN 1900',
        '2 PLAC London, England',
      ];

      final nodes = GedcomParser.parseLines(lines);

      expect(nodes.length, 1);
      final root = nodes.first;
      expect(root.level, 0);
      expect(root.id, '@I1@');
      expect(root.tag, 'INDI');

      final nameNode = root.getChild('NAME');
      expect(nameNode?.value, 'John /Doe/');
      expect(nameNode?.getChild('GIVN')?.value, 'John');

      final sexNode = root.getChild('SEX');
      expect(sexNode?.value, 'M');

      final birtNode = root.getChild('BIRT');
      expect(birtNode?.getChild('DATE')?.value, '1 JAN 1900');
    });

    test('handles CONC and CONT tags', () {
      final lines = [
        '0 @I1@ INDI',
        '1 NOTE This is a long note',
        '2 CONT that continues on the next line',
        '2 CONC and has no space.',
      ];

      final nodes = GedcomParser.parseLines(lines);
      final noteNode = nodes.first.getChild('NOTE');

      expect(
        noteNode?.value,
        'This is a long note\nthat continues on the next lineand has no space.',
      );
    });
  });
}
