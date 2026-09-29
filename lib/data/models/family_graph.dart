import '../database/app_database.dart';

/// An in-memory view of one tree's family structure.
///
/// Built from three queries — the tree's people, its partnerships and their child
/// links — so a caller can walk the family structure as often as it likes without
/// a database round trip per node. The tree and fan-chart views used to ask for
/// parents/spouses/children once per person, which cost several queries per node
/// on every rebuild.
///
/// Only live rows are included: this is the view the UI renders, so deleted
/// people, dissolved families and removed child links are absent by construction.
class FamilyGraph {
  FamilyGraph({
    required Map<String, GenealogyPerson> people,
    required List<FamiliesV2Data> families,
    required List<FamilyChildrenV2Data> childLinks,
  }) : people = Map.unmodifiable(people),
       _familiesById = {for (final family in families) family.id: family},
       _familiesByPartner = _indexFamiliesByPartner(families),
       _linksByFamily = _indexLinksByFamily(childLinks),
       _linksByChild = _indexLinksByChild(childLinks);

  /// Every person in the tree, by id.
  final Map<String, GenealogyPerson> people;

  final Map<String, FamiliesV2Data> _familiesById;
  final Map<String, List<FamiliesV2Data>> _familiesByPartner;
  final Map<String, List<FamilyChildrenV2Data>> _linksByFamily;
  final Map<String, List<FamilyChildrenV2Data>> _linksByChild;

  int get personCount => people.length;

  GenealogyPerson? person(String id) => people[id];

  bool contains(String id) => people.containsKey(id);

  /// The recorded parents of [personId], resolved to people.
  List<GenealogyPerson> parentsOf(String personId) {
    final result = <String, GenealogyPerson>{};
    for (final link in _linksByChild[personId] ?? const []) {
      for (final partnerId in partnerIdsOf(link.familyId)) {
        final parent = people[partnerId];
        if (parent != null) result[partnerId] = parent;
      }
    }
    return result.values.toList();
  }

  /// The recorded children of [personId], resolved to people.
  List<GenealogyPerson> childrenOf(String personId) {
    final result = <String, GenealogyPerson>{};
    for (final family in _familiesByPartner[personId] ?? const []) {
      for (final link in _linksByFamily[family.id] ?? const []) {
        final child = people[link.childId];
        if (child != null) result[child.id] = child;
      }
    }
    return result.values.toList();
  }

  /// The recorded partners of [personId], resolved to people.
  List<GenealogyPerson> spousesOf(String personId) {
    final result = <String, GenealogyPerson>{};
    for (final family in _familiesByPartner[personId] ?? const []) {
      for (final partnerId in partnerIdsOf(family.id)) {
        if (partnerId == personId) continue;
        final partner = people[partnerId];
        if (partner != null) result[partnerId] = partner;
      }
    }
    return result.values.toList();
  }

  /// The couples that involve at least one of [personIds], trimmed to the
  /// partners and children that are also in [personIds].
  ///
  /// Tree layouts need the family grouping itself ("these two partners and
  /// these children form one union"), not just pairwise parent/child lookups:
  /// spouses have to share a row, which no per-person relationship query can
  /// express. Children are ordered by birth order where recorded.
  List<FamilyGrouping> familiesAmong(Set<String> personIds) {
    final groupings = <FamilyGrouping>[];
    for (final family in _familiesById.values) {
      final partners = partnerIdsOf(
        family.id,
      ).where(personIds.contains).toList(growable: false);
      if (partners.isEmpty) continue;

      final links = [...?_linksByFamily[family.id]]
        ..sort((a, b) {
          final left = a.birthOrder;
          final right = b.birthOrder;
          if (left == null && right == null) return 0;
          if (left == null) return 1;
          if (right == null) return -1;
          return left.compareTo(right);
        });
      final children = [
        for (final link in links)
          if (personIds.contains(link.childId)) link.childId,
      ];

      // A lone partner with no visible children adds nothing; a couple without
      // children still needs to be grouped so the two cards sit side by side.
      if (partners.length < 2 && children.isEmpty) continue;

      groupings.add(
        FamilyGrouping(
          familyId: family.id,
          partnerIds: partners,
          childIds: children,
        ),
      );
    }
    return groupings;
  }

  /// The recorded partners of a family, in slot order.
  List<String> partnerIdsOf(String familyId) {
    final family = _familiesById[familyId];
    if (family == null) return const [];
    return [
      if (family.husbandId != null) family.husbandId!,
      if (family.wifeId != null) family.wifeId!,
    ];
  }

  static Map<String, List<FamiliesV2Data>> _indexFamiliesByPartner(
    List<FamiliesV2Data> families,
  ) {
    final index = <String, List<FamiliesV2Data>>{};
    for (final family in families) {
      for (final partnerId in [family.husbandId, family.wifeId]) {
        if (partnerId == null) continue;
        index.putIfAbsent(partnerId, () => []).add(family);
      }
    }
    return index;
  }

  static Map<String, List<FamilyChildrenV2Data>> _indexLinksByFamily(
    List<FamilyChildrenV2Data> links,
  ) {
    final index = <String, List<FamilyChildrenV2Data>>{};
    for (final link in links) {
      index.putIfAbsent(link.familyId, () => []).add(link);
    }
    return index;
  }

  static Map<String, List<FamilyChildrenV2Data>> _indexLinksByChild(
    List<FamilyChildrenV2Data> links,
  ) {
    final index = <String, List<FamilyChildrenV2Data>>{};
    for (final link in links) {
      index.putIfAbsent(link.childId, () => []).add(link);
    }
    return index;
  }
}

/// One couple (a `families_v2` row) reduced to the people the caller cares
/// about: the partners and children of that union that are in the visible set.
class FamilyGrouping {
  const FamilyGrouping({
    required this.familyId,
    required this.partnerIds,
    required this.childIds,
  });

  final String familyId;

  /// One or two partners, in husband/wife slot order.
  final List<String> partnerIds;

  /// Children of this union, oldest first where birth order is recorded.
  final List<String> childIds;
}
