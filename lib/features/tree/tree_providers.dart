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

    final rememberEnabled = ref.read(rememberLastRootPersonProvider).value ??
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
      if (rootPerson == null) {
        return null;
      }

      final parents = await relationshipRepository.getParents(personId);
      final spouses = await relationshipRepository.getSpouses(personId);
      final children = await relationshipRepository.getChildren(personId);

      return BasicFamilyTreeData(
        rootPerson: rootPerson,
        parents: parents,
        spouses: spouses,
        children: children,
      );
    });

final multiGenFamilyTreeProvider =
    FutureProvider.family<MultiGenFamilyTreeData?, String>((ref, personId) async {
      ref.watch(personRelationshipsProvider(personId));

      final personRepository = ref.watch(genealogyRepositoryProvider);
      final relationshipRepository = ref.watch(relationshipRepositoryProvider);

      final rootPerson = await personRepository.getPersonById(personId);
      if (rootPerson == null) return null;

      final nodes = <String, GenealogyPerson>{rootPerson.id: rootPerson};
      final edges = <TreeEdge>[];
      final visitedNodes = <String>{rootPerson.id};

      // Configuration for depth
      const maxUpDepth = 3; // Ancestors
      const maxDownDepth = 2; // Descendants

      // Fetch ancestors BFS
      var currentUpQueue = [rootPerson.id];
      for (var depth = 1; depth <= maxUpDepth; depth++) {
        if (currentUpQueue.isEmpty) break;
        final nextQueue = <String>[];
        for (final id in currentUpQueue) {
          final parents = await relationshipRepository.getParents(id);
          for (final parent in parents) {
            nodes[parent.id] = parent;
            edges.add(TreeEdge(sourceId: parent.id, targetId: id, relationType: 'parent_child'));
            if (!visitedNodes.contains(parent.id)) {
              visitedNodes.add(parent.id);
              nextQueue.add(parent.id);
            }
          }
        }
        currentUpQueue = nextQueue;
      }

      // Fetch descendants BFS
      var currentDownQueue = [rootPerson.id];
      for (var depth = 1; depth <= maxDownDepth; depth++) {
        if (currentDownQueue.isEmpty) break;
        final nextQueue = <String>[];
        for (final id in currentDownQueue) {
          final children = await relationshipRepository.getChildren(id);
          for (final child in children) {
            nodes[child.id] = child;
            edges.add(TreeEdge(sourceId: id, targetId: child.id, relationType: 'parent_child'));
            if (!visitedNodes.contains(child.id)) {
              visitedNodes.add(child.id);
              nextQueue.add(child.id);
            }
          }
        }
        currentDownQueue = nextQueue;
      }

      // Fetch spouses for everyone found (optional depth for spouses, but let's just do it for everyone in nodes so far)
      final allNodeIds = nodes.keys.toList();
      for (final id in allNodeIds) {
        final spouses = await relationshipRepository.getSpouses(id);
        for (final spouse in spouses) {
          if (!nodes.containsKey(spouse.id)) {
            nodes[spouse.id] = spouse;
          }
          edges.add(TreeEdge(sourceId: id, targetId: spouse.id, relationType: 'spouse'));
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
      if (rootPerson == null) {
        return null;
      }

      final maxGenerations =
          await ref.watch(fanChartAncestorGenerationsProvider.future);
      final generations = <List<AncestrySlot>>[
        [AncestrySlot(generation: 0, childId: null, relationToChild: null, person: rootPerson)],
      ];

      var currentGenerationPersons = <GenealogyPerson>[rootPerson];
      for (var generation = 1; generation <= maxGenerations; generation++) {
        final slots = <AncestrySlot>[];
        final nextGenerationPersons = <GenealogyPerson>[];

        for (final child in currentGenerationPersons) {
          final parents = await relationshipRepository.getParents(child.id);

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
