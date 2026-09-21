import 'package:drift/drift.dart';

import '../../core/utils/id_generator.dart';
import '../database/app_database.dart';
import '../database/daos/genealogy_person_dao.dart';
import '../models/relationship_edges.dart';
import '../../features/duplicates/duplicate_detection_providers.dart';

/// The schema default for `genealogy_persons.display_name_format`, used by the
/// merge contract to decide when a recorded format beats the default.
const String defaultDisplayNameFormat = 'birth_married';

/// What a merge did, so callers and tests can see the outcome.
typedef MergeResult = ({
  int partnershipsMoved,
  int partnershipsCollapsed,
  int childLinksMoved,
  int childLinksCollapsed,
  int duplicateMarkersRewritten,
  int duplicateMarkersRemoved,
});

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

  /// Removes [personId] from the tree (soft delete) in one transaction.
  ///
  /// Only the person row is flagged, so the delete is exactly reversible and no
  /// historical row is destroyed. Reads exclude anything that involves a deleted
  /// person, so the person disappears from lists, search, trees, dashboards and
  /// relationship lookups.
  ///
  /// The person is also detached from the families they were a partner of, by
  /// clearing their slot:
  ///  * a family that still has a partner stays live and keeps its child links,
  ///    so the surviving spouse's marriage and the children's place survive;
  ///  * a family left with no partner existed only for this person, so it and
  ///    its child links are soft-deleted as well.
  ///
  /// Rows that simply reference the person (child links where they are the
  /// child, events, media, notes, to-dos, surname events) are left untouched and
  /// become reachable again if the delete is reverted.
  Future<void> deletePerson(String personId) async {
    final person = await _personDao.getPersonById(personId);
    if (person == null) {
      throw ArgumentError('Person not found: $personId');
    }
    // Checked before the already-deleted early return: a merged person is
    // flagged as deleted, so the order matters.
    if (person.mergedIntoId != null) {
      throw StateError(
        'Cannot delete $personId: they were merged into '
        '${person.mergedIntoId}. Delete the survivor instead.',
      );
    }
    if (person.isDeleted) return;

    final now = DateTime.now();
    await _database.transaction(() async {
      for (final family in await _personDao.getFamiliesForPerson(personId)) {
        final isHusband = family.husbandId == personId;
        final remainingPartnerId = isHusband ? family.wifeId : family.husbandId;

        await _personDao.updateFamilyFields(
          family.id,
          isHusband
              ? FamiliesV2Companion(
                  husbandId: const Value(null),
                  updatedAt: Value(now),
                )
              : FamiliesV2Companion(
                  wifeId: const Value(null),
                  updatedAt: Value(now),
                ),
        );

        if (remainingPartnerId == null) {
          // The family existed only for this person.
          for (final link in await _personDao.getChildrenForFamily(family.id)) {
            await _personDao.markFamilyChildDeleted(link.id, now);
          }
          await _personDao.markFamilyDeleted(family.id, now);
        }
      }

      await _personDao.markPersonDeleted(personId, now);
    });
  }

  /// Reverts a soft delete of the person row.
  ///
  /// Only the person is restored. Partner slots that [deletePerson] cleared are
  /// not rebuilt, because nothing records whether a membership was removed by a
  /// delete or deliberately, and the same is true of a family that was retired
  /// with its child links. A merged person cannot be restored at all: that would
  /// need an un-merge, which has its own integrity rules.
  Future<void> restorePerson(String personId) async {
    final person = await _personDao.getPersonById(personId);
    if (person == null) {
      throw ArgumentError('Person not found: $personId');
    }
    if (person.mergedIntoId != null) {
      throw StateError(
        'Cannot restore $personId: they were merged into '
        '${person.mergedIntoId} and un-merging is not supported.',
      );
    }
    if (!person.isDeleted) return;

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

  /// Duplicate markers whose two people are both live and both in [treeId].
  ///
  /// The marker no longer stores a tree of its own: tree ownership is derived
  /// from the people it links, so it cannot drift out of sync with them.
  Future<List<DuplicateMarker>> getDuplicateMarkers(String treeId) async {
    final markers = await _database.select(_database.duplicateMarkers).get();
    if (markers.isEmpty) return const [];

    final people = await _personDao.getLivePeopleByIds([
      for (final marker in markers) ...[marker.personAId, marker.personBId],
    ]);
    final treeByPerson = {for (final person in people) person.id: person.treeId};

    return markers
        .where(
          (marker) =>
              treeByPerson[marker.personAId] == treeId &&
              treeByPerson[marker.personBId] == treeId,
        )
        .toList();
  }

  /// Marks two people as suspected duplicates.
  ///
  /// The pair is stored in a canonical order (`UNIQUE(person_a_id,
  /// person_b_id)`), so marking the same two people in either argument order is
  /// a single marker.
  Future<void> markAsDuplicate({
    required String treeId,
    required String sourceId,
    required String targetId,
    String? reason,
  }) async {
    if (sourceId == targetId) {
      throw ArgumentError('A person cannot be a duplicate of themselves.');
    }
    final first = await _personDao.getPersonById(sourceId);
    final second = await _personDao.getPersonById(targetId);
    if (first == null || second == null) {
      throw ArgumentError('Both people must exist to mark them as duplicates.');
    }
    if (first.treeId != treeId || second.treeId != treeId) {
      throw ArgumentError(
        'Both people must belong to tree $treeId to be marked as duplicates.',
      );
    }

    final (personAId, personBId) = sourceId.compareTo(targetId) <= 0
        ? (sourceId, targetId)
        : (targetId, sourceId);

    await _database.into(_database.duplicateMarkers).insert(
      DuplicateMarkersCompanion.insert(
        id: IdGenerator.newId(),
        personAId: personAId,
        personBId: personBId,
        reason: Value(reason),
        createdAt: DateTime.now(),
      ),
      mode: InsertMode.insertOrIgnore,
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

  /// Merges [duplicateId] into [survivorId] as one atomic operation.
  ///
  /// ## Contract
  ///
  /// **Survivor identity** — the caller chooses the survivor; the operation never
  /// picks one. The survivor keeps its `id`, `uuid`, `tree_id` and `created_at`.
  /// The duplicate is *retired*, not erased: its row keeps `is_deleted = true`,
  /// its original `uuid` (so an external reference to that identity can still be
  /// resolved) and gains `merged_into_id = survivorId`.
  ///
  /// **Preconditions**, all checked before anything is written: different people;
  /// both exist; neither is deleted or already merged; both belong to the same
  /// tree. A cross-tree merge is refused, because it would silently move
  /// person-scoped rows and families between two ownership roots.
  ///
  /// **Field conflicts** — the survivor's value wins unless it is absent, in
  /// which case the duplicate's is taken; a caller can override that per field
  /// with a `preferred*Source` argument. For non-null columns with a schema
  /// default, a non-default value wins over the default. `is_living` is derived
  /// from the merged death date rather than inherited, privacy is the union of
  /// both records, and the stricter privacy level wins.
  ///
  /// **Partnerships** — the duplicate's partner slots move to the survivor:
  ///  * the family that contains *both* people is retired (a family with the same
  ///    person in both slots is not a relationship) and its children are re-homed
  ///    on a single-parent family of the survivor;
  ///  * a family that would become a duplicate of one the survivor already has
  ///    (same other partner) is collapsed: its children move onto the surviving
  ///    family and the redundant family is retired;
  ///  * otherwise the duplicate's slot is reassigned to the survivor.
  /// A merged pair therefore cannot end up with a self-relationship or a
  /// duplicate couple.
  ///
  /// **Child links** — the duplicate's links move to the survivor; a link that
  /// already exists for the pair is collapsed onto the existing row
  /// (`UNIQUE(family_id, child_id)` counts soft-deleted rows too), and a link that
  /// would give one child the same parent twice is removed as redundant.
  ///
  /// **Duplicate markers** — a marker that named both people is resolved and
  /// removed; a marker naming the duplicate and a *third* person is rewritten
  /// onto the survivor rather than discarded; markers that never mentioned the
  /// duplicate are left untouched.
  ///
  /// **Other references** are repointed: surname events (as subject and as
  /// related person), events, media items, research notes, to-dos, citation links
  /// (which have a composite primary key) and a tree root that pointed at the
  /// duplicate.
  ///
  /// **Sync / version** — there is no sync engine and, since schema v12, no
  /// sync/version columns, so a merge writes none. `updated_at` is set on both
  /// rows.
  ///
  /// **Atomicity** — everything runs in one transaction. Any failure rolls the
  /// entire merge back: no partial merge, no orphaned rows and no invalid
  /// references survive.
  Future<MergeResult> mergePeople({
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
    if (survivor.isDeleted || survivor.mergedIntoId != null) {
      throw ArgumentError('The survivor is already retired: $survivorId');
    }
    if (duplicate.isDeleted || duplicate.mergedIntoId != null) {
      throw ArgumentError('The duplicate is already retired: $duplicateId');
    }
    if (survivor.treeId != duplicate.treeId) {
      throw ArgumentError(
        'Both people must belong to the same tree to be merged.'
        '($survivorId is in ${survivor.treeId}, $duplicateId is in '
        '${duplicate.treeId}).',
      );
    }

    final now = DateTime.now();
    var partnershipsMoved = 0;
    var partnershipsCollapsed = 0;
    var childLinksMoved = 0;
    var childLinksCollapsed = 0;
    var markersRewritten = 0;
    var markersRemoved = 0;

    // A merge rewrites families, child links, person-scoped rows and both person
    // rows. It has to be all-or-nothing: a half-applied merge cannot be repaired
    // by the user.
    return _database.transaction(() async {
      // 1. Partnerships.
      for (final family in await _personDao.getFamiliesForPerson(duplicateId)) {
        final duplicateIsHusband = family.husbandId == duplicateId;
        final otherPartnerId =
            duplicateIsHusband ? family.wifeId : family.husbandId;

        // Their own family: both slots hold the two people being merged.
        if (otherPartnerId == survivorId) {
          // Retire it *before* re-homing: a family with the same person in both
          // slots is not a relationship, and while it is still live the
          // re-homing check would treat it as an existing parentage.
          final children = await _personDao.getChildrenForFamily(family.id);
          await _personDao.markFamilyDeleted(family.id, now);
          if (children.isNotEmpty) {
            final rehomed = await _rehomeChildren(
              fromFamilyId: family.id,
              toFamilyId: await _singleParentFamilyFor(survivorId, now),
              now: now,
            );
            childLinksMoved += rehomed.moved;
            childLinksCollapsed += rehomed.collapsed;
          }
          partnershipsCollapsed++;
          continue;
        }

        // A partnership the survivor already records with the same person.
        if (otherPartnerId != null) {
          final existing = await _familyForPairOf(survivorId, otherPartnerId);
          if (existing != null && existing.id != family.id) {
            await _personDao.markFamilyDeleted(family.id, now);
            final rehomed = await _rehomeChildren(
              fromFamilyId: family.id,
              toFamilyId: existing.id,
              now: now,
            );
            childLinksMoved += rehomed.moved;
            childLinksCollapsed += rehomed.collapsed;
            partnershipsCollapsed++;
            continue;
          }
        }

        await _personDao.updateFamilyFields(
          family.id,
          duplicateIsHusband
              ? FamiliesV2Companion(
                  husbandId: Value(survivorId),
                  updatedAt: Value(now),
                )
              : FamiliesV2Companion(
                  wifeId: Value(survivorId),
                  updatedAt: Value(now),
                ),
        );
        partnershipsMoved++;
      }

      // 2. Child links of the duplicate.
      final duplicateChildLinks =
          await (_database.select(_database.familyChildrenV2)
                ..where(
                  (t) =>
                      t.childId.equals(duplicateId) &
                      t.isDeleted.equals(false),
                ))
              .get();
      for (final link in duplicateChildLinks) {
        // `UNIQUE(family_id, child_id)` counts soft-deleted rows too, so this
        // clash check must consider them.
        final existing =
            await _personDao.getFamilyChildLink(link.familyId, survivorId);
        if (existing != null) {
          if (existing.isDeleted) {
            // A live link is about to exist for this pair again.
            await _personDao.restoreFamilyChild(existing.id, now);
          }
          await _personDao.removeFamilyChildLinkRow(link.id);
          childLinksCollapsed++;
        } else {
          await _personDao.updateFamilyChildFields(
            link.id,
            FamilyChildrenV2Companion(
              childId: Value(survivorId),
              updatedAt: Value(now),
            ),
          );
          childLinksMoved++;
        }
      }

      // 2b. Moving a family onto the survivor (rather than a link) can leave one
      //     child linked through two of the survivor's families, which would
      //     record the same parent twice. The extra link is removed.
      childLinksCollapsed += await _collapseDuplicateParentageOf(survivorId, now);

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
      // To-dos are person-scoped as well: without this they would be orphaned on
      // a retired person.
      await (_database.update(_database.todos)
            ..where((t) => t.personId.equals(duplicateId)))
          .write(TodosCompanion(personId: Value(survivorId)));
      await _repointCitationLinks(duplicateId, survivorId);
      // A tree that was rooted at the duplicate now roots at the survivor.
      await (_database.update(_database.familyTrees)
            ..where((t) => t.rootPersonId.equals(duplicateId)))
          .write(FamilyTreesCompanion(rootPersonId: Value(survivorId)));

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
          // Non-null column with a schema default: a non-default value wins.
          displayNameFormat: Value(
            survivor.displayNameFormat == defaultDisplayNameFormat
                ? duplicate.displayNameFormat
                : survivor.displayNameFormat,
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

      // 5. Retire the duplicate and resolve the markers that named it.
      await _personDao.updatePersonFields(
        duplicateId,
        GenealogyPersonsCompanion(
          isDeleted: const Value(true),
          mergedIntoId: Value(survivorId),
          updatedAt: Value(now),
        ),
      );

      final markers = await (_database.select(_database.duplicateMarkers)
            ..where(
              (t) =>
                  t.personAId.equals(duplicateId) |
                  t.personBId.equals(duplicateId),
            ))
          .get();
      for (final marker in markers) {
        final otherId = marker.personAId == duplicateId
            ? marker.personBId
            : marker.personAId;
        if (otherId != survivorId) {
          // The suspicion about a third person moves to the survivor; the marker
          // is information, not a row to throw away.
          final (low, high) = survivorId.compareTo(otherId) <= 0
              ? (survivorId, otherId)
              : (otherId, survivorId);
          await _database.into(_database.duplicateMarkers).insert(
            DuplicateMarkersCompanion.insert(
              id: IdGenerator.newId(),
              personAId: low,
              personBId: high,
              reason: Value(marker.reason),
              createdAt: now,
            ),
            mode: InsertMode.insertOrIgnore,
          );
          markersRewritten++;
        } else {
          markersRemoved++;
        }
      }
      await (_database.delete(_database.duplicateMarkers)
            ..where(
              (t) =>
                  t.personAId.equals(duplicateId) |
                  t.personBId.equals(duplicateId),
            ))
          .go();

      return (
        partnershipsMoved: partnershipsMoved,
        partnershipsCollapsed: partnershipsCollapsed,
        childLinksMoved: childLinksMoved,
        childLinksCollapsed: childLinksCollapsed,
        duplicateMarkersRewritten: markersRewritten,
        duplicateMarkersRemoved: markersRemoved,
      );
    });
  }

  /// Removes surplus child links created by a merge: after a family has moved
  /// onto the survivor, a child can be linked through more than one of the
  /// survivor's families. Keeping both would record the same parent twice, so the
  /// child keeps one link — preferring the family that records a partner, because
  /// a child with both parents is more informative.
  Future<int> _collapseDuplicateParentageOf(
    String personId,
    DateTime now,
  ) async {
    final families = await _personDao.getFamiliesForPerson(personId);
    if (families.length < 2) return 0;

    final linksByChild = <String, List<FamilyChildrenV2Data>>{};
    for (final family in families) {
      for (final link in await _personDao.getChildrenForFamily(family.id)) {
        linksByChild.putIfAbsent(link.childId, () => []).add(link);
      }
    }

    int partnerCount(String familyId) {
      final family = families.firstWhere((f) => f.id == familyId);
      return (family.husbandId != null ? 1 : 0) + (family.wifeId != null ? 1 : 0);
    }

    var removed = 0;
    for (final entry in linksByChild.entries) {
      if (entry.value.length < 2) continue;
      entry.value.sort(
        (a, b) => partnerCount(b.familyId).compareTo(partnerCount(a.familyId)),
      );
      for (final surplus in entry.value.skip(1)) {
        await _personDao.markFamilyChildDeleted(surplus.id, now);
        removed++;
      }
    }
    return removed;
  }

  /// The live partnership family of the pair, or null when they are not
  /// partners.
  Future<FamiliesV2Data?> _familyForPairOf(
    String personAId,
    String personBId,
  ) async {
    for (final family in await _personDao.getFamiliesForPerson(personAId)) {
      if (family.husbandId == personBId || family.wifeId == personBId) {
        return family;
      }
    }
    return null;
  }

  /// A live family in which [personId] is the only recorded partner, creating one
  /// when the person has none.
  Future<String> _singleParentFamilyFor(String personId, DateTime now) async {
    final person = await _personDao.getPersonById(personId);
    if (person == null) {
      throw ArgumentError('Person not found: $personId');
    }

    for (final family in await _personDao.getFamiliesForPerson(personId)) {
      final isSoloHusband =
          family.husbandId == personId && family.wifeId == null;
      final isSoloWife = family.wifeId == personId && family.husbandId == null;
      if (isSoloHusband || isSoloWife) return family.id;
    }

    final isFemale = isFemaleGender(person.gender);
    final id = IdGenerator.newId();
    await _personDao.createFamily(
      FamiliesV2Companion.insert(
        id: id,
        treeId: person.treeId,
        husbandId: Value(isFemale ? null : personId),
        wifeId: Value(isFemale ? personId : null),
        uuid: IdGenerator.newId(),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    return id;
  }

  /// Moves the live child links of [fromFamilyId] onto [toFamilyId], collapsing
  /// any link that already exists there and any link that would give the child
  /// the same parent twice.
  Future<({int moved, int collapsed})> _rehomeChildren({
    required String fromFamilyId,
    required String toFamilyId,
    required DateTime now,
  }) async {
    var moved = 0;
    var collapsed = 0;

    for (final link in await _personDao.getChildrenForFamily(fromFamilyId)) {
      final existing =
          await _personDao.getFamilyChildLink(toFamilyId, link.childId);
      if (existing != null) {
        if (existing.isDeleted) {
          await _personDao.restoreFamilyChild(existing.id, now);
        }
        await _personDao.removeFamilyChildLinkRow(link.id);
        collapsed++;
        continue;
      }

      final targetFamily = await _personDao.getFamilyById(toFamilyId);
      final redundant = targetFamily != null &&
          await _childAlreadyLinkedViaAnotherFamily(
            childId: link.childId,
            family: targetFamily,
          );
      if (redundant) {
        await _personDao.removeFamilyChildLinkRow(link.id);
        collapsed++;
        continue;
      }

      await _personDao.updateFamilyChildFields(
        link.id,
        FamilyChildrenV2Companion(
          familyId: Value(toFamilyId),
          updatedAt: Value(now),
        ),
      );
      moved++;
    }

    return (moved: moved, collapsed: collapsed);
  }

  /// True when [childId] is already linked through a live family other than
  /// [family] that shares one of its partners — i.e. the parentage already
  /// exists and a second link would duplicate it.
  Future<bool> _childAlreadyLinkedViaAnotherFamily({
    required String childId,
    required FamiliesV2Data family,
  }) async {
    final partnerIds = [
      if (family.husbandId != null) family.husbandId!,
      if (family.wifeId != null) family.wifeId!,
    ];
    if (partnerIds.isEmpty) return false;

    final links = await (_database.select(_database.familyChildrenV2)
          ..where((t) => t.childId.equals(childId) & t.isDeleted.equals(false)))
        .get();

    for (final link in links) {
      if (link.familyId == family.id) continue;
      final otherFamily = await _personDao.getFamilyById(link.familyId);
      if (otherFamily == null || otherFamily.isDeleted) continue;
      for (final partnerId in [otherFamily.husbandId, otherFamily.wifeId]) {
        if (partnerId != null && partnerIds.contains(partnerId)) return true;
      }
    }
    return false;
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
        treeId: treeId,
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
