import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../data/database/app_database.dart';
import '../../data/providers/genealogy_repository_provider.dart';
import '../../data/providers/relationship_repository_provider.dart';
import 'person_relationship_models.dart';

final peopleListProvider = StreamProvider<List<GenealogyPerson>>((ref) {
  final repository = ref.watch(genealogyRepositoryProvider);

  return repository.watchPeopleByTree(AppConstants.defaultTreeId);
});

final personByIdProvider = StreamProvider.family<GenealogyPerson?, String>((
  ref,
  personId,
) {
  final repository = ref.watch(genealogyRepositoryProvider);

  return repository.watchPersonById(personId);
});

final personRelationshipsProvider = StreamProvider.family<void, String>((
  ref,
  personId,
) {
  final repository = ref.watch(relationshipRepositoryProvider);
  return repository.watchRelationshipsForPerson(personId);
});

final parentsProvider = FutureProvider.family<List<GenealogyPerson>, String>((
  ref,
  personId,
) {
  ref.watch(personRelationshipsProvider(personId));

  final repository = ref.watch(relationshipRepositoryProvider);
  return repository.getParents(personId);
});

final childrenProvider = FutureProvider.family<List<GenealogyPerson>, String>((
  ref,
  personId,
) {
  ref.watch(personRelationshipsProvider(personId));

  final repository = ref.watch(relationshipRepositoryProvider);
  return repository.getChildren(personId);
});

final spousesProvider = FutureProvider.family<List<GenealogyPerson>, String>((
  ref,
  personId,
) {
  ref.watch(personRelationshipsProvider(personId));

  final repository = ref.watch(relationshipRepositoryProvider);
  return repository.getSpouses(personId);
});

final siblingsProvider = FutureProvider.family<List<GenealogyPerson>, String>((
  ref,
  personId,
) {
  ref.watch(personRelationshipsProvider(personId));

  final repository = ref.watch(relationshipRepositoryProvider);
  return repository.getSiblings(personId);
});

final parentItemsProvider =
    FutureProvider.family<List<PersonRelationItem>, String>((ref, personId) {
      ref.watch(personRelationshipsProvider(personId));

      final repository = ref.watch(relationshipRepositoryProvider);
      return repository.getParentItems(personId);
    });

final spouseItemsProvider =
    FutureProvider.family<List<PersonRelationItem>, String>((ref, personId) {
      ref.watch(personRelationshipsProvider(personId));

      final repository = ref.watch(relationshipRepositoryProvider);
      return repository.getSpouseItems(personId);
    });

final childItemsProvider =
    FutureProvider.family<List<PersonRelationItem>, String>((ref, personId) {
      ref.watch(personRelationshipsProvider(personId));

      final repository = ref.watch(relationshipRepositoryProvider);
      return repository.getChildItems(personId);
    });

final siblingItemsProvider =
    FutureProvider.family<List<PersonRelationItem>, String>((ref, personId) {
      ref.watch(personRelationshipsProvider(personId));

      final repository = ref.watch(relationshipRepositoryProvider);
      return repository.getSiblingItems(personId);
    });
