import '../../data/database/app_database.dart';
import '../../data/models/family_graph.dart';
import '../../data/repositories/relationship_repository.dart';

/// Exports a tree as GEDCOM 5.5.1 (LINEAGE-LINKED, UTF-8).
///
/// The unit of export is the whole tree: every live person becomes an INDI
/// record, every live partnership a FAM record, and the FAMC/FAMS links
/// reconstruct the parentage structure any standard reader understands.
///
/// Mapping decisions worth knowing:
///  * people are numbered `@I1@…` and families `@F1@…` in a deterministic
///    order (people by name then id, families by id), so the same data always
///    produces byte-identical output;
///  * `1 _UID` carries the person's stable [GenealogyPersons.uuid], which
///    survives database recreation and merges — round-trips through this app
///    or matching in another tool can key on it;
///  * dates render `DD MMM YYYY`; a stored date of 1 January renders as the
///    bare year, because the model does not track date precision and a
///    year-only value re-imports to the same DateTime;
///  * the stored qualifier (ABT, CAL, EST, BEF, AFT, BET) prefixes the date;
///  * `marriedSurname` / `birthSurname` become secondary `NAME` records with
///    `TYPE married` / `TYPE birth` when they differ from the primary surname;
///  * occupation and religion export as the standard OCCU / RELI tags;
///  * multi-line notes fold into `CONT` continuation lines.
///
/// What is deliberately not exported yet: the free-form `events` and
/// `research_notes` tables (the importer has no matching tags to read back),
/// media, and custom event types. The `isPrivate` flag is not a filter — the
/// user explicitly asks for the file, so everything in the tree goes into it.
class GedcomExporter {
  const GedcomExporter();

  static const String _appName = 'VANSHVRIKSH';
  static const String _appVersion = '1.0.0';
  static const List<String> _months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  static const Set<String> _knownQualifiers = {
    'ABT',
    'CAL',
    'EST',
    'BEF',
    'AFT',
    'BET',
  };

  /// Loads [treeId] and returns the GEDCOM document.
  Future<String> exportTree(AppDatabase db, String treeId) async {
    final graph = await RelationshipRepository(db).loadFamilyGraph(treeId);
    return exportGraph(graph);
  }

  /// Formats the live family structure of [graph] as GEDCOM text.
  String exportGraph(FamilyGraph graph) {
    final people = graph.people.values.toList()..sort(_byName);
    final personXref = <String, String>{
      for (var i = 0; i < people.length; i++) people[i].id: '@I${i + 1}@',
    };

    final groupings = graph.familiesAmong(graph.people.keys.toSet()).toList()
      ..sort((a, b) => a.familyId.compareTo(b.familyId));
    final familyXref = <String, String>{
      for (var i = 0; i < groupings.length; i++)
        groupings[i].familyId: '@F${i + 1}@',
    };

    // Per-person union membership, resolved once instead of per person.
    final familiesAsChild = <String, List<FamilyGrouping>>{};
    final familiesAsPartner = <String, List<FamilyGrouping>>{};
    for (final grouping in groupings) {
      for (final childId in grouping.childIds) {
        familiesAsChild.putIfAbsent(childId, () => []).add(grouping);
      }
      for (final partnerId in grouping.partnerIds) {
        familiesAsPartner.putIfAbsent(partnerId, () => []).add(grouping);
      }
    }

    final lines = <String>[];
    _addHead(lines, 'vanshvriksh_export.ged');
    for (final person in people) {
      _addPerson(
        lines,
        person,
        graph,
        personXref,
        familyXref,
        familiesAsChild[person.id] ?? const [],
        familiesAsPartner[person.id] ?? const [],
      );
    }
    for (final grouping in groupings) {
      final family = graph.familyById(grouping.familyId);
      if (family == null) continue;
      _addFamily(lines, grouping, family, personXref, familyXref);
    }
    lines.add('0 TRLR');

    return '${lines.join('\r\n')}\r\n';
  }

  void _addHead(List<String> lines, String fileName) {
    final now = DateTime.now();
    lines
      ..add('0 HEAD')
      ..add('1 SOUR $_appName')
      ..add('2 NAME VanshVriksh')
      ..add('2 VERS $_appVersion')
      ..add('1 GEDC')
      ..add('2 VERS 5.5.1')
      ..add('2 FORM LINEAGE-LINKED')
      ..add('1 CHAR UTF-8')
      ..add('1 DATE ${_dayText(now.day)} ${_months[now.month - 1]} ${now.year}')
      ..add('1 FILE $fileName');
  }

