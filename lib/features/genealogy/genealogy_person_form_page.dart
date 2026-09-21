import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// Only `Value` is needed from drift here; importing it wholesale would clash
// with Flutter's own `Column`/`Table` widgets.
import 'package:drift/drift.dart' show Value;

import '../../core/constants/app_constants.dart';
import '../../data/database/app_database.dart';
import '../../data/models/person_save_data.dart';
import '../../data/providers/genealogy_repository_provider.dart';
import '../../data/providers/person_save_service_provider.dart';

class GenealogyPersonFormPage extends ConsumerStatefulWidget {
  const GenealogyPersonFormPage({
    super.key,
    this.personId,
    this.linkPersonId,
    this.relationKind,
    this.initialGender,
    this.returnTo,
  });

  final String? personId;
  final String? linkPersonId;
  final String? relationKind;
  final String? initialGender;
  final String? returnTo;

  @override
  ConsumerState<GenealogyPersonFormPage> createState() =>
      _GenealogyPersonFormPageState();
}

class _GenealogyPersonFormPageState
    extends ConsumerState<GenealogyPersonFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthSurnameController = TextEditingController();
  final _marriedSurnameController = TextEditingController();
  final _fullNameController = TextEditingController();

  String _gender = 'M';
  bool _loading = false;
  String? _loadedPersonId;

  @override
  void initState() {
    super.initState();
    _gender = widget.initialGender ?? 'M';
    if (widget.personId != null) {
      _loadPerson(widget.personId!);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _birthSurnameController.dispose();
    _marriedSurnameController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _loadPerson(String id) async {
    setState(() {
      _loading = true;
    });

    final repo = ref.read(genealogyRepositoryProvider);
    final person = await repo.getPersonById(id);
    if (!mounted) return;

    if (person != null) {
      _loadedPersonId = id;
      _firstNameController.text = person.firstName;
      _middleNameController.text = person.middleName ?? '';
      _lastNameController.text = person.lastName ?? '';
      _birthSurnameController.text = person.birthSurname ?? '';
      _marriedSurnameController.text = person.marriedSurname ?? '';
      _fullNameController.text = person.customDisplayName ?? '';
      _gender = person.gender;
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(genealogyRepositoryProvider);
    final firstName = _firstNameController.text.trim();
    final middleName = _middleNameController.text.trim().isEmpty
        ? null
        : _middleNameController.text.trim();
    final lastName = _lastNameController.text.trim().isEmpty
        ? null
        : _lastNameController.text.trim();
    final birthSurname = _birthSurnameController.text.trim().isEmpty
        ? null
        : _birthSurnameController.text.trim();
    final marriedSurname = _marriedSurnameController.text.trim().isEmpty
        ? null
        : _marriedSurnameController.text.trim();
    final customDisplayName = _fullNameController.text.trim().isEmpty
        ? null
        : _fullNameController.text.trim();

    if (_loadedPersonId == null &&
        widget.linkPersonId != null &&
        widget.relationKind == 'spouse') {
      // One atomic application operation instead of the previous raw
      // createFamily with ad-hoc partner slotting.
      await ref
          .read(personSaveServiceProvider)
          .createPersonAsSpouse(
            treeId: AppConstants.defaultTreeId,
            person: PersonSaveData(
              firstName: firstName,
              middleName: middleName,
              lastName: lastName,
              birthSurname: birthSurname,
              marriedSurname: marriedSurname,
              gender: _gender,
              customDisplayName: customDisplayName,
            ),
            partnerId: widget.linkPersonId!,
          );
    } else if (_loadedPersonId == null &&
        widget.linkPersonId != null &&
        widget.relationKind == 'child') {
      // Canonical relationship rules instead of the previous
      // families.first / single-parent createFamily path.
      await ref
          .read(personSaveServiceProvider)
          .createPersonAsChild(
            treeId: AppConstants.defaultTreeId,
            person: PersonSaveData(
              firstName: firstName,
              middleName: middleName,
              lastName: lastName,
              birthSurname: birthSurname,
              marriedSurname: marriedSurname,
              gender: _gender,
              customDisplayName: customDisplayName,
            ),
            parentId: widget.linkPersonId!,
          );
    } else if (_loadedPersonId == null) {
      await repo.addPerson(
        treeId: AppConstants.defaultTreeId,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        birthSurname: birthSurname,
        marriedSurname: marriedSurname,
        gender: _gender,
        customDisplayName: customDisplayName,
      );
    } else {
      await repo.updatePerson(
        GenealogyPersonsCompanion(
          id: Value(_loadedPersonId!),
          firstName: Value(firstName),
          middleName: Value(middleName),
          lastName: Value(lastName),
          birthSurname: Value(birthSurname),
          marriedSurname: Value(marriedSurname),
          gender: Value(_gender),
          customDisplayName: Value(customDisplayName),
        ),
      );
    }

    if (!mounted) return;
    if (widget.linkPersonId != null && widget.relationKind != null) {
      final relationLabel = widget.relationKind == 'spouse'
          ? 'spouse'
          : widget.relationKind == 'child'
          ? 'child'
          : 'person';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Created and linked new $relationLabel successfully.'),
        ),
      );
      context.go(widget.returnTo ?? '/v2/people/${widget.linkPersonId}');
      return;
    }
    if (_loadedPersonId != null) {
      context.go(widget.returnTo ?? '/v2/people/$_loadedPersonId');
      return;
    }
    if (widget.returnTo != null && widget.returnTo!.isNotEmpty) {
      context.go(widget.returnTo!);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.personId == null ? 'Add Person (v2)' : 'Edit Person (v2)',
        ),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First Name'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter first name'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _middleNameController,
              decoration: const InputDecoration(labelText: 'Middle Name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _birthSurnameController,
              decoration: const InputDecoration(labelText: 'Birth Surname'),
            ),
            const SizedBox(height: 12),
            if (_gender == 'F') ...[
              TextFormField(
                controller: _marriedSurnameController,
                decoration: const InputDecoration(labelText: 'Married Surname'),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Display Name Override',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: const [
                DropdownMenuItem(value: 'M', child: Text('Male')),
                DropdownMenuItem(value: 'F', child: Text('Female')),
                DropdownMenuItem(value: 'U', child: Text('Unknown')),
                DropdownMenuItem(value: 'O', child: Text('Other')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _gender = value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
