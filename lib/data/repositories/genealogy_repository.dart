import 'package:drift/drift.dart';

import '../../core/utils/id_generator.dart';
import '../database/app_database.dart';
import '../database/daos/genealogy_person_dao.dart';
import '../../features/duplicates/duplicate_detection_providers.dart';

class GenealogyRepository {
  GenealogyRepository(this._database);

  final AppDatabase _database;

  GenealogyPersonDao get _personDao => _database.genealogyPersonDao;

  Future<String> addPerson({
    required String treeId,
    required String firstName,
    String? middleName,
    String? lastName,
    String? birthSurname,
    String? marriedSurname,
    String? prefix,
    String? suffix,
    String? nickname,
    required String gender,
    DateTime? birthDate,
    String? birthDateQualifier,
    String? birthPlace,
    double? birthPlaceLat,
    double? birthPlaceLng,
    String? currentPlace,
    DateTime? deathDate,
    String? deathDateQualifier,
    String? deathPlace,
    double? deathPlaceLat,
    double? deathPlaceLng,
    bool isLiving = true,
    String? biography,
    String? notes,
    String? occupation,
    String? religion,
    String? ethnicity,
    bool isPrivate = false,
    int privacyLevel = 0,
    String displayNameFormat = 'birth_married',
    String? customDisplayName,
    String? mergedIntoId,
    String? profilePhotoPath,
  }) async {
    final id = IdGenerator.newId();
    final now = DateTime.now();
    final uuid = IdGenerator.newId();

    await _personDao.createPerson(
      GenealogyPersonsCompanion.insert(
        id: id,
        firstName: firstName.trim(),
        treeId: treeId,
        gender: gender,
        uuid: uuid,
        createdAt: Value(now),
        updatedAt: Value(now),
        middleName: Value(middleName?.trim()),
        lastName: Value(lastName?.trim()),
        birthSurname: Value(birthSurname?.trim()),
        marriedSurname: Value(marriedSurname?.trim()),
        prefix: Value(prefix?.trim()),
        suffix: Value(suffix?.trim()),
        nickname: Value(nickname?.trim()),
        birthDate: Value(birthDate),
        birthDateQualifier: Value(birthDateQualifier?.trim()),
        birthPlace: Value(birthPlace?.trim()),
        birthPlaceLat: Value(birthPlaceLat),
        birthPlaceLng: Value(birthPlaceLng),
        currentPlace: Value(currentPlace?.trim()),
        profilePhotoPath: Value(profilePhotoPath?.trim()),
        deathDate: Value(deathDate),
        deathDateQualifier: Value(deathDateQualifier?.trim()),
        deathPlace: Value(deathPlace?.trim()),
        deathPlaceLat: Value(deathPlaceLat),
        deathPlaceLng: Value(deathPlaceLng),
        isLiving: Value(isLiving),
        biography: Value(biography?.trim()),
        notes: Value(notes?.trim()),
        occupation: Value(occupation?.trim()),
        religion: Value(religion?.trim()),
        ethnicity: Value(ethnicity?.trim()),
        isPrivate: Value(isPrivate),
        privacyLevel: Value(privacyLevel),
        displayNameFormat: Value(displayNameFormat),
        customDisplayName: Value(customDisplayName?.trim()),
        syncStatus: const Value('pending'),
        isDeleted: const Value(false),
        version: const Value(1),
        mergedIntoId: Value(mergedIntoId),
      ),
    );

    return id;
  }