  void _addPerson(
    List<String> lines,
    GenealogyPerson person,
    FamilyGraph graph,
    Map<String, String> personXref,
    Map<String, String> familyXref,
    List<FamilyGrouping> asChild,
    List<FamilyGrouping> asPartner,
  ) {
    lines.add('0 ${personXref[person.id]} INDI');

    // 1 NAME <given> /<surname>/ <suffix>
    final given = [
      ?_nonEmpty(person.firstName),
      ?_nonEmpty(person.middleName),
    ].join(' ');
    final surname = _nonEmpty(person.lastName);
    final suffix = _nonEmpty(person.suffix);
    final nameValue = [
      if (given.isNotEmpty) given,
      if (surname != null) '/$surname/',
      ?suffix,
    ].join(' ');
    lines.add('1 NAME $nameValue');
    if (given.isNotEmpty) lines.add('2 GIVN $given');
    if (surname != null) lines.add('2 SURN $surname');
    final prefix = _nonEmpty(person.prefix);
    if (prefix != null) lines.add('2 NPFX $prefix');
    if (suffix != null) lines.add('2 NSFX $suffix');
    final nickname = _nonEmpty(person.nickname);
    if (nickname != null) lines.add('1 NICK $nickname');

    // Secondary surnames, when they differ from the primary one.
    _addSecondaryName(lines, given, person.marriedSurname, surname, 'married');
    _addSecondaryName(lines, given, person.birthSurname, surname, 'birth');

    lines.add('1 SEX ${_sexCode(person.gender)}');
    final uid = _nonEmpty(person.uuid);
    if (uid != null) lines.add('1 _UID $uid');

    _addEvent(
      lines,
      'BIRT',
      person.birthDate,
      person.birthDateQualifier,
      person.birthPlace,
    );
    _addEvent(
      lines,
      'DEAT',
      person.deathDate,
      person.deathDateQualifier,
      person.deathPlace,
    );

    final occupation = _nonEmpty(person.occupation);
    if (occupation != null) lines.add('1 OCCU $occupation');
    final religion = _nonEmpty(person.religion);
    if (religion != null) lines.add('1 RELI $religion');

    for (final grouping in asChild) {
      final xref = familyXref[grouping.familyId];
      if (xref != null) lines.add('1 FAMC $xref');
    }
    for (final grouping in asPartner) {
      final xref = familyXref[grouping.familyId];
      if (xref != null) lines.add('1 FAMS $xref');
    }

    _addNote(lines, 1, person.notes);
  }

  void _addSecondaryName(
    List<String> lines,
    String given,
    String? altSurname,
    String? primarySurname,
    String type,
  ) {
    final alt = _nonEmpty(altSurname);
    if (alt == null || alt == primarySurname || given.isEmpty) return;
    lines
      ..add('1 NAME $given /$alt/')
      ..add('2 TYPE $type')
      ..add('2 SURN $alt');
  }

  void _addFamily(
    List<String> lines,
    FamilyGrouping grouping,
    FamiliesV2Data family,
    Map<String, String> personXref,
    Map<String, String> familyXref,
  ) {
    lines.add('0 ${familyXref[family.id]} FAM');
    for (final partnerId in grouping.partnerIds) {
      final xref = personXref[partnerId];
      if (xref == null) continue;
      lines.add('1 ${partnerId == family.husbandId ? 'HUSB' : 'WIFE'} $xref');
    }
    for (final childId in grouping.childIds) {
      final xref = personXref[childId];
      if (xref != null) lines.add('1 CHIL $xref');
    }
    _addEvent(
      lines,
      'MARR',
      family.marriageDate,
      family.marriageDateQualifier,
      family.marriagePlace,
    );
    _addNote(lines, 1, family.notes);
  }

  void _addEvent(
    List<String> lines,
    String tag,
    DateTime? date,
    String? qualifier,
    String? place,
  ) {
    if (date == null && _nonEmpty(place) == null) return;
    lines.add('1 $tag');
    final dateText = _formatGedcomDate(date, qualifier);
    if (dateText != null) lines.add('2 DATE $dateText');
    final placeText = _nonEmpty(place);
    if (placeText != null) lines.add('2 PLAC $placeText');
  }

  void _addNote(List<String> lines, int level, String? text) {
    if (text == null || text.trim().isEmpty) return;
    final parts = text.replaceAll('\r\n', '\n').split('\n');
    lines.add('$level NOTE ${parts.first}');
    for (final rest in parts.skip(1)) {
      lines.add('${level + 1} CONT $rest');
    }
  }

  /// `DD MMM YYYY`, collapsing 1 January to the bare year (the model does not
  /// track precision, and a bare year re-imports to the same DateTime).
  String? _formatGedcomDate(DateTime? date, String? qualifier) {
    if (date == null) return null;

    String dateText;
    if (date.day == 1 && date.month == 1) {
      dateText = '${date.year}';
    } else if (date.day == 1) {
      dateText = '${_months[date.month - 1]} ${date.year}';
    } else {
      dateText =
          '${_dayText(date.day)} ${_months[date.month - 1]} ${date.year}';
    }

    final q = (qualifier ?? '').trim().toUpperCase();
    return _knownQualifiers.contains(q) ? '$q $dateText' : dateText;
  }

  static String _sexCode(String gender) {
    final g = gender.trim().toLowerCase();
    if (g.startsWith('m')) return 'M';
    if (g.startsWith('f')) return 'F';
    return 'U';
  }

  static String _dayText(int day) => day.toString().padLeft(2, '0');

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  /// Last name, then first name, then id — a total, stable order.
  static int _byName(GenealogyPerson a, GenealogyPerson b) {
    var order = (a.lastName ?? '').toLowerCase().compareTo(
      (b.lastName ?? '').toLowerCase(),
    );
    if (order != 0) return order;
    order = a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase());
    if (order != 0) return order;
    return a.id.compareTo(b.id);
  }
}
