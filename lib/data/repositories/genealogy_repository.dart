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

  /// Applies a **partial** update to a person.
  ///
  /// [changes] must carry the person id; only the columns present in the
  /// companion are written. Callers supply every field they intend to change —
  /// there is no "copy the rest from the current row" fallback, because that is
  /// exactly the behaviour that made an edit silently reset unrelated columns.
  ///
  /// `updated_at` is set here so no caller can forget it.
  Future<bool> updatePerson(GenealogyPersonsCompanion changes) async {
    final id = changes.id.present ? changes.id.value : null;
    if (id == null || id.isEmpty) {
      throw ArgumentError(
        'updatePerson requires a companion carrying the person id.',
      );
    }

    final rows = await _personDao.updatePersonFields(
      id,
      changes.copyWith(updatedAt: Value(DateTime.now())),
    );
    return rows > 0;
  }

  /// Removes [personId] from the tree (soft delete), in one transaction.
  ///
  /// Rules:
  ///  * the person row is flagged `is_deleted`;
  ///  * child links where the person is the child are flagged `is_deleted`;
  ///  * a family that exists only for this person (its other partner slot is
  ///    empty) is soft-deleted together with its remaining child links;
  ///  * a family shared with a partner is KEPT, so the surviving spouse's
  ///    marriage and the children's place in the tree survive. The deleted
  ///    person is filtered out of every read path instead.
  ///
  /// Person-scoped rows (events, media, notes, todos) are intentionally left
  /// alone: they are unreachable while the person is deleted, and they come
  /// back if the delete is reverted.
  Future<void> deletePerson(String personId) async {
    final person = await _personDao.getPersonById(personId);
    if (person == null) {
      throw ArgumentError('Person not found: $personId');
    }
    if (person.isDeleted) return;

    final now = DateTime.now();
    await _database.transaction(() async {
      final childLinks = await (_database.select(_database.familyChildrenV2)
            ..where(
              (t) =>
                  t.childId.equals(personId) & t.isDeleted.equals(false),
            ))
          .get();
      for (final link in childLinks) {
        await _personDao.markFamilyChildDeleted(link.id, now);
      }

      for (final family in await _personDao.getFamiliesForPerson(personId)) {
        final partnerId =
            family.husbandId == personId ? family.wifeId : family.husbandId;
        if (partnerId != null) continue; // shared family survives

        for (final link in await _personDao.getChildrenForFamily(family.id)) {
          await _personDao.markFamilyChildDeleted(link.id, now);
        }
        await _personDao.markFamilyDeleted(family.id, now);
      }

      await _personDao.markPersonDeleted(personId, now);
    });
  }

  /// Reverts a soft delete of the person row itself.
  ///
  /// Family links that [deletePerson] removed are not restored here: without an
  /// audit trail there is no way to tell a link that was deleted by the cascade
  /// from one the user removed deliberately. Restoring links is a Phase 5
  /// concern (restore/purge semantics).
  Future<void> restorePerson(String personId) async {
    final person = await _personDao.getPersonById(personId);
    if (person == null) {
      throw ArgumentError('Person not found: $personId');
    }
    await _personDao.restorePerson(personId, DateTime.now());
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

  /// Duplicate markers for [treeId], excluding markers whose people have been
  /// deleted (or merged away).
  Future<List<DuplicateMarker>> getDuplicateMarkers(String treeId) async {
    final markers = await (_database.select(_database.duplicateMarkers)
          ..where((t) => t.treeId.equals(treeId)))
        .get();
    if (markers.isEmpty) return const [];

    final live = (await _personDao.getLivePeopleByIds([
      for (final m in markers) ...[m.personAId, m.personBId],
    ]))
        .map((p) => p.id)
        .toSet();

    return markers
        .where((m) => live.contains(m.personAId) && live.contains(m.personBId))
        .toList();
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
    if (survivor.isDeleted) {
      throw ArgumentError('The survivor has been deleted: $survivorId');
    }
    if (duplicate.isDeleted) {
      throw ArgumentError(
        'The duplicate has already been deleted: $duplicateId',
      );
    }

    final now = DateTime.now();

    // A merge rewrites families, child links, person-scoped rows and both
    // person rows. It has to be all-or-nothing: a half-applied merge cannot be
    // repaired by the user.
    await _database.transaction(() async {
      // 1. Move the duplicate's partner slots onto the survivor. A family that
      //    already contains the survivor keeps the survivor's existing slot.
      final duplicateFamilies =
          await _personDao.getFamiliesForPerson(duplicateId);
      for (final family in duplicateFamilies) {
        final survivorIsPartner =
            family.husbandId == survivorId || family.wifeId == survivorId;
        final reassignedSlot = survivorIsPartner ? null : survivorId;
        await _personDao.updateFamilyFields(
          family.id,
          family.husbandId == duplicateId
              ? FamiliesV2Companion(husbandId: Value(reassignedSlot))
              : FamiliesV2Companion(wifeId: Value(reassignedSlot)),
        );
      }

    final duplicateChildLinks = await (_database.select(_database.familyChildrenV2)
          ..where(
            (t) =>
                t.childId.equals(duplicateId) & t.isDeleted.equals(false),
          ))
        .get();
    for (final link in duplicateChildLinks) {
      // `UNIQUE(family_id, child_id)` ignores soft delete, so this clash check
      // must consider ALL rows for (family, survivor), not just live ones.
      final existing =
          await _personDao.getFamilyChildLink(link.familyId, survivorId);
      if (existing != null) {
        if (existing.isDeleted) {
          // A live link is about to exist for this pair again, so un-delete it.
          await _personDao.restoreFamilyChild(existing.id, now);
        }
        await _personDao.removeFamilyChildLinkRow(link.id);
      } else {
        await _personDao.updateFamilyChildFields(
          link.id,
          FamilyChildrenV2Companion(
            childId: Value(survivorId),
            updatedAt: Value(now),
          ),
        );
      }
    }

      // 3. Repoint every row that references the duplicate.
      await (_database.update(_database.surnameEvents)
            ..where((t) => t.personId.equals(duplicateId)))
          .write(
        SurnameEventsCompanion(
          personId: Value(survivorId),
          updatedAt: Value(now),
        ),
      );
      await (_database.update(_database.surnameEvents)
            ..where((t) => t.relatedPersonId.equals(duplicateId)))
          .write(
        SurnameEventsCompanion(
          relatedPersonId: Value(survivorId),
          updatedAt: Value(now),
        ),
      );
      await (_database.update(_database.events)
            ..where((t) => t.personId.equals(duplicateId)))
          .write(
        EventsCompanion(personId: Value(survivorId), updatedAt: Value(now)),
      );
      await (_database.update(_database.mediaItems)
            ..where((t) => t.personId.equals(duplicateId)))
          .write(MediaItemsCompanion(personId: Value(survivorId)));
      await (_database.update(_database.researchNotes)
            ..where((t) => t.personId.equals(duplicateId)))
          .write(ResearchNotesCompanion(personId: Value(survivorId)));
      await _repointCitationLinks(duplicateId, survivorId);

      // 4. Merge the duplicate's data into the survivor. Every field the model
      //    carries is considered, so nothing is dropped silently.
      final mergedBirthDate = _preferDate(
        survivor.birthDate,
        duplicate.birthDate,
        preferredBirthDateSource,
      );
      final mergedDeathDate = _preferDate(
        survivor.deathDate,
        duplicate.deathDate,
        preferredDeathDateSource,
      );
      final mergedGender = _pickGender(survivor.gender, duplicate.gender);

      await _personDao.updatePersonFields(
        survivorId,
        GenealogyPersonsCompanion(
          firstName: Value(
            _keep(survivor.firstName, duplicate.firstName) ??
                survivor.firstName,
          ),
          middleName: Value(_keep(survivor.middleName, duplicate.middleName)),
          lastName: Value(_keep(survivor.lastName, duplicate.lastName)),
          birthSurname: Value(
            _keep(survivor.birthSurname, duplicate.birthSurname),
          ),
          marriedSurname: Value(
            _keep(survivor.marriedSurname, duplicate.marriedSurname),
          ),
          prefix: Value(_keep(survivor.prefix, duplicate.prefix)),
          suffix: Value(_keep(survivor.suffix, duplicate.suffix)),
          nickname: Value(_keep(survivor.nickname, duplicate.nickname)),
          customDisplayName: Value(
            _keep(survivor.customDisplayName, duplicate.customDisplayName),
          ),
          gender: Value(mergedGender),
          birthDate: Value(mergedBirthDate),
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
          deathDate: Value(mergedDeathDate),
          deathDateQualifier: Value(
            _keep(survivor.deathDateQualifier, duplicate.deathDateQualifier),
          ),
          deathPlace: Value(_keep(survivor.deathPlace, duplicate.deathPlace)),
          deathPlaceLat: Value(
            survivor.deathPlaceLat ?? duplicate.deathPlaceLat,
          ),
          deathPlaceLng: Value(
            survivor.deathPlaceLng ?? duplicate.deathPlaceLng,
          ),
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
          occupation: Value(_keep(survivor.occupation, duplicate.occupation)),
          religion: Value(_keep(survivor.religion, duplicate.religion)),
          ethnicity: Value(_keep(survivor.ethnicity, duplicate.ethnicity)),
          profilePhotoPath: Value(
            _keep(survivor.profilePhotoPath, duplicate.profilePhotoPath),
          ),
          // Life status follows the merged death date rather than keeping the
          // survivor's flag regardless of the data.
          isLiving: Value(mergedDeathDate == null),
          // Privacy is the union of both records, and the stricter level wins.
          isPrivate: Value(survivor.isPrivate || duplicate.isPrivate),
          privacyLevel: Value(
            survivor.privacyLevel >= duplicate.privacyLevel
                ? survivor.privacyLevel
                : duplicate.privacyLevel,
          ),
          updatedAt: Value(now),
        ),
      );

      // 5. Retire the duplicate and clear the markers that mentioned it.
      await _personDao.updatePersonFields(
        duplicateId,
        GenealogyPersonsCompanion(
          isDeleted: const Value(true),
          mergedIntoId: Value(survivorId),
          updatedAt: Value(now),
        ),
      );

      await (_database.delete(_database.duplicateMarkers)
            ..where(
              (t) =>
                  t.personAId.equals(survivorId) |
                  t.personBId.equals(survivorId) |
                  t.personAId.equals(duplicateId) |
                  t.personBId.equals(duplicateId),
            ))
          .go();
    });
  }

  /// Moves `citation_links` rows from [fromPersonId] to [toPersonId].
  ///
  /// `citation_links` has the composite primary key
  /// `(citation_id, entity_type, entity_id)`, so a plain UPDATE collides when
  /// the survivor already cites the same source. In that case the duplicate's
  /// link is dropped instead of overwriting the survivor's.
  Future<void> _repointCitationLinks(
    String fromPersonId,
    String toPersonId,
  ) async {
    final links = await (_database.select(_database.citationLinks)
          ..where(
            (t) =>
                t.entityType.equals('person') &
                t.entityId.equals(fromPersonId),
          ))
        .get();

    for (final link in links) {
      final existing = await (_database.select(_database.citationLinks)
            ..where(
              (t) =>
                  t.citationId.equals(link.citationId) &
                  t.entityType.equals(link.entityType) &
                  t.entityId.equals(toPersonId),
            ))
          .getSingleOrNull();

      final deleteDuplicate = _database.delete(_database.citationLinks)
        ..where(
          (t) =>
              t.citationId.equals(link.citationId) &
              t.entityType.equals(link.entityType) &
              t.entityId.equals(fromPersonId),
        );

      if (existing != null) {
        await deleteDuplicate.go();
      } else {
        await (_database.update(_database.citationLinks)
              ..where(
                (t) =>
                    t.citationId.equals(link.citationId) &
                    t.entityType.equals(link.entityType) &
                    t.entityId.equals(fromPersonId),
              ))
            .write(CitationLinksCompanion(entityId: Value(toPersonId)));
      }
    }
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
