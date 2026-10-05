import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/database/app_database.dart';
import 'gedcom_parser.dart';

class GedcomDateResult {
  GedcomDateResult({this.date, this.qualifier, this.raw});
  final DateTime? date;
  final String? qualifier;
  final String? raw;
}

/// What one import did, so the UI can report it honestly.
class GedcomImportResult {
  const GedcomImportResult({
    required this.people,
    required this.families,
    required this.childLinks,
    this.warnings = const [],
  });

  final int people;
  final int families;
  final int childLinks;
  final List<String> warnings;

  bool get hasWarnings => warnings.isNotEmpty;
}

class GedcomImporter {
  GedcomImporter(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  /// Imports [nodes] into [treeId] in one transaction.
  ///
  /// Throws [FormatException] when the file contains no INDI/FAM records at
  /// all — that means the file is not a GEDCOM file (or is unreadable), and
  /// reporting success would be a lie. Records with a malformed or missing
  /// cross-reference id are skipped and collected into the result's warnings
  /// instead of crashing the import.
  Future<GedcomImportResult> importGedcom(
    List<GedcomNode> nodes,
    String treeId,
  ) async {
    final warnings = <String>[];

    final personsToInsert = <GenealogyPersonsCompanion>[];
    final familiesToInsert = <FamiliesV2Companion>[];
    final childrenToInsert = <FamilyChildrenV2Companion>[];

    // Maps GEDCOM ID (e.g. @I1@) to database UUID. Local to one import: an
    // importer instance reused for a second file must not see the first
    // file's ids.
    final personIdMap = <String, String>{};
    final familyIdMap = <String, String>{};

    // First pass: Create IDs for everyone and every family
    for (final node in nodes) {
      if (node.tag == 'INDI') {
        if (node.id == null) {
          warnings.add(
            'Skipped an individual record with no cross-reference id.',
          );
        } else {
          personIdMap[node.id!] = _uuid.v4();
        }
      } else if (node.tag == 'FAM') {
        if (node.id == null) {
          warnings.add('Skipped a family record with no cross-reference id.');
        } else {
          familyIdMap[node.id!] = _uuid.v4();
        }
      }
    }

    if (personIdMap.isEmpty && familyIdMap.isEmpty) {
      throw const FormatException(
        'No GEDCOM records (INDI/FAM) were found in this file. It may not be '
        'a GEDCOM file, or it uses an encoding this importer cannot read.',
      );
    }

    // Second pass: Parse INDI (Persons)
    for (final node in nodes.where((n) => n.tag == 'INDI')) {
      final dbId = node.id == null ? null : personIdMap[node.id!];
      if (dbId == null) continue;

      final nameNode = node.getChild('NAME');
      String firstName = '';
      String? lastName;
      String? suffix;

      if (nameNode != null) {
        final rawName = nameNode.value ?? '';
        final parts = rawName.split('/');
        firstName = parts.isNotEmpty ? parts[0].trim() : '';
        if (parts.length > 1) lastName = parts[1].trim();
        if (parts.length > 2) suffix = parts[2].trim();

        // Check for GIVN / SURN under NAME
        final givn = nameNode.getChild('GIVN')?.value;
        final surn = nameNode.getChild('SURN')?.value;
        if (givn != null) firstName = givn;
        if (surn != null) lastName = surn;
      }

      final sexNode = node.getChild('SEX');
      String gender = 'unknown';
      if (sexNode?.value == 'M') gender = 'male';
      if (sexNode?.value == 'F') gender = 'female';

      final birtNode = node.getChild('BIRT');
      final birtDate = _parseDate(birtNode?.getChild('DATE')?.value);
      final birtPlace = birtNode?.getChild('PLAC')?.value;

      final deatNode = node.getChild('DEAT');
      final deatDate = _parseDate(deatNode?.getChild('DATE')?.value);
      final deatPlace = deatNode?.getChild('PLAC')?.value;

      final noteNode = node.getChild('NOTE');

      personsToInsert.add(
        GenealogyPersonsCompanion.insert(
          id: dbId,
          uuid: dbId,
          treeId: treeId,
          firstName: firstName,
          lastName: Value(lastName),
          suffix: Value(suffix),
          gender: gender,
          birthDate: Value(birtDate.date),
          birthDateQualifier: Value(birtDate.qualifier),
          birthPlace: Value(birtPlace),
          deathDate: Value(deatDate.date),
          deathDateQualifier: Value(deatDate.qualifier),
          deathPlace: Value(deatPlace),
          notes: Value(noteNode?.value),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }

    // Third pass: Parse FAM (Families and relationships)
    for (final node in nodes.where((n) => n.tag == 'FAM')) {
      final dbFamilyId = node.id == null ? null : familyIdMap[node.id!];
      if (dbFamilyId == null) continue;

      final husbId = node.getChild('HUSB')?.value;
      final wifeId = node.getChild('WIFE')?.value;

      final marrNode = node.getChild('MARR');
      final marrDate = _parseDate(marrNode?.getChild('DATE')?.value);
      final marrPlace = marrNode?.getChild('PLAC')?.value;

      String? husbDbId;
      String? wifeDbId;
      if (husbId != null) {
        husbDbId = personIdMap[husbId];
        if (husbDbId == null) {
          warnings.add('Family ${node.id} references unknown husband $husbId.');
        }
      }
      if (wifeId != null) {
        wifeDbId = personIdMap[wifeId];
        if (wifeDbId == null) {
          warnings.add('Family ${node.id} references unknown wife $wifeId.');
        }
      }

      familiesToInsert.add(
        FamiliesV2Companion.insert(
          id: dbFamilyId,
          treeId: treeId,
          husbandId: Value(husbDbId),
          wifeId: Value(wifeDbId),
          marriageDate: Value(marrDate.date),
          marriageDateQualifier: Value(marrDate.qualifier),
          marriagePlace: Value(marrPlace),
        ),
      );

      final children = node.getChildren('CHIL');
      for (final childNode in children) {
        final childId = childNode.value;
        if (childId == null) continue;
        final childDbId = personIdMap[childId];
        if (childDbId == null) {
          warnings.add('Family ${node.id} references unknown child $childId.');
          continue;
        }
        childrenToInsert.add(
          FamilyChildrenV2Companion.insert(
            id: _uuid.v4(),
            familyId: dbFamilyId,
            childId: childDbId,
          ),
        );
      }
    }

    // Insert everything in a transaction
    await _db.transaction(() async {
      await _db.batch((batch) {
        batch.insertAll(
          _db.genealogyPersons,
          personsToInsert,
          mode: InsertMode.insertOrIgnore,
        );
        batch.insertAll(
          _db.familiesV2,
          familiesToInsert,
          mode: InsertMode.insertOrIgnore,
        );
        batch.insertAll(
          _db.familyChildrenV2,
          childrenToInsert,
          mode: InsertMode.insertOrIgnore,
        );
      });
    });

    return GedcomImportResult(
      people: personsToInsert.length,
      families: familiesToInsert.length,
      childLinks: childrenToInsert.length,
      warnings: warnings,
    );
  }

  GedcomDateResult _parseDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return GedcomDateResult();

    final parts = rawDate.trim().toUpperCase().split(' ');
    String? qualifier;

    final qualifiers = ['ABT', 'CAL', 'EST', 'BEF', 'AFT', 'BET', 'AND'];
    if (qualifiers.contains(parts[0])) {
      qualifier = parts[0];
      parts.removeAt(0);
    }

    if (parts.isEmpty) {
      return GedcomDateResult(raw: rawDate, qualifier: qualifier);
    }

    // Try parsing basic "DD MMM YYYY" or "MMM YYYY" or "YYYY"
    int? year;
    int? month;
    int? day;

    final months = {
      'JAN': 1,
      'FEB': 2,
      'MAR': 3,
      'APR': 4,
      'MAY': 5,
      'JUN': 6,
      'JUL': 7,
      'AUG': 8,
      'SEP': 9,
      'OCT': 10,
      'NOV': 11,
      'DEC': 12,
    };

    for (final p in parts) {
      if (months.containsKey(p)) {
        month = months[p];
      } else if (int.tryParse(p) != null) {
        final val = int.parse(p);
        if (val > 31) {
          year = val;
        } else {
          day = val;
        }
      }
    }

    DateTime? date;
    if (year != null) {
      date = DateTime(year, month ?? 1, day ?? 1);
    }

    return GedcomDateResult(date: date, qualifier: qualifier, raw: rawDate);
  }
}
