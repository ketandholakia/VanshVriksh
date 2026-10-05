import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/models/family_graph.dart';
import '../../data/providers/genealogy_repository_provider.dart';
import '../../data/providers/relationship_repository_provider.dart';
import '../people/people_providers.dart';
import '../settings/fan_chart_settings_provider.dart';
import 'tree_models.dart';

/// A person's direct line: everyone reachable by repeatedly asking "who are
/// this person's father and mother", plus the links themselves. Siblings,
/// aunts and uncles never enter.
class DirectLineData {
  const DirectLineData({
    required this.focusId,
    required this.people,
    required this.fatherOf,
    required this.motherOf,
  });

  final String focusId;
  final Map<String, GenealogyPerson> people;
  final Map<String, String?> fatherOf;
  final Map<String, String?> motherOf;

  bool get isTrivial => people.length <= 1;
}

/// A root person and everything that descends from them, organised as the
/// couples the drop-line layout renders.
class DescendantLineData {
  const DescendantLineData({
    required this.rootId,
    required this.people,
    required this.couples,
  });

  final String rootId;
  final Map<String, GenealogyPerson> people;
  final List<TreeCouple> couples;

  bool get isTrivial => couples.isEmpty;
}

/// Which parental line an ancestor walk follows.
enum AncestorLineage {
  /// Father and mother at every generation (pedigree, hourglass).
  both,

  /// Fathers only — the bow-tie's left wing: father, paternal grandfather, …
  paternal,

  /// Mothers only — the bow-tie's right wing: mother, maternal grandmother, …
  maternal,
}

/// Walks the direct ancestor line of [focusId] up to [maxGenerations].
///
/// Father/mother slots follow the fan chart's rule: a male-recorded parent
/// takes the father slot, a female-recorded one the mother slot, and unknown
/// genders fill whichever slot is open. [lineage] restricts the walk to one
/// parental line: every visited person still gets both slots recorded so
/// layouts can render partners, but the frontier follows only the chosen
/// parent edge.
DirectLineData walkAncestors(
  FamilyGraph graph,
  String focusId,
  int maxGenerations, {
  AncestorLineage lineage = AncestorLineage.both,
}) {
  final people = <String, GenealogyPerson>{focusId: graph.person(focusId)!};
  final fatherOf = <String, String?>{};
  final motherOf = <String, String?>{};

  var frontier = <String>[focusId];
  for (var generation = 1; generation <= maxGenerations; generation++) {
    if (frontier.isEmpty) break;
    final next = <String>[];
    for (final personId in frontier) {
      GenealogyPerson? father;
      GenealogyPerson? mother;
      for (final parent in graph.parentsOf(personId)) {
        if (parent.gender == 'male' && father == null) {
          father = parent;
        } else if (parent.gender == 'female' && mother == null) {
          mother = parent;
        } else if (father == null) {
          father = parent;
        } else {
          mother ??= parent;
        }
      }
      fatherOf[personId] = father?.id;
      motherOf[personId] = mother?.id;
      // A single-lineage walk follows only its own parent edge.
      GenealogyPerson? followFather = father;
      GenealogyPerson? followMother = mother;
      if (lineage == AncestorLineage.paternal) followMother = null;
      if (lineage == AncestorLineage.maternal) followFather = null;
      for (final parent in [followFather, followMother]) {
        if (parent == null) continue;
        people[parent.id] = parent;
        next.add(parent.id);
      }
    }
    frontier = next;
  }

  return DirectLineData(
    focusId: focusId,
    people: people,
    fatherOf: fatherOf,
    motherOf: motherOf,
  );
}

/// Walks every descendant of [rootId] and groups them into the couples the
/// drop-line layout draws. Uncapped within a safety depth, since the walk is
/// in-memory over an already-loaded graph.
DescendantLineData walkDescendants(FamilyGraph graph, String rootId) {
  const safetyDepth = 12;

  final people = <String, GenealogyPerson>{rootId: graph.person(rootId)!};
  var frontier = <String>[rootId];
  for (var generation = 1; generation <= safetyDepth; generation++) {
    if (frontier.isEmpty) break;
    final next = <String>[];
    for (final personId in frontier) {
      for (final child in graph.childrenOf(personId)) {
        if (!people.containsKey(child.id)) {
          people[child.id] = child;
          next.add(child.id);
        }
      }
    }
    frontier = next;
  }

  // Spouses join so couples render side by side.
  for (final id in people.keys.toList()) {
    for (final spouse in graph.spousesOf(id)) {
      people[spouse.id] = spouse;
    }
  }

  final couples = [
    for (final grouping in graph.familiesAmong(people.keys.toSet()))
      TreeCouple(
        familyId: grouping.familyId,
        partnerIds: grouping.partnerIds,
        childIds: grouping.childIds,
      ),
  ];

  return DescendantLineData(rootId: rootId, people: people, couples: couples);
}

final pedigreeChartProvider = FutureProvider.family<DirectLineData?, String>((
  ref,
  personId,
) async {
  ref.watch(personRelationshipsProvider(personId));

  final person = await ref
      .watch(genealogyRepositoryProvider)
      .getPersonById(personId);
  if (person == null || person.isDeleted) return null;

  final graph = await ref
      .watch(relationshipRepositoryProvider)
      .loadFamilyGraph(person.treeId);
  if (!graph.contains(personId)) return null;

  final maxGenerations = await ref.watch(
    fanChartAncestorGenerationsProvider.future,
  );
  return walkAncestors(graph, personId, maxGenerations);
});