  Future<void> updatePerson({
    required String id,
    required String treeId,
    required String firstName,
    String? middleName,
    String? lastName,
    String? birthSurname,
    String? marriedSurname,
    String? prefix,
    String? suffix,
    String? nickname,
    required String gender,
    DateTime? birthDate,
    String? birthDateQualifier,
    String? birthPlace,
    double? birthPlaceLat,
    double? birthPlaceLng,
    String? currentPlace,
    DateTime? deathDate,
    String? deathDateQualifier,
    String? deathPlace,
    double? deathPlaceLat,
    double? deathPlaceLng,
    bool isLiving = true,
    String? biography,
    String? notes,
    String? occupation,
    String? religion,
    String? ethnicity,
    bool isPrivate = false,
    int privacyLevel = 0,
    String displayNameFormat = 'birth_married',
    String? customDisplayName,
    String? mergedIntoId,
    String? profilePhotoPath,
  }) async {
    final now = DateTime.now();

    await _personDao.updatePerson(
      GenealogyPersonsCompanion(
        id: Value(id),
        firstName: Value(firstName.trim()),
        treeId: Value(treeId),
        gender: Value(gender),
        updatedAt: Value(now),
        middleName: Value(middleName?.trim()),
        lastName: Value(lastName?.trim()),
        birthSurname: Value(birthSurname?.trim()),
        marriedSurname: Value(marriedSurname?.trim()),
        prefix: Value(prefix?.trim()),
        suffix: Value(suffix?.trim()),
        nickname: Value(nickname?.trim()),
        birthDate: Value(birthDate),
        birthDateQualifier: Value(birthDateQualifier?.trim()),
        birthPlace: Value(birthPlace?.trim()),
        birthPlaceLat: Value(birthPlaceLat),
        birthPlaceLng: Value(birthPlaceLng),
        currentPlace: Value(currentPlace?.trim()),
        profilePhotoPath: Value(profilePhotoPath?.trim()),
        deathDate: Value(deathDate),
        deathDateQualifier: Value(deathDateQualifier?.trim()),
        deathPlace: Value(deathPlace?.trim()),
        deathPlaceLat: Value(deathPlaceLat),
        deathPlaceLng: Value(deathPlaceLng),
        isLiving: Value(isLiving),
        biography: Value(biography?.trim()),
        notes: Value(notes?.trim()),
        occupation: Value(occupation?.trim()),
        religion: Value(religion?.trim()),
        ethnicity: Value(ethnicity?.trim()),
        isPrivate: Value(isPrivate),
        privacyLevel: Value(privacyLevel),
        displayNameFormat: Value(displayNameFormat),
        customDisplayName: Value(customDisplayName?.trim()),
        mergedIntoId: Value(mergedIntoId),
      ),
    );
  }

  Future<int> deletePerson(String personId) {
    return _personDao.deletePerson(personId);
  }

  Future<GenealogyPerson?> getPersonById(String id) => _personDao.getPersonById(id);

  Stream<GenealogyPerson?> watchPersonById(String id) => _personDao.watchPersonById(id);

  Stream<List<GenealogyPerson>> watchPeopleByTree(String treeId) =>
      _personDao.watchPeopleByTree(treeId);

  Future<List<GenealogyPerson>> searchPeople({
    required String treeId,
    required String query,
  }) =>
      _personDao.searchPeople(treeId: treeId, query: query);

  Future<List<GenealogyPerson>> getPeopleByTree(String treeId) => _personDao.getPeopleByTree(treeId);

  Future<List<DuplicateMarker>> getDuplicateMarkers(String treeId) async {
    return _database.select(_database.duplicateMarkers).get();
  }

