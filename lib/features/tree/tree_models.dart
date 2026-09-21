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
  bool get isHint => person == null && childId != null && relationToChild != null;
  bool get isAncestor => person != null;
}

class MultiGenFamilyTreeData {
  const MultiGenFamilyTreeData({
    required this.rootPerson,
    required this.nodes,
    required this.edges,
  });

  final GenealogyPerson rootPerson;
  final Map<String, GenealogyPerson> nodes;
  final List<TreeEdge> edges;
}

class TreeEdge {
  const TreeEdge({
    required this.sourceId,
    required this.targetId,
    required this.relationType,
  });

  final String sourceId;
  final String targetId;
  final String relationType; // 'parent_child', 'spouse'
}
