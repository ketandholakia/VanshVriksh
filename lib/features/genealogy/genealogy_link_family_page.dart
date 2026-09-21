import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../data/database/app_database.dart';
import '../../data/providers/genealogy_repository_provider.dart';

class GenealogyLinkFamilyPage extends ConsumerStatefulWidget {
  const GenealogyLinkFamilyPage({
    super.key,
    required this.personId,
    required this.linkType,
  });

  final String personId;
  final String linkType;

  @override
  ConsumerState<GenealogyLinkFamilyPage> createState() =>
      _GenealogyLinkFamilyPageState();
}

class _GenealogyLinkFamilyPageState
    extends ConsumerState<GenealogyLinkFamilyPage> {
  final _searchController = TextEditingController();
  List<GenealogyPerson> _matches = const [];
  GenealogyPerson? _selected;
  bool _loading = false;
  String _status = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final repo = ref.read(genealogyRepositoryProvider);
    final people = await repo.searchPeople(
      treeId: AppConstants.defaultTreeId,
      query: query,
    );
    if (!mounted) return;
    setState(() {
      _matches = people
          .where((person) => person.id != widget.personId)
          .toList();
      _status = _matches.isEmpty ? 'No matches found.' : '';
    });
  }

  String _displayName(GenealogyPerson person) {
    final surname = (person.marriedSurname?.trim().isNotEmpty ?? false)
        ? person.marriedSurname!.trim()
        : (person.birthSurname?.trim().isNotEmpty ?? false)
        ? person.birthSurname!.trim()
        : (person.lastName ?? '').trim();
    return [
      person.firstName.trim(),
      if ((person.middleName ?? '').trim().isNotEmpty)
        person.middleName!.trim(),
      if (surname.isNotEmpty) surname,
    ].where((part) => part.trim().isNotEmpty).join(' ');
  }

  Future<void> _save() async {
    if (_selected == null) return;
    setState(() {
      _loading = true;
      _status = '';
    });

    final repo = ref.read(genealogyRepositoryProvider);
    final current = await repo.getPersonById(widget.personId);
    if (current == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _status = 'Current person not found.';
      });
      return;
    }

    if (widget.linkType == 'spouse') {
      final spouse = _selected!;
      final husbandId = current.gender == 'M'
          ? current.id
          : spouse.gender == 'M'
          ? spouse.id
          : current.id;
      final wifeId = current.gender == 'F'
          ? current.id
          : spouse.gender == 'F'
          ? spouse.id
          : spouse.id;
      await repo.createFamily(
        treeId: AppConstants.defaultTreeId,
        husbandId: husbandId,
        wifeId: wifeId,
        isPrimaryMarriage: true,
        husbandTookWifeName: false,
        wifeTookHusbandName: false,
      );
    } else {
      final familyId = await repo.createFamily(
        treeId: AppConstants.defaultTreeId,
        husbandId: current.gender == 'M' ? current.id : null,
        wifeId: current.gender == 'F' ? current.id : null,
        isPrimaryMarriage: true,
      );
      await repo.addChildToFamily(
        familyId: familyId,
        childId: _selected!.id,
        relationshipType: 'biological',
      );
    }

    if (!mounted) return;
    final message = widget.linkType == 'spouse'
        ? 'Spouse linked successfully.'
        : 'Child linked successfully.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    context.pop();
  }

  Future<void> _createNewLinkedPerson() async {
    final current = await ref
        .read(genealogyRepositoryProvider)
        .getPersonById(widget.personId);
    if (current == null || !mounted) return;

    final initialGender = widget.linkType == 'spouse'
        ? (current.gender == 'M'
              ? 'F'
              : current.gender == 'F'
              ? 'M'
              : 'O')
        : 'O';

    final relationKind = widget.linkType == 'spouse' ? 'spouse' : 'child';

    if (!mounted) return;
    context.push(
      '/v2/people/add?${Uri(queryParameters: {'linkPersonId': widget.personId, 'relationKind': relationKind, 'returnTo': '/v2/people/${widget.personId}', 'initialGender': initialGender}).query}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.linkType == 'spouse'
        ? 'Link Spouse (v2)'
        : 'Link Child (v2)';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search person',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: _search,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _loading
                ? null
                : () => _search(_searchController.text.trim()),
            child: const Text('Search'),
          ),
          const SizedBox(height: 12),
          if (_status.isNotEmpty) Text(_status),
          if (_matches.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _createNewLinkedPerson,
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: Text(
                  widget.linkType == 'spouse'
                      ? 'Create New Spouse'
                      : 'Create New Child',
                ),
              ),
            ),
          ..._matches.map(
            (person) => Card(
              child: ListTile(
                title: Text(_displayName(person)),
                subtitle: Text(person.gender),
                trailing: _selected?.id == person.id
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.chevron_right),
                onTap: () => setState(() => _selected = person),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading || _selected == null ? null : _save,
            child: Text(_loading ? 'Saving...' : 'Save Link'),
          ),
        ],
      ),
    );
  }
}
