import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'birthday_models.dart';
import 'dashboard_providers.dart';
import '../../core/extensions/genealogy_person_extensions.dart';

class UpcomingBirthdaysPage extends ConsumerWidget {
  const UpcomingBirthdaysPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final birthdays = ref.watch(upcomingBirthdaysProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming Birthdays')),
      body: birthdays.isEmpty
          ? const _EmptyBirthdaysView()
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: birthdays.length,
              itemBuilder: (context, index) {
                final birthday = birthdays[index];
                return _BirthdayTile(
                  birthday: birthday,
                  onTap: () => context.push('/people/${birthday.person.id}'),
                );
              },
            ),
    );
  }
}

class _BirthdayTile extends StatelessWidget {
  const _BirthdayTile({required this.birthday, required this.onTap});

  final UpcomingBirthday birthday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final person = birthday.person;
    final hasPhoto =
        person.profilePhotoPath != null &&
        person.profilePhotoPath!.trim().isNotEmpty;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: hasPhoto
              ? FileImage(File(person.profilePhotoPath!))
              : null,
          child: hasPhoto
              ? null
              : Text(
                  person.fullName.trim().isNotEmpty
                      ? person.fullName.trim()[0].toUpperCase()
                      : '?',
                ),
        ),
        title: Text(
          person.fullName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(_subtitle()),
        trailing: _BirthdayBadge(daysLeft: birthday.daysLeft),
        onTap: onTap,
      ),
    );
  }

  String _subtitle() {
    final date = birthday.nextBirthday;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    final ageText = birthday.ageTurning == null
        ? ''
        : ' • Turning ${birthday.ageTurning}';

    return '$day-$month-${date.year}$ageText';
  }
}

class _BirthdayBadge extends StatelessWidget {
  const _BirthdayBadge({required this.daysLeft});

  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    final text = daysLeft == 0
        ? 'Today'
        : daysLeft == 1
        ? 'Tomorrow'
        : '$daysLeft days';

    return Chip(
      avatar: const Icon(Icons.cake_outlined, size: 18),
      label: Text(text),
    );
  }
}

class _EmptyBirthdaysView extends StatelessWidget {
  const _EmptyBirthdaysView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cake_outlined,
              size: 76,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No upcoming birthdays',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Birthdays within the next 60 days will appear here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
