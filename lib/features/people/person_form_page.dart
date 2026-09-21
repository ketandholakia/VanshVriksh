import 'dart:io';

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
// Only `Value` is needed from drift here; importing it wholesale would clash
// with Flutter's own `Column`/`Table` widgets.
import 'package:drift/drift.dart' show Value;

import '../../core/constants/app_constants.dart';
import '../../core/extensions/genealogy_person_extensions.dart';
import '../settings/display_formatters.dart';
import '../../data/database/app_database.dart';
import '../../data/providers/image_storage_provider.dart';
import '../../data/providers/genealogy_repository_provider.dart';
import '../../data/providers/relationship_repository_provider.dart';
import 'people_providers.dart';
import '../settings/app_settings_provider.dart';

class PersonFormPage extends ConsumerStatefulWidget {
  const PersonFormPage({
    super.key,
    this.personId,
    this.linkPersonId,
    this.siblingOfPersonId,
    this.relationKind,
    this.initialGender,
    this.returnTo,
  });

  final String? personId;
  final String? linkPersonId;
  final String? siblingOfPersonId;
  final String? relationKind;
  final String? initialGender;
  final String? returnTo;

  @override
  ConsumerState<PersonFormPage> createState() => _PersonFormPageState();
}

class _PersonFormPageState extends ConsumerState<PersonFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _prefixController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthSurnameController = TextEditingController();
  final _marriedSurnameController = TextEditingController();
  final _suffixController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  final _currentPlaceController = TextEditingController();
  final _bioController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _birthDate;
  DateTime? _deathDate;
  bool _isPrivate = false;

  bool _isSaving = false;
  bool _hasLoadedPerson = false;
  bool _hasAppliedRelationshipPrefill = false;
  bool _isUpdatingFullNameProgrammatically = false;
  bool _fullNameManuallyEdited = false;
  bool _isResolvingCurrentPlace = false;
  bool _isSearchingBirthPlaces = false;
  int _birthPlaceSearchToken = 0;
  String? _selectedSpouseId;
  String? _selectedSiblingParentId;

  GenealogyPerson? _editingPerson;
  String? _profilePhotoPath;
  File? _pickedPhotoFile;
  late String _gender;
  List<String> _placeSuggestions = const [];

  bool get _isEditMode => widget.personId != null;

  @override
  void initState() {
    super.initState();
    _gender = widget.initialGender ?? 'male';
    _firstNameController.addListener(_syncFullNameFromParts);
    _middleNameController.addListener(_syncFullNameFromParts);
    _birthSurnameController.addListener(_syncFullNameFromParts);
    _fullNameController.addListener(_handleFullNameChange);
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _fullNameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _birthSurnameController.dispose();
    _marriedSurnameController.dispose();
    _suffixController.dispose();
    _nicknameController.dispose();
    _birthPlaceController.dispose();
    _currentPlaceController.dispose();
    _bioController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadPersonIntoForm(GenealogyPerson person) {
    if (_hasLoadedPerson) return;

    _editingPerson = person;
    _prefixController.text = person.prefix ?? '';
    _fullNameController.text = person.fullName;
    _firstNameController.text = person.firstName;
    _middleNameController.text = person.middleName ?? '';
    _lastNameController.text = person.birthSurname ?? person.lastName ?? '';
    _birthSurnameController.text = person.birthSurname ?? person.lastName ?? '';
    _marriedSurnameController.text = person.gender == 'female'
        ? person.marriedSurname ?? ''
        : '';
    _suffixController.text = person.suffix ?? '';
    _nicknameController.text = person.nickname ?? '';
    _birthPlaceController.text = person.birthPlace ?? '';
    _currentPlaceController.text = person.currentPlace ?? '';
    _bioController.text = person.bio ?? '';
    _notesController.text = person.notes ?? '';

    _gender = person.gender;
    if (_gender != 'female') {
      _marriedSurnameController.clear();
    } else if (_marriedSurnameController.text.trim().isEmpty &&
        _birthSurnameController.text.trim().isNotEmpty) {
      _marriedSurnameController.text = _birthSurnameController.text.trim();
      _birthSurnameController.clear();
    }
    _birthDate = person.birthDate;
    _deathDate = person.deathDate;
    _profilePhotoPath = person.profilePhotoPath;
    _isPrivate = person.private;
    _hasLoadedPerson = true;
    _fullNameManuallyEdited = !_matchesComposedFullName(person.fullName);
  }

  Future<void> _searchBirthPlaces(String query) async {
    final token = ++_birthPlaceSearchToken;
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      if (!mounted) return;
      setState(() {
        _placeSuggestions = const [];
        _isSearchingBirthPlaces = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSearchingBirthPlaces = true;
    });

    try {
      final localMatches = _buildPlaceSuggestions(
        ref.read(peopleListProvider).asData?.value ?? const <GenealogyPerson>[],
        trimmed,
      );

      final remoteMatches = await _searchRemotePlaces(trimmed);
      if (!mounted || token != _birthPlaceSearchToken) return;

      final merged = <String>{...localMatches, ...remoteMatches}.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      setState(() {
        _placeSuggestions = merged.take(8).toList();
      });
    } catch (_) {
      // Keep the local suggestions if remote search fails.
    } finally {
      if (mounted && token == _birthPlaceSearchToken) {
        setState(() {
          _isSearchingBirthPlaces = false;
        });
      }
    }
  }

  Future<List<String>> _searchRemotePlaces(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'limit': '8',
      'addressdetails': '1',
    });
    final response = await http.get(
      uri,
      headers: const {
        'User-Agent': 'VanshVriksh/1.0',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) return const [];

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];

    final results = <String>[];
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      final displayName = item['display_name']?.toString().trim();
      if (displayName == null || displayName.isEmpty) continue;
      results.add(_compactPlaceName(displayName));
    }
    return results;
  }

  String _compactPlaceName(String value) {
    final parts = value.split(',');
    if (parts.isEmpty) return value;

    final cleaned = parts
        .take(3)
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    return cleaned.isEmpty ? value : cleaned.join(', ');
  }

  List<String> _buildPlaceSuggestions(List<GenealogyPerson> people, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    final places = <String>{};

    for (final person in people) {
      final birthPlace = person.birthPlace?.trim();
      final currentPlace = person.currentPlace?.trim();
      if (birthPlace != null && birthPlace.isNotEmpty) {
        places.add(birthPlace);
      }
      if (currentPlace != null && currentPlace.isNotEmpty) {
        places.add(currentPlace);
      }
    }

    final sortedPlaces = places.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    if (normalizedQuery.isEmpty) return sortedPlaces.take(8).toList();
    return sortedPlaces
        .where((place) => place.toLowerCase().contains(normalizedQuery))
        .take(8)
        .toList();
  }

  Future<void> _useCurrentLocation() async {
    if (_isResolvingCurrentPlace) return;

    setState(() {
      _isResolvingCurrentPlace = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final place = _formatPlacemark(placemarks);
      if (!mounted) return;

      setState(() {
        _currentPlaceController.text = place;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not determine current location: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingCurrentPlace = false;
        });
      }
    }
  }

  String _formatPlacemark(List<Placemark> placemarks) {
    if (placemarks.isEmpty) return 'Current location';
    final placemark = placemarks.first;
    final parts = <String>[
      if ((placemark.locality ?? '').trim().isNotEmpty)
        placemark.locality!.trim(),
      if ((placemark.administrativeArea ?? '').trim().isNotEmpty)
        placemark.administrativeArea!.trim(),
      if ((placemark.country ?? '').trim().isNotEmpty)
        placemark.country!.trim(),
    ];
    return parts.isEmpty ? 'Current location' : parts.join(', ');
  }

  Future<void> _applyRelationshipPrefill(GenealogyPerson linkedPerson) async {
    if (_hasAppliedRelationshipPrefill) return;

    final relationKind = widget.relationKind;
    if (relationKind == null) return;

    final suggestedFirstName = _suggestFirstName(linkedPerson);
    final suggestedLastName = _suggestLastName(linkedPerson);
    String? fatherFirstName = suggestedFirstName;
    String? fatherSurname = suggestedLastName;

    if (relationKind == 'child') {
      fatherFirstName =
          _suggestFirstName(linkedPerson) ?? linkedPerson.fullName;
      fatherSurname = _suggestLastName(linkedPerson) ?? fatherSurname;

      if (linkedPerson.gender == 'female') {
        final relationshipRepository = ref.read(relationshipRepositoryProvider);
        final spouses = await relationshipRepository.getSpouses(
          linkedPerson.id,
        );
        final maleSpouses = spouses
            .where((person) => person.gender == 'male')
            .toList();
        if (maleSpouses.isNotEmpty) {
          final father = maleSpouses.first;
          fatherFirstName = _suggestFirstName(father) ?? father.fullName;
          fatherSurname = _suggestLastName(father) ?? fatherSurname;
        }
      }
    } else if (relationKind == 'sibling') {
      final relationshipRepository = ref.read(relationshipRepositoryProvider);
      final targetPersonId = widget.siblingOfPersonId;

      if (targetPersonId != null) {
        final parents = await relationshipRepository.getParents(targetPersonId);
        final fatherCandidates = parents
            .where((person) => person.gender == 'male')
            .toList();
        if (fatherCandidates.isNotEmpty) {
          final father = fatherCandidates.first;
          fatherFirstName = _suggestFirstName(father) ?? father.fullName;
          fatherSurname = _suggestLastName(father) ?? fatherSurname;
        }
      }
    }

    switch (relationKind) {
      case 'parent':
        final surname = suggestedLastName;
        if (surname != null) {
          if (_gender == 'female') {
            if (_marriedSurnameController.text.trim().isEmpty) {
              _marriedSurnameController.text = surname;
            }
          } else if (_birthSurnameController.text.trim().isEmpty) {
            _birthSurnameController.text = surname;
          }
        }
        break;
      case 'child':
        if (_middleNameController.text.trim().isEmpty &&
            fatherFirstName != null) {
          _middleNameController.text = fatherFirstName;
        }
        if (_birthSurnameController.text.trim().isEmpty &&
            fatherSurname != null) {
          _birthSurnameController.text = fatherSurname;
        }
        break;
      case 'sibling':
        if (_middleNameController.text.trim().isEmpty &&
            fatherFirstName != null) {
          _middleNameController.text = fatherFirstName;
        }
        if (_birthSurnameController.text.trim().isEmpty &&
            fatherSurname != null) {
          _birthSurnameController.text = fatherSurname;
        }
        break;
      case 'spouse':
        if (_gender == 'female' &&
            _marriedSurnameController.text.trim().isEmpty &&
            suggestedLastName != null) {
          _marriedSurnameController.text = suggestedLastName;
        }
        break;
    }

    _syncFullNameFromParts(force: true);
    _hasAppliedRelationshipPrefill = true;
  }

  void _syncFullNameFromParts({bool force = false}) {
    if (_isUpdatingFullNameProgrammatically) return;
    if (_fullNameManuallyEdited && !force) return;

    final composed = _composeFullName();
    if (composed == null) return;

    final current = _fullNameController.text.trim();
    if (!force && current == composed) return;

    _isUpdatingFullNameProgrammatically = true;
    _fullNameController.text = composed;
    _isUpdatingFullNameProgrammatically = false;
    if (_fullNameManuallyEdited) {
      if (mounted) {
        setState(() {
          _fullNameManuallyEdited = false;
        });
      } else {
        _fullNameManuallyEdited = false;
      }
    }
  }

  void _handleFullNameChange() {
    if (_isUpdatingFullNameProgrammatically) return;

    final composed = _composeFullName();
    final current = _fullNameController.text.trim();

    if (current.isEmpty || composed == current) {
      if (_fullNameManuallyEdited) {
        if (mounted) {
          setState(() {
            _fullNameManuallyEdited = false;
          });
        } else {
          _fullNameManuallyEdited = false;
        }
      }
      return;
    }

    if (!_fullNameManuallyEdited) {
      if (mounted) {
        setState(() {
          _fullNameManuallyEdited = true;
        });
      } else {
        _fullNameManuallyEdited = true;
      }
    }
  }

  String? _composeFullName() {
    final parts = <String>[
      _firstNameController.text.trim(),
      _middleNameController.text.trim(),
      _birthSurnameController.text.trim(),
    ].where((part) => part.isNotEmpty).toList();

    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  bool _matchesComposedFullName(String fullName) {
    final composed = _composeFullName();
    if (composed == null) return fullName.trim().isEmpty;
    return composed == fullName.trim();
  }

  void _resetFullNameOverride() {
    if (!_fullNameManuallyEdited) return;

    if (mounted) {
      setState(() {
        _fullNameManuallyEdited = false;
      });
    } else {
      _fullNameManuallyEdited = false;
    }
    _syncFullNameFromParts(force: true);
  }

  String? _suggestFirstName(GenealogyPerson person) {
    final firstName = person.firstName.trim();
    if (firstName.isNotEmpty) return firstName;

    final parts = _splitName(person.fullName);
    if (parts.isEmpty) return null;
    return parts.first;
  }

  String? _suggestLastName(GenealogyPerson person) {
    final lastName = person.lastName?.trim();
    if (lastName != null && lastName.isNotEmpty) return lastName;

    final parts = _splitName(person.fullName);
    if (parts.isEmpty) return null;
    return parts.length == 1 ? parts.first : parts.last;
  }

  List<String> _splitName(String fullName) {
    return fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
  }

  Future<void> _pickProfilePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (pickedFile == null) return;

    setState(() {
      _pickedPhotoFile = File(pickedFile.path);
    });
  }

  Future<void> _removeProfilePhoto() async {
    setState(() {
      _pickedPhotoFile = null;
      _profilePhotoPath = null;
    });
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1990),
      firstDate: DateTime(1800),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    setState(() {
      _birthDate = picked;
    });
  }

  Future<void> _pickDeathDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deathDate ?? DateTime.now(),
      firstDate: DateTime(1800),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    setState(() {
      _deathDate = picked;
    });
  }

  Future<void> _savePerson() async {
    if (!_formKey.currentState!.validate()) return;

    if (_birthDate != null &&
        _deathDate != null &&
        _deathDate!.isBefore(_birthDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Death date cannot be before birth date.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(genealogyRepositoryProvider);
      final imageStorage = ref.read(imageStorageServiceProvider);

      if (_isEditMode) {
        final existingPerson = _editingPerson;
        if (existingPerson == null) {
          throw Exception('Existing person data not loaded.');
        }

        String? photoPath = existingPerson.profilePhotoPath;
        if (_pickedPhotoFile != null) {
          photoPath = await imageStorage.saveProfilePhoto(
            sourceFile: _pickedPhotoFile!,
            personId: existingPerson.id,
          );
          if (existingPerson.profilePhotoPath != null &&
              existingPerson.profilePhotoPath != photoPath) {
            await imageStorage.deleteFileIfExists(
              existingPerson.profilePhotoPath!,
            );
          }
        } else if (_profilePhotoPath == null &&
            existingPerson.profilePhotoPath != null) {
          // Photo removed by the user.
          await imageStorage.deleteFileIfExists(
            existingPerson.profilePhotoPath!,
          );
          photoPath = null;
        }

        await repository.updatePerson(
          GenealogyPersonsCompanion(
            id: Value(existingPerson.id),
            firstName: Value(
              _firstNameController.text.trim().isEmpty
                  ? 'Unknown'
                  : _firstNameController.text.trim(),
            ),
            middleName: Value(_emptyToNull(_middleNameController.text)),
            // The form has one surname field; it feeds both the plain surname
            // and the birth surname.
            lastName: Value(_emptyToNull(_birthSurnameController.text)),
            birthSurname: Value(_emptyToNull(_birthSurnameController.text)),
            marriedSurname: Value(_emptyToNull(_marriedSurnameController.text)),
            prefix: Value(_emptyToNull(_prefixController.text)),
            suffix: Value(_emptyToNull(_suffixController.text)),
            nickname: Value(_emptyToNull(_nicknameController.text)),
            gender: Value(_gender),
            birthDate: Value(_birthDate),
            deathDate: Value(_deathDate),
            // Derived from the death date the user just entered, so it is
            // written explicitly rather than defaulting to "alive".
            isLiving: Value(_deathDate == null),
            birthPlace: Value(_emptyToNull(_birthPlaceController.text)),
            currentPlace: Value(_emptyToNull(_currentPlaceController.text)),
            biography: Value(_emptyToNull(_bioController.text)),
            notes: Value(_emptyToNull(_notesController.text)),
            isPrivate: Value(_isPrivate),
            profilePhotoPath: Value(photoPath),
          ),
        );
      } else {
        final personId = await repository.addPerson(
          treeId: AppConstants.defaultTreeId,
          firstName: _firstNameController.text.trim().isEmpty ? 'Unknown' : _firstNameController.text.trim(),
          middleName: _emptyToNull(_middleNameController.text),
          lastName: _emptyToNull(_birthSurnameController.text),
          birthSurname: _emptyToNull(_birthSurnameController.text),
          marriedSurname: _emptyToNull(_marriedSurnameController.text),
          prefix: _emptyToNull(_prefixController.text),
          suffix: _emptyToNull(_suffixController.text),
          nickname: _emptyToNull(_nicknameController.text),
          gender: _gender,
          birthDate: _birthDate,
          deathDate: _deathDate,
          birthPlace: _emptyToNull(_birthPlaceController.text),
          currentPlace: _emptyToNull(_currentPlaceController.text),
          biography: _emptyToNull(_bioController.text),
          notes: _emptyToNull(_notesController.text),
          isPrivate: _isPrivate,
          isLiving: _deathDate == null,
        );

        if (_pickedPhotoFile != null) {
          final savedPhotoPath = await imageStorage.saveProfilePhoto(
            sourceFile: _pickedPhotoFile!,
            personId: personId,
          );

          final createdPerson = await repository.getPersonById(personId);
          if (createdPerson != null) {
            // Attaching a photo touches one column: send only that column
            // instead of echoing the whole row back to the database.
            await repository.updatePerson(
              GenealogyPersonsCompanion(
                id: Value(createdPerson.id),
                profilePhotoPath: Value(savedPhotoPath),
              ),
            );
          }
        }

        final linkedPersonId = widget.linkPersonId;
        final siblingOfPersonId = widget.siblingOfPersonId;
        final relationKind = widget.relationKind;
        if (linkedPersonId != null && relationKind != null) {
          final relationshipRepository = ref.read(
            relationshipRepositoryProvider,
          );

          switch (relationKind) {
            case 'parent':
              await relationshipRepository.addParentChildRelationship(
                treeId: AppConstants.defaultTreeId,
                parentId: personId,
                childId: linkedPersonId,
              );
              break;
            case 'child':
              await relationshipRepository.addParentChildRelationship(
                treeId: AppConstants.defaultTreeId,
                parentId: linkedPersonId,
                childId: personId,
              );

              final spouses = <GenealogyPerson>[];
              if (_selectedSpouseId != null) {
                final GenealogyPerson? spouse = await ref
                    .read(genealogyRepositoryProvider)
                    .getPersonById(_selectedSpouseId!);
                if (spouse != null) spouses.add(spouse);
              } else {
                spouses.addAll(
                  await relationshipRepository.getSpouses(linkedPersonId),
                );
              }

              for (final spouse in spouses) {
                try {
                  await relationshipRepository.addParentChildRelationship(
                    treeId: AppConstants.defaultTreeId,
                    parentId: spouse.id,
                    childId: personId,
                  );
                } catch (_) {
                  // Ignore duplicates when the spouse-child link already exists.
                }
              }
              break;
            case 'spouse':
              await relationshipRepository.addSpouseRelationship(
                treeId: AppConstants.defaultTreeId,
                personAId: linkedPersonId,
                personBId: personId,
              );
              break;
          }
        }

        if (siblingOfPersonId != null) {
          final relationshipRepository = ref.read(
            relationshipRepositoryProvider,
          );
          final parents = <GenealogyPerson>[];
          if (_selectedSiblingParentId != null) {
            final GenealogyPerson? selectedParent = await ref
                .read(genealogyRepositoryProvider)
                .getPersonById(_selectedSiblingParentId!);
            if (selectedParent != null) {
              parents.add(selectedParent);
            }
          } else {
            parents.addAll(
              await relationshipRepository.getParents(siblingOfPersonId),
            );
          }

          for (final parent in parents) {
            try {
              await relationshipRepository.addParentChildRelationship(
                treeId: AppConstants.defaultTreeId,
                parentId: parent.id,
                childId: personId,
              );
            } catch (_) {
              // Ignore duplicate parent-child links when one already exists.
            }
          }
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Person updated successfully.'
                : 'Person added successfully.',
          ),
        ),
      );

      if (_isEditMode) {
        context.go('/people/${widget.personId}');
      } else if (widget.linkPersonId != null) {
        context.go(widget.returnTo ?? '/people/${widget.linkPersonId}');
      } else {
        if (widget.returnTo != null && widget.returnTo!.isNotEmpty) {
          context.go(widget.returnTo!);
        } else {
          context.pop();
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save person: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat =
        ref.watch(dateDisplayFormatProvider).value ?? dateDisplayFormatDefault;
    if (_isEditMode) {
      final personAsync = ref.watch(personByIdProvider(widget.personId!));
      return personAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Edit Person')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => Scaffold(
          appBar: AppBar(title: const Text('Edit Person')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Failed to load person:\n$error',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        data: (person) {
          if (person == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit Person')),
              body: const Center(child: Text('Person not found')),
            );
          }
          _loadPersonIntoForm(person);
          final AsyncValue<List<GenealogyPerson>>? parentAsync =
              widget.relationKind == 'sibling' &&
                  widget.siblingOfPersonId != null
              ? ref.watch(parentsProvider(widget.siblingOfPersonId!))
              : null;
          return _buildForm(dateFormat, parentAsync: parentAsync);
        },
      );
    }

    if (widget.linkPersonId != null) {
      final linkedPersonAsync = ref.watch(
        personByIdProvider(widget.linkPersonId!),
      );
      return linkedPersonAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: Text(_addPersonTitle())),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => Scaffold(
          appBar: AppBar(title: Text(_addPersonTitle())),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Failed to load linked person:\n$error',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        data: (linkedPerson) {
          if (linkedPerson != null) {
            unawaited(_applyRelationshipPrefill(linkedPerson));
          }
          final AsyncValue<List<GenealogyPerson>>? parentAsync =
              widget.relationKind == 'sibling' &&
                  widget.siblingOfPersonId != null
              ? ref.watch(parentsProvider(widget.siblingOfPersonId!))
              : null;
          return _buildForm(dateFormat, parentAsync: parentAsync);
        },
      );
    }

    return _buildForm(dateFormat);
  }

  Widget _buildForm(
    DateDisplayFormat dateFormat, {
    AsyncValue<List<GenealogyPerson>>? parentAsync,
  }) {
    final isDeceased = _deathDate != null;
    final relationSummary = _relationshipSummary();
    final siblingNotice = _relationshipSiblingNotice(parentAsync);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Person' : _addPersonTitle()),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (relationSummary != null) ...[
                _RelationshipIntentCard(summary: relationSummary),
                const SizedBox(height: 16),
              ],
              if (siblingNotice != null) ...[
                _RelationshipWarningCard(
                  title: siblingNotice.title,
                  message: siblingNotice.message,
                  child: siblingNotice.child,
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                'Basic Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              _ProfilePhotoPicker(
                photoPath: _pickedPhotoFile?.path ?? _profilePhotoPath,
                onPickPhoto: _pickProfilePhoto,
                onRemovePhoto: _removeProfilePhoto,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _prefixController,
                decoration: const InputDecoration(
                  labelText: 'Prefix',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _middleNameController,
                decoration: const InputDecoration(
                  labelText: 'Middle Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _birthSurnameController,
                decoration: const InputDecoration(
                  labelText: 'Birth Surname',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              if (_gender == 'female') ...[
                TextFormField(
                  controller: _marriedSurnameController,
                  decoration: const InputDecoration(
                    labelText: 'Married Surname',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _suffixController,
                decoration: const InputDecoration(
                  labelText: 'Suffix',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Nickname',
                  prefixIcon: Icon(Icons.tag_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullNameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: const Icon(Icons.person_outline),
                  helperText: _fullNameManuallyEdited
                      ? 'Manual override active'
                      : 'Auto-composed from first, middle, and last name',
                  suffixIcon: _fullNameManuallyEdited
                      ? IconButton(
                          tooltip: 'Reset to auto-composed name',
                          onPressed: _resetFullNameOverride,
                          icon: const Icon(Icons.sync_outlined),
                        )
                      : const Icon(Icons.auto_mode_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter full name';
                  }
                  if (value.trim().length < 2) return 'Name is too short';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender *',
                  prefixIcon: Icon(Icons.wc_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _gender = value);
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.lock_outline),
                title: const Text('Private person'),
                subtitle: const Text(
                  'Hide this profile from shared or future public views.',
                ),
                value: _isPrivate,
                onChanged: (value) => setState(() => _isPrivate = value),
              ),
              const SizedBox(height: 24),
              const Text(
                'Life Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              _DateTile(
                title: 'Birth Date',
                value: _birthDate == null
                    ? 'Select date'
                    : formatDateForDisplay(_birthDate, dateFormat),
                icon: Icons.cake_outlined,
                onTap: _pickBirthDate,
                onClear: _birthDate == null
                    ? null
                    : () => setState(() => _birthDate = null),
              ),
              const SizedBox(height: 8),
              _DateTile(
                title: 'Death Date',
                value: _deathDate == null
                    ? 'Select date'
                    : formatDateForDisplay(_deathDate, dateFormat),
                icon: Icons.event_busy_outlined,
                onTap: _pickDeathDate,
                onClear: _deathDate == null
                    ? null
                    : () => setState(() => _deathDate = null),
              ),
              if (isDeceased) ...[
                const SizedBox(height: 8),
                const Text(
                  'This person will be marked as deceased.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _birthPlaceController,
                    decoration: InputDecoration(
                      labelText: 'Birth Place',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      suffixIcon: _isSearchingBirthPlaces
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      unawaited(_searchBirthPlaces(value));
                    },
                  ),
                  if (_placeSuggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _placeSuggestions.map((place) {
                        return ActionChip(
                          label: Text(place),
                          onPressed: () {
                            setState(() {
                              _birthPlaceController.text = place;
                              _placeSuggestions = const [];
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currentPlaceController,
                decoration: InputDecoration(
                  labelText: 'Current Place',
                  prefixIcon: const Icon(Icons.home_outlined),
                  suffixIcon: IconButton(
                    tooltip: 'Use current location',
                    onPressed: _isResolvingCurrentPlace
                        ? null
                        : _useCurrentLocation,
                    icon: _isResolvingCurrentPlace
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Life Story / Notes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Bio / Notes',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: 'Private Notes',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _isSaving ? null : _savePerson,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Saving...' : 'Save Person'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isSaving
                    ? null
                    : () => context.go(
                        _isEditMode ? '/people/${widget.personId}' : '/people',
                      ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _addPersonTitle() {
    final relationKind = widget.relationKind;
    final label = switch (relationKind) {
      'parent' => widget.initialGender == 'female' ? 'Mother' : 'Father',
      'child' => widget.initialGender == 'female' ? 'Daughter' : 'Son',
      'sibling' => widget.initialGender == 'female' ? 'Sister' : 'Brother',
      'spouse' => 'Spouse',
      _ => 'Person',
    };
    return 'Add Person as $label';
  }

  String? _relationshipSummary() {
    final linkedPersonId = widget.linkPersonId;
    final relationKind = widget.relationKind;

    if (linkedPersonId == null || relationKind == null) return null;

    switch (relationKind) {
      case 'parent':
        return 'This new person will be linked as a parent of the selected person after saving.';
      case 'child':
        return 'This new person will be linked as a son or daughter of the selected person after saving.';
      case 'sibling':
        return 'This new person will be linked as a sibling by sharing the same shared parents after saving.';
      case 'spouse':
        return 'This new person will be linked as a spouse after saving.';
      default:
        return null;
    }
  }

  _RelationshipNotice? _relationshipSiblingNotice(
    AsyncValue<List<GenealogyPerson>>? parentAsync,
  ) {
    if (widget.relationKind != 'sibling') return null;
    final parents = parentAsync?.asData?.value ?? const <GenealogyPerson>[];

    if (parents.isEmpty) {
      return const _RelationshipNotice(
        title: 'No parents linked',
        message:
            'This sibling can only be attached automatically if the selected person already has parent links.',
      );
    }

    if (parents.length == 1) {
      _selectedSiblingParentId = parents.first.id;
      return _RelationshipNotice(
        title: 'Shared parent detected',
        message:
            'This sibling will be linked through the same shared parent after saving.',
      );
    }

    _selectedSiblingParentId ??= parents.first.id;
    return _RelationshipNotice(
      title: 'Choose shared parent',
      message:
          'The selected person has more than one parent link. Pick the shared parent to anchor the sibling save.',
      child: DropdownButtonFormField<String>(
        initialValue: _selectedSiblingParentId,
        decoration: const InputDecoration(
          labelText: 'Shared parent',
          prefixIcon: Icon(Icons.family_restroom_outlined),
        ),
        items: parents.map((parent) {
          return DropdownMenuItem(
            value: parent.id,
            child: Text(parent.fullName),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedSiblingParentId = value;
          });
        },
      ),
    );
  }
}

class _RelationshipNotice {
  const _RelationshipNotice({
    required this.title,
    required this.message,
    this.child,
  });

  final String title;
  final String message;
  final Widget? child;
}

class _RelationshipIntentCard extends StatelessWidget {
  const _RelationshipIntentCard({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.link_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                summary,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RelationshipWarningCard extends StatelessWidget {
  const _RelationshipWarningCard({
    required this.title,
    required this.message,
    this.child,
  });

  final String title;
  final String message;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(message),
            if (child != null) ...[const SizedBox(height: 12), child!],
          ],
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
    this.onClear,
  });

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
        trailing: onClear == null
            ? const Icon(Icons.calendar_month_outlined)
            : IconButton(onPressed: onClear, icon: const Icon(Icons.close)),
        onTap: onTap,
      ),
    );
  }
}

class _ProfilePhotoPicker extends StatelessWidget {
  const _ProfilePhotoPicker({
    required this.photoPath,
    required this.onPickPhoto,
    required this.onRemovePhoto,
  });

  final String? photoPath;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null && photoPath!.trim().isNotEmpty;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 42,
              backgroundImage: hasPhoto ? FileImage(File(photoPath!)) : null,
              child: hasPhoto
                  ? null
                  : const Icon(Icons.person_outline, size: 38),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile Photo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: onPickPhoto,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(hasPhoto ? 'Change' : 'Add Photo'),
                      ),
                      if (hasPhoto)
                        OutlinedButton.icon(
                          onPressed: onRemovePhoto,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Remove'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