  Future<void> markAsDuplicate({
    required String treeId,
    required String sourceId,
    required String targetId,
    String? reason,
  }) async {
    await _database.into(_database.duplicateMarkers).insert(
      DuplicateMarkersCompanion.insert(
        id: IdGenerator.newId(),
        personAId: sourceId,
        personBId: targetId,
        treeId: treeId,
        reason: Value(reason),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> deleteDuplicateMarker({
    required String personAId,
    required String personBId,
  }) async {
    await (_database.delete(_database.duplicateMarkers)
          ..where((t) =>
              (t.personAId.equals(personAId) & t.personBId.equals(personBId)) |
              (t.personAId.equals(personBId) & t.personBId.equals(personAId))))
        .go();
  }

  Future<DuplicateMergePreview> getMergePreview({
    required String survivorId,
    required String duplicateId,
  }) async {
    final eventCount = (await (_database.select(_database.events)
            ..where((t) => t.personId.equals(duplicateId)))
          .get())
        .length;
    final noteCount = (await (_database.select(_database.researchNotes)
            ..where((t) => t.personId.equals(duplicateId)))
          .get())
        .length;
    final mediaCount = (await (_database.select(_database.mediaItems)
            ..where((t) => t.personId.equals(duplicateId)))
          .get())
        .length;
    final families = await _personDao.getFamiliesForPerson(duplicateId);
    final childLinks = (await (_database.select(_database.familyChildrenV2)
            ..where(
              (t) =>
                  t.childId.equals(duplicateId) & t.isDeleted.equals(false),
            ))
          .get())
        .length;

    return DuplicateMergePreview(
      eventCount: eventCount,
      noteCount: noteCount,
      mediaCount: mediaCount,
      relationshipCount: families.length + childLinks,
    );
  }

  Future<void> mergePeople({
    required String survivorId,
    required String duplicateId,
    String? preferredBirthDateSource,
    String? preferredDeathDateSource,
    String? preferredBirthPlaceSource,
    String? preferredCurrentPlaceSource,
    String? preferredBioSource,
    String? preferredNotesSource,
  }) async {
    if (survivorId == duplicateId) {
      throw ArgumentError('Cannot merge a person into themselves.');
    }

    final survivor = await _personDao.getPersonById(survivorId);
    final duplicate = await _personDao.getPersonById(duplicateId);
    if (survivor == null || duplicate == null) {
      throw ArgumentError('Both people must exist to merge them.');
    }

    final now = DateTime.now();

    // Merge the duplicate's relationships onto the survivor.
    final duplicateFamilies = await _personDao.getFamiliesForPerson(duplicateId);
    for (final family in duplicateFamilies) {
      final survivorIsPartner =
          family.husbandId == survivorId || family.wifeId == survivorId;
      final reassignedSlot = survivorIsPartner ? null : survivorId;
      if (family.husbandId == duplicateId) {
        await (_database.update(_database.familiesV2)
              ..where((t) => t.id.equals(family.id)))
            .write(FamiliesV2Companion(husbandId: Value(reassignedSlot)));
      } else {
        await (_database.update(_database.familiesV2)
              ..where((t) => t.id.equals(family.id)))
            .write(FamiliesV2Companion(wifeId: Value(reassignedSlot)));
      }
    }

    final duplicateChildLinks = await (_database.select(_database.familyChildrenV2)
          ..where(
            (t) =>
                t.childId.equals(duplicateId) & t.isDeleted.equals(false),
          ))
        .get();
    for (final link in duplicateChildLinks) {
      final survivorAlreadyChild =
          await (_database.select(_database.familyChildrenV2)
                ..where(
                  (t) =>
                      t.familyId.equals(link.familyId) &
                      t.childId.equals(survivorId) &
                      t.isDeleted.equals(false),
                ))
              .getSingleOrNull();
      if (survivorAlreadyChild != null) {
        await (_database.delete(_database.familyChildrenV2)
              ..where((t) => t.id.equals(link.id)))
            .go();
      } else {
        await (_database.update(_database.familyChildrenV2)
              ..where((t) => t.id.equals(link.id)))
            .write(FamilyChildrenV2Companion(childId: Value(survivorId)));
      }
    }

    // Repoint all person-scoped records from the duplicate to the survivor.
    await (_database.update(_database.surnameEvents)
          ..where((t) => t.personId.equals(duplicateId)))
        .write(SurnameEventsCompanion(
          personId: Value(survivorId),
          updatedAt: Value(now),
        ));
    await (_database.update(_database.events)
          ..where((t) => t.personId.equals(duplicateId)))
        .write(EventsCompanion(
          personId: Value(survivorId),
          updatedAt: Value(now),
        ));
    await (_database.update(_database.mediaItems)
          ..where((t) => t.personId.equals(duplicateId)))
        .write(MediaItemsCompanion(personId: Value(survivorId)));
    await (_database.update(_database.researchNotes)
          ..where((t) => t.personId.equals(duplicateId)))
        .write(ResearchNotesCompanion(personId: Value(survivorId)));

    // Merge data fields into the survivor, then soft-delete the duplicate.
    final gender = _pickGender(survivor.gender, duplicate.gender);
    await (_database.update(_database.genealogyPersons)
          ..where((t) => t.id.equals(survivorId)))
        .write(
      GenealogyPersonsCompanion(
        firstName: Value(
          _keep(survivor.firstName, duplicate.firstName) ?? survivor.firstName,
        ),
        middleName: Value(_keep(survivor.middleName, duplicate.middleName)),
        lastName: Value(_keep(survivor.lastName, duplicate.lastName)),
        birthSurname: Value(_keep(survivor.birthSurname, duplicate.birthSurname)),
        marriedSurname: Value(
          _keep(survivor.marriedSurname, duplicate.marriedSurname),
        ),
        prefix: Value(_keep(survivor.prefix, duplicate.prefix)),
        suffix: Value(_keep(survivor.suffix, duplicate.suffix)),
        nickname: Value(_keep(survivor.nickname, duplicate.nickname)),
        gender: Value(gender),
        birthDate: Value(
          _preferDate(
            survivor.birthDate,
            duplicate.birthDate,
            preferredBirthDateSource,
          ),
        ),
        birthDateQualifier: Value(
          _keep(survivor.birthDateQualifier, duplicate.birthDateQualifier),
        ),
        birthPlace: Value(
          _preferString(
            survivor.birthPlace,
            duplicate.birthPlace,
            preferredBirthPlaceSource,
          ),
        ),
        birthPlaceLat: Value(
          survivor.birthPlaceLat ?? duplicate.birthPlaceLat,
        ),
        birthPlaceLng: Value(
          survivor.birthPlaceLng ?? duplicate.birthPlaceLng,
        ),
        deathDate: Value(
          _preferDate(
            survivor.deathDate,
            duplicate.deathDate,
            preferredDeathDateSource,
          ),
        ),
        deathDateQualifier: Value(
          _keep(survivor.deathDateQualifier, duplicate.deathDateQualifier),
        ),
        deathPlace: Value(_keep(survivor.deathPlace, duplicate.deathPlace)),
        deathPlaceLat: Value(survivor.deathPlaceLat ?? duplicate.deathPlaceLat),
        deathPlaceLng: Value(survivor.deathPlaceLng ?? duplicate.deathPlaceLng),
        currentPlace: Value(
          _preferString(
            survivor.currentPlace,
            duplicate.currentPlace,
            preferredCurrentPlaceSource,
          ),
        ),
        biography: Value(
          _preferString(
            survivor.biography,
            duplicate.biography,
            preferredBioSource,
          ),
        ),
        notes: Value(
          _preferString(
            survivor.notes,
            duplicate.notes,
            preferredNotesSource,
          ),
        ),
        profilePhotoPath: Value(
          _keep(survivor.profilePhotoPath, duplicate.profilePhotoPath),
        ),
        isLiving: Value(survivor.isLiving),
        isPrivate: Value(survivor.isPrivate),
        privacyLevel: Value(survivor.privacyLevel),
        updatedAt: Value(now),
      ),
    );

    await (_database.update(_database.genealogyPersons)
          ..where((t) => t.id.equals(duplicateId)))
        .write(
      GenealogyPersonsCompanion(
        isDeleted: const Value(true),
        mergedIntoId: Value(survivorId),
        updatedAt: Value(now),
      ),
    );

    // Clear duplicate markers involving either person.
    await (_database.delete(_database.duplicateMarkers)
          ..where(
            (t) =>
                t.personAId.equals(survivorId) |
                t.personBId.equals(survivorId) |
                t.personAId.equals(duplicateId) |
                t.personBId.equals(duplicateId),
          ))
        .go();
  }

  static String? _keep(String? survivor, String? duplicate) {
    final s = _nonEmpty(survivor);
    if (s != null) return s;
    return _nonEmpty(duplicate);
  }

  static String? _preferString(
    String? survivor,
    String? duplicate,
    String? source,
  ) {
    final s = _nonEmpty(survivor);
    final d = _nonEmpty(duplicate);
    if (source == 'secondary') return d ?? s;
    return s ?? d;
  }

  static DateTime? _preferDate(
    DateTime? survivor,
    DateTime? duplicate,
    String? source,
  ) {
    if (source == 'secondary') return duplicate ?? survivor;
    return survivor ?? duplicate;
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  static String _pickGender(String survivorGender, String duplicateGender) {
    final s = survivorGender.trim().toUpperCase();
    final d = duplicateGender.trim().toUpperCase();
    if (s == 'U' || s == 'UNKNOWN') {
      if (d == 'M' || d == 'F' || d == 'MALE' || d == 'FEMALE') {
        return duplicateGender;
      }
    }
    return survivorGender;
  }

  Stream<List<SurnameEvent>> watchSurnameHistory(String personId) =>
      _personDao.watchSurnameHistory(personId);

  Stream<List<FamiliesV2Data>> watchFamiliesForPerson(String personId) =>
      _personDao.watchFamiliesForPerson(personId);

  Future<List<FamiliesV2Data>> getFamiliesForPerson(String personId) =>
      _personDao.getFamiliesForPerson(personId);

  Stream<List<FamilyChildrenV2Data>> watchChildrenForFamily(String familyId) =>
      _personDao.watchChildrenForFamily(familyId);

  Future<List<FamilyChildrenV2Data>> getChildrenForFamily(String familyId) =>
      _personDao.getChildrenForFamily(familyId);

  Future<String> createFamily({
    required String treeId,
    String? husbandId,
    String? wifeId,
    DateTime? marriageDate,
    String? marriageDateQualifier,
    String? marriagePlace,
    double? marriagePlaceLat,
    double? marriagePlaceLng,
    bool wifeTookHusbandName = false,
    bool husbandTookWifeName = false,
    bool hyphenatedSurname = false,
    bool noNameChange = false,
    String? customSurnameChange,
    String? wifeMarriedSurname,
    String? wifeNameChangeType,
    String? husbandMarriedSurname,
    String? husbandNameChangeType,
    bool isPrimaryMarriage = false,
    String? notes,
    String? privateNotes,
  }) async {
    final id = IdGenerator.newId();
    final now = DateTime.now();
    final uuid = IdGenerator.newId();

    await _personDao.createFamily(
      FamiliesV2Companion.insert(
        id: id,
        husbandId: Value(husbandId),
        wifeId: Value(wifeId),
        marriageDate: Value(marriageDate),
        marriageDateQualifier: Value(marriageDateQualifier?.trim()),
        marriagePlace: Value(marriagePlace?.trim()),
        marriagePlaceLat: Value(marriagePlaceLat),
        marriagePlaceLng: Value(marriagePlaceLng),
        wifeTookHusbandName: Value(wifeTookHusbandName),
        husbandTookWifeName: Value(husbandTookWifeName),
        hyphenatedSurname: Value(hyphenatedSurname),
        customSurnameChange: Value(customSurnameChange?.trim()),
        noNameChange: Value(noNameChange),
        wifeMarriedSurname: Value(wifeMarriedSurname?.trim()),
        wifeNameChangeType: Value(wifeNameChangeType?.trim()),
        husbandMarriedSurname: Value(husbandMarriedSurname?.trim()),
        husbandNameChangeType: Value(husbandNameChangeType?.trim()),
        isPrimaryMarriage: Value(isPrimaryMarriage),
        notes: Value(notes?.trim()),
        privateNotes: Value(privateNotes?.trim()),
        uuid: uuid,
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    return id;
  }

  Future<String> addChildToFamily({
    required String familyId,
    required String childId,
    int? birthOrder,
    String relationshipType = 'biological',
    String? childSurnameAtBirth,
    String? paternalRelationship,
    String? maternalRelationship,
    String? notes,
  }) async {
    final id = IdGenerator.newId();
    final now = DateTime.now();
    final uuid = IdGenerator.newId();

    await _personDao.createFamilyChild(
      FamilyChildrenV2Companion.insert(
        id: id,
        familyId: familyId,
        childId: childId,
        birthOrder: Value(birthOrder),
        relationshipType: Value(relationshipType),
        childSurnameAtBirth: Value(childSurnameAtBirth?.trim()),
        paternalRelationship: Value(paternalRelationship?.trim()),
        maternalRelationship: Value(maternalRelationship?.trim()),
        notes: Value(notes?.trim()),
        uuid: uuid,
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    return id;
  }
}
