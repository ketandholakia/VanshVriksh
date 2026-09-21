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

class GedcomImporter {
  GedcomImporter(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  // Maps GEDCOM ID (e.g. @I1@) to database UUID
  final Map<String, String> _personIdMap = {};
  final Map<String, String> _familyIdMap = {};

  Future<void> importGedcom(List<GedcomNode> nodes, String treeId) async {
    final personsToInsert = <GenealogyPersonsCompanion>[];
    final familiesToInsert = <FamiliesV2Companion>[];
    final childrenToInsert = <FamilyChildrenV2Companion>[];

    // First pass: Create IDs for everyone and every family
    for (final node in nodes) {
      if (node.tag == 'INDI' && node.id != null) {
        _personIdMap[node.id!] = _uuid.v4();
      } else if (node.tag == 'FAM' && node.id != null) {
        _familyIdMap[node.id!] = _uuid.v4();
      }
    }

    // Second pass: Parse INDI (Persons)
    for (final node in nodes.where((n) => n.tag == 'INDI')) {
      final dbId = _personIdMap[node.id!];
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
      final dbFamilyId = _familyIdMap[node.id!];
      if (dbFamilyId == null) continue;

      final husbId = node.getChild('HUSB')?.value;
      final wifeId = node.getChild('WIFE')?.value;
      
      final marrNode = node.getChild('MARR');
      final marrDate = _parseDate(marrNode?.getChild('DATE')?.value);
      final marrPlace = marrNode?.getChild('PLAC')?.value;

      String? husbDbId;
      String? wifeDbId;
      if (husbId != null) husbDbId = _personIdMap[husbId];
      if (wifeId != null) wifeDbId = _personIdMap[wifeId];

      familiesToInsert.add(
        FamiliesV2Companion.insert(
          id: dbFamilyId,
          treeId: treeId,
          uuid: dbFamilyId,
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
        if (childId != null) {
          final childDbId = _personIdMap[childId];
          if (childDbId != null) {
            childrenToInsert.add(
              FamilyChildrenV2Companion.insert(
                id: _uuid.v4(),
                uuid: _uuid.v4(),
                familyId: dbFamilyId,
                childId: childDbId,
              ),
            );
          }
        }
      }
    }

    // Insert everything in a transaction
    await _db.transaction(() async {
      await _db.batch((batch) {
        batch.insertAll(_db.genealogyPersons, personsToInsert, mode: InsertMode.insertOrIgnore);
        batch.insertAll(_db.familiesV2, familiesToInsert, mode: InsertMode.insertOrIgnore);
        batch.insertAll(_db.familyChildrenV2, childrenToInsert, mode: InsertMode.insertOrIgnore);
      });
    });
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
    
    if (parts.isEmpty) return GedcomDateResult(raw: rawDate, qualifier: qualifier);

    // Try parsing basic "DD MMM YYYY" or "MMM YYYY" or "YYYY"
    int? year;
    int? month;
    int? day;

    final months = {
      'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4, 'MAY': 5, 'JUN': 6,
      'JUL': 7, 'AUG': 8, 'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12,
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
