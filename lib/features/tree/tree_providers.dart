import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/providers/genealogy_repository_provider.dart';
import '../../data/providers/relationship_repository_provider.dart';
import '../people/people_providers.dart';
import '../settings/app_settings_provider.dart';
import '../../core/extensions/genealogy_person_extensions.dart';
import '../settings/fan_chart_settings_provider.dart';
import 'tree_models.dart';

final selectedRootPersonIdProvider =
    NotifierProvider<SelectedRootPersonIdNotifier, String?>(
      SelectedRootPersonIdNotifier.new,
    );

class SelectedRootPersonIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setRootPersonId(String? personId) {
    state = personId;
    if (personId == null || personId.trim().isEmpty) return;

    final rememberEnabled =
        ref.read(rememberLastRootPersonProvider).value ??
        rememberLastRootPersonDefault;
    if (!rememberEnabled) return;

    unawaited(
      ref.read(lastRootPersonIdProvider.notifier).setPersonId(personId),
    );
  }
}

final basicFamilyTreeProvider =
    FutureProvider.family<BasicFamilyTreeData?, String>((ref, personId) async {
      ref.watch(personRelationshipsProvider(personId));

      final personRepository = ref.watch(genealogyRepositoryProvider);
      final relationshipRepository = ref.watch(relationshipRepositoryProvider);

      final rootPerson = await personRepository.getPersonById(personId);
      if (rootPerson == null || rootPerson.isDeleted) {
        return null;
      }

      // One graph load instead of three separate relationship queries.
      final graph = await relationshipRepository.loadFamilyGraph(
        rootPerson.treeId,
      );

      return BasicFamilyTreeData(
        rootPerson: graph.person(personId) ?? rootPerson,
        parents: graph.parentsOf(personId),
        spouses: graph.spousesOf(personId),
        children: graph.childrenOf(personId),
      );
    });

final multiGenFamilyTreeProvider =
    FutureProvider.family<MultiGenFamilyTreeData?, String>((
      ref,
      personId,
    ) async {
      ref.watch(personRelationshipsProvider(personId));

      final personRepository = ref.watch(genealogyRepositoryProvider);
      final relationshipRepository = ref.watch(relationshipRepositoryProvider);

      final rootPerson = await personRepository.getPersonById(personId);
      if (rootPerson == null || rootPerson.isDeleted) return null;

      // The whole traversal runs against one in-memory graph. Previously every
      // node cost separate parents/spouses/children queries, so a three-up,
      // two-down walk of a few dozen people issued hundreds of queries.
      final graph = await relationshipRepository.loadFamilyGraph(
        rootPerson.treeId,
      );

      final nodes = <String, GenealogyPerson>{rootPerson.id: rootPerson};
      final edges = <TreeEdge>[];
      final visitedNodes = <String>{rootPerson.id};

      // Configuration for depth
      const maxUpDepth = 3; // Ancestors
      const maxDownDepth = 2; // Descendants

      // Walk ancestors breadth-first.
      var currentUpQueue = [rootPerson.id];
      for (var depth = 1; depth <= maxUpDepth; depth++) {
        if (currentUpQueue.isEmpty) break;
        final nextQueue = <String>[];
        for (final id in currentUpQueue) {
          for (final parent in graph.parentsOf(id)) {
            nodes[parent.id] = parent;
            edges.add(
              TreeEdge(
                sourceId: parent.id,
                targetId: id,
                relationType: 'parent_child',
              ),
            );
            if (!visitedNodes.contains(parent.id)) {
              visitedNodes.add(parent.id);
              nextQueue.add(parent.id);
            }
          }
        }
        currentUpQueue = nextQueue;
      }

      // Walk descendants breadth-first.
      var currentDownQueue = [rootPerson.id];
      for (var depth = 1; depth <= maxDownDepth; depth++) {
        if (currentDownQueue.isEmpty) break;
        final nextQueue = <String>[];
        for (final id in currentDownQueue) {
          for (final child in graph.childrenOf(id)) {
            nodes[child.id] = child;
            edges.add(
              TreeEdge(
                sourceId: id,
                targetId: child.id,
                relationType: 'parent_child',
              ),
            );
            if (!visitedNodes.contains(child.id)) {
              visitedNodes.add(child.id);
              nextQueue.add(child.id);
            }
          }
        }
        currentDownQueue = nextQueue;
      }

      // Attach the spouses of everyone found.
      for (final id in nodes.keys.toList()) {
        for (final spouse in graph.spousesOf(id)) {
          nodes[spouse.id] = spouse;
          edges.add(
            TreeEdge(sourceId: id, targetId: spouse.id, relationType: 'spouse'),
          );
        }
      }

      return MultiGenFamilyTreeData(
        rootPerson: rootPerson,
        nodes: nodes,
        edges: edges,
      );
    });

final ancestryFanChartProvider =
    FutureProvider.family<AncestryFanChartData?, String>((ref, personId) async {
      ref.watch(personRelationshipsProvider(personId));

      final personRepository = ref.watch(genealogyRepositoryProvider);
      final relationshipRepository = ref.watch(relationshipRepositoryProvider);

      final rootPerson = await personRepository.getPersonById(personId);
      if (rootPerson == null || rootPerson.isDeleted) {
        return null;
      }

      // One graph load for the whole fan: the loop below asks for parents of many
      // people, generation after generation.
      final graph = await relationshipRepository.loadFamilyGraph(
        rootPerson.treeId,
      );

      final maxGenerations = await ref.watch(
        fanChartAncestorGenerationsProvider.future,
      );
      final generations = <List<AncestrySlot>>[
        [
          AncestrySlot(
            generation: 0,
            childId: null,
            relationToChild: null,
            person: rootPerson,
          ),
        ],
      ];

      var currentGenerationPersons = <GenealogyPerson>[rootPerson];
      for (var generation = 1; generation <= maxGenerations; generation++) {
        final slots = <AncestrySlot>[];
        final nextGenerationPersons = <GenealogyPerson>[];

        for (final child in currentGenerationPersons) {
          final parents = graph.parentsOf(child.id);

          GenealogyPerson? father;
          GenealogyPerson? mother;

          for (final parent in parents) {
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

          final fatherSlot = AncestrySlot(
            generation: generation,
            childId: child.id,
            relationToChild: 'father',
            person: father,
          );
          final motherSlot = AncestrySlot(
            generation: generation,
            childId: child.id,
            relationToChild: 'mother',
            person: mother,
          );

          slots.add(fatherSlot);
          slots.add(motherSlot);

          final ancestorsToAdd = <GenealogyPerson>[];
          if (father != null) {
            ancestorsToAdd.add(father);
          }
          if (mother != null) {
            ancestorsToAdd.add(mother);
          }
          nextGenerationPersons.addAll(ancestorsToAdd);
        }

        if (slots.isEmpty) {
          break;
        }

        generations.add(slots);
        if (nextGenerationPersons.isEmpty) {
          break;
        }

        currentGenerationPersons = nextGenerationPersons;
      }

      return AncestryFanChartData(
        rootPerson: rootPerson,
        generations: generations,
      );
    });

final firstPersonProvider = FutureProvider<GenealogyPerson?>((ref) async {
  final people = await ref.watch(peopleListProvider.future);

  if (people.isEmpty) {
    return null;
  }

  return people.first;
});
