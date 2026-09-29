import '../../data/database/app_database.dart';

class BasicFamilyTreeData {
  const BasicFamilyTreeData({
    required this.rootPerson,
    required this.parents,
    required this.spouses,
    required this.children,
  });

  final GenealogyPerson rootPerson;
  final List<GenealogyPerson> parents;
  final List<GenealogyPerson> spouses;
  final List<GenealogyPerson> children;
}

class AncestryFanChartData {
  const AncestryFanChartData({
    required this.rootPerson,
    required this.generations,
  });

  final GenealogyPerson rootPerson;
  final List<List<AncestrySlot>> generations;
}

class AncestrySlot {
  const AncestrySlot({
    required this.generation,
    required this.childId,
    required this.relationToChild,
    this.person,
  });

  final int generation;
  final String? childId;
  final String? relationToChild;
  final GenealogyPerson? person;

  bool get isRoot => generation == 0;
  bool get isHint =>
      person == null && childId != null && relationToChild != null;
  bool get isAncestor => person != null;
}

class MultiGenFamilyTreeData {
  const MultiGenFamilyTreeData({
    required this.rootPerson,
    required this.nodes,
    required this.couples,
  });

  final GenealogyPerson rootPerson;
  final Map<String, GenealogyPerson> nodes;

  /// The unions among [nodes]: a couple and the children of that union.
  ///
  /// A tree layout is driven by these rather than by pairwise edges, because
  /// spouses belong on the same generation row and their shared children hang
  /// below the union, not below one partner.
  final List<TreeCouple> couples;
}

class TreeCouple {
  const TreeCouple({
    required this.familyId,
    required this.partnerIds,
    required this.childIds,
  });

  final String familyId;

  /// The partners of this union that are present in the tree, in slot order.
  final List<String> partnerIds;

  /// The children of this union that are present in the tree, oldest first.
  final List<String> childIds;
}
