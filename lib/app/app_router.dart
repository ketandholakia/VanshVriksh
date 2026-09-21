import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'main_shell_page.dart';
import '../features/backup/backup_restore_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/dashboard/upcoming_birthdays_page.dart';
import '../features/duplicates/duplicate_detection_page.dart';
import '../features/duplicates/marked_duplicates_page.dart';
import '../features/integrity/integrity_check_page.dart';
import '../features/media/person_media_gallery_page.dart';
import '../features/people/people_list_page.dart';
import '../features/people/person_form_page.dart';
import '../features/person_facts/person_facts_page.dart';
import '../features/person_facts/person_fact_form_page.dart';
import '../features/genealogy/genealogy_person_form_page.dart';
import '../features/genealogy/genealogy_link_family_page.dart';
import '../features/genealogy/genealogy_people_list_page.dart';
import '../features/genealogy/genealogy_person_profile_page.dart';
import '../data/database/app_database.dart';
import '../data/providers/genealogy_repository_provider.dart';
import '../data/repositories/genealogy_repository.dart';
import '../features/people/person_profile_page.dart';
import '../features/relationships/add_relationship_page.dart';
import '../features/settings/app_settings_provider.dart';
import '../features/settings/settings_page.dart';
import '../features/tree/family_fan_chart_page.dart';
import '../features/tree/family_tree_page.dart';

part 'genealogy_tree_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShellPage(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/people',
          name: 'people',
          builder: (context, state) => const PeopleListPage(),
        ),
    GoRoute(
      path: '/people/duplicates',
      name: 'people-duplicates',
      builder: (context, state) => const DuplicateDetectionPage(),
    ),
    GoRoute(
      path: '/integrity',
      name: 'integrity',
      builder: (context, state) => const IntegrityCheckPage(),
    ),
    GoRoute(
      path: '/duplicates/marked',
      name: 'marked-duplicates',
      builder: (context, state) => const MarkedDuplicatesPage(),
    ),
        GoRoute(
          path: '/tree',
          name: 'tree',
          builder: (context, state) => const FamilyTreePage(),
        ),
        GoRoute(
          path: '/fan-tree',
          name: 'fan-tree',
          builder: (context, state) => const FamilyFanChartPage(),
        ),
        GoRoute(
          path: '/backup',
          name: 'backup',
          builder: (context, state) => const BackupRestorePage(),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    ),
    GoRoute(
      path: '/birthdays',
      name: 'birthdays',
      builder: (context, state) => const UpcomingBirthdaysPage(),
    ),
    GoRoute(
      path: '/people/add',
      name: 'person-add',
      builder: (context, state) {
        final linkPersonId = state.uri.queryParameters['linkPersonId'];
        final siblingOfPersonId = state.uri.queryParameters['siblingOfPersonId'];
        final relationKind = state.uri.queryParameters['relationKind'];
        final initialGender = state.uri.queryParameters['initialGender'];
        final returnTo = state.uri.queryParameters['returnTo'];

        return PersonFormPage(
          linkPersonId: linkPersonId,
          siblingOfPersonId: siblingOfPersonId,
          relationKind: relationKind,
          initialGender: initialGender,
          returnTo: returnTo,
        );
      },
    ),
    GoRoute(
      path: '/people/:id/edit',
      name: 'person-edit',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return PersonFormPage(personId: id);
      },
    ),
    GoRoute(
      path: '/people/:id/add-relationship',
      name: 'add-relationship',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final initialRelation = state.uri.queryParameters['relation'];
        return AddRelationshipPage(
          personId: id,
          initialRelation: initialRelation,
        );
      },
    ),
    GoRoute(
      path: '/people/:id/media',
      name: 'person-media',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return PersonMediaGalleryPage(personId: id);
      },
    ),
    GoRoute(
      path: '/people/:id/facts',
      name: 'person-facts',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return PersonFactsPage(personId: id);
      },
    ),
    GoRoute(
      path: '/people/:id/facts/new',
      name: 'person-fact-new',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final kind = state.uri.queryParameters['kind'] == 'note'
            ? FactKind.researchNote
            : FactKind.event;
        return PersonFactFormPage(personId: id, kind: kind);
      },
    ),
    GoRoute(
      path: '/people/:id/facts/edit/:factId',
      name: 'person-fact-edit',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final factId = state.pathParameters['factId']!;
        final kind = state.uri.queryParameters['kind'] == 'note'
            ? FactKind.researchNote
            : FactKind.event;
        return PersonFactFormPage(personId: id, kind: kind, factId: factId);
      },
    ),
    GoRoute(
      path: '/tree/:rootPersonId',
      name: 'tree-root',
      builder: (context, state) {
        final rootPersonId = state.pathParameters['rootPersonId'];
        return FamilyTreePage(rootPersonId: rootPersonId);
      },
    ),
    GoRoute(
      path: '/fan-tree/:rootPersonId',
      name: 'fan-tree-root',
      builder: (context, state) {
        final rootPersonId = state.pathParameters['rootPersonId'];
        return FamilyFanChartPage(rootPersonId: rootPersonId);
      },
    ),
    GoRoute(
      path: '/people/:id',
      name: 'person-profile',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return PersonProfilePage(personId: id);
      },
    ),
    GoRoute(
      path: '/v2/people/add',
      name: 'genealogy-person-add',
      builder: (context, state) {
        final linkPersonId = state.uri.queryParameters['linkPersonId'];
        final relationKind = state.uri.queryParameters['relationKind'];
        final initialGender = state.uri.queryParameters['initialGender'];
        final returnTo = state.uri.queryParameters['returnTo'];
        return GenealogyPersonFormPage(
          linkPersonId: linkPersonId,
          relationKind: relationKind,
          initialGender: initialGender,
          returnTo: returnTo,
        );
      },
    ),
    GoRoute(
      path: '/v2/people',
      name: 'genealogy-people',
      builder: (context, state) => const GenealogyPeopleListPage(),
    ),
    GoRoute(
      path: '/v2/people/:id',
      name: 'genealogy-person-profile',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return GenealogyPersonProfilePage(personId: id);
      },
    ),
    GoRoute(
      path: '/v2/people/:id/edit',
      name: 'genealogy-person-edit',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final returnTo = state.uri.queryParameters['returnTo'];
        return GenealogyPersonFormPage(personId: id, returnTo: returnTo);
      },
    ),
    GoRoute(
      path: '/v2/people/:id/link/:type',
      name: 'genealogy-link-family',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final type = state.pathParameters['type']!;
        return GenealogyLinkFamilyPage(personId: id, linkType: type);
      },
    ),
    GoRoute(
      path: '/v2/tree/:id',
      name: 'genealogy-tree',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return GenealogyTreePage(personId: id);
      },
    ),
  ],
);

