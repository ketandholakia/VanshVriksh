import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'integrity_check_providers.dart';

class IntegrityCheckPage extends ConsumerWidget {
  const IntegrityCheckPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issuesAsync = ref.watch(integrityIssuesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Integrity Check')),
      body: issuesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to run integrity check:\n$error'),
          ),
        ),
        data: (issues) {
          if (issues.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'No obvious integrity issues found.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: issues.length,
            itemBuilder: (context, index) {
              final issue = issues[index];
              final color = issue.severity == 'error'
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.tertiary;
              return Card(
                child: ListTile(
                  leading: Icon(Icons.report_problem_outlined, color: color),
                  title: Text(issue.title),
                  subtitle: Text(issue.description),
                  trailing: issue.personId == null
                      ? null
                      : TextButton(
                          onPressed: () =>
                              context.push('/people/${issue.personId}'),
                          child: const Text('Open person'),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