final descendantChartProvider =
    FutureProvider.family<DescendantLineData?, String>((ref, personId) async {
      ref.watch(personRelationshipsProvider(personId));

      final person = await ref
          .watch(genealogyRepositoryProvider)
          .getPersonById(personId);
      if (person == null || person.isDeleted) return null;

      final graph = await ref
          .watch(relationshipRepositoryProvider)
          .loadFamilyGraph(person.treeId);
      if (!graph.contains(personId)) return null;

      return walkDescendants(graph, personId);
    });

class HourglassChartData {
  const HourglassChartData({
    required this.focusId,
    required this.ancestors,
    required this.descendants,
  });

  final String focusId;
  final DirectLineData ancestors;
  final DescendantLineData descendants;

  Map<String, GenealogyPerson> get people => {
    ...descendants.people,
    ...ancestors.people,
  };
}

final hourglassChartProvider =
    FutureProvider.family<HourglassChartData?, String>((ref, personId) async {
      ref.watch(personRelationshipsProvider(personId));

      final person = await ref
          .watch(genealogyRepositoryProvider)
          .getPersonById(personId);
      if (person == null || person.isDeleted) return null;

      final graph = await ref
          .watch(relationshipRepositoryProvider)
          .loadFamilyGraph(person.treeId);
      if (!graph.contains(personId)) return null;

      final maxGenerations = await ref.watch(
        fanChartAncestorGenerationsProvider.future,
      );
      return HourglassChartData(
        focusId: personId,
        ancestors: walkAncestors(graph, personId, maxGenerations),
        descendants: walkDescendants(graph, personId),
      );
    });

class BowTieChartData {
  const BowTieChartData({
    required this.focusId,
    required this.fatherLine,
    required this.motherLine,
    required this.fatherId,
    required this.motherId,
  });

  final String focusId;
  final DirectLineData? fatherLine;
  final DirectLineData? motherLine;
  final String? fatherId;
  final String? motherId;

  Map<String, GenealogyPerson> get people => {
    if (fatherLine != null) ...fatherLine!.people,
    if (motherLine != null) ...motherLine!.people,
  };
}

final bowTieChartProvider = FutureProvider.family<BowTieChartData?, String>((
  ref,
  personId,
) async {
  ref.watch(personRelationshipsProvider(personId));

  final person = await ref
      .watch(genealogyRepositoryProvider)
      .getPersonById(personId);
  if (person == null || person.isDeleted) return null;

  final graph = await ref
      .watch(relationshipRepositoryProvider)
      .loadFamilyGraph(person.treeId);
  if (!graph.contains(personId)) return null;

  final maxGenerations = await ref.watch(
    fanChartAncestorGenerationsProvider.future,
  );

  GenealogyPerson? father;
  GenealogyPerson? mother;
  for (final parent in graph.parentsOf(personId)) {
    if (parent.gender == 'male' && father == null) {
      father = parent;
    } else if (parent.gender == 'female' && mother == null) {
      mother = parent;
    } else if (father == null) {
      father = parent;
    } else {
      mother ??= parent;
    }
  }

  return BowTieChartData(
    focusId: personId,
    fatherId: father?.id,
    motherId: mother?.id,
    // The classic bow-tie: the father's paternal line opens left, the
    // mother's maternal line opens right — single-lineage chains, not full
    // ancestor trees.
    fatherLine: father == null
        ? null
        : walkAncestors(
            graph,
            father.id,
            maxGenerations,
            lineage: AncestorLineage.paternal,
          ),
    motherLine: mother == null
        ? null
        : walkAncestors(
            graph,
            mother.id,
            maxGenerations,
            lineage: AncestorLineage.maternal,
          ),
  );
});

/// Everything the genogram painter needs over the standard hourglass shape:
/// the people, the couple metadata (for the divorce slash) and how each child
/// link is typed (for the dashed adoption/step/foster lines).
class GenogramChartData extends HourglassChartData {
  const GenogramChartData({
    required super.focusId,
    required super.ancestors,
    required super.descendants,
    required this.families,
    required this.childLinkTypes,
  });

  /// The live families of the visible couples.
  final List<FamiliesV2Data> families;

  /// `'$familyId:$childId'` → link type (`biological`, `adopted`, …).
  final Map<String, String> childLinkTypes;
}

final genogramChartProvider = FutureProvider.family<GenogramChartData?, String>(
  (ref, personId) async {
    ref.watch(personRelationshipsProvider(personId));

    final person = await ref
        .watch(genealogyRepositoryProvider)
        .getPersonById(personId);
    if (person == null || person.isDeleted) return null;

    final graph = await ref
        .watch(relationshipRepositoryProvider)
        .loadFamilyGraph(person.treeId);
    if (!graph.contains(personId)) return null;

    final maxGenerations = await ref.watch(
      fanChartAncestorGenerationsProvider.future,
    );
    final ancestors = walkAncestors(graph, personId, maxGenerations);
    final descendants = walkDescendants(graph, personId);

    final families = <FamiliesV2Data>[];
    final childLinkTypes = <String, String>{};
    for (final grouping in descendants.couples) {
      final family = graph.familyById(grouping.familyId);
      if (family != null) families.add(family);
      for (final childId in grouping.childIds) {
        final type = graph.childLinkType(grouping.familyId, childId);
        if (type != null) {
          childLinkTypes['${grouping.familyId}:$childId'] = type;
        }
      }
    }

    return GenogramChartData(
      focusId: personId,
      ancestors: ancestors,
      descendants: descendants,
      families: families,
      childLinkTypes: childLinkTypes,
    );
  },
);
