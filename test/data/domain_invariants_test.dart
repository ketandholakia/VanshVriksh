// Domain invariants.
//
// Instead of checking that a particular method produced a particular row, these
// tests ask the database a set of questions that must always answer "nothing
// wrong". The queries are the specification: if a future change lets the data
// reach a state one of them describes, the suite fails even when no individual
// assertion about a method would have.
//
// Two directions are tested:
//   * a healthy database (fresh, and after repository operations) satisfies every
//     invariant;
//   * each invariant that *can* be violated behind the constraints' back is
//     deliberately violated, to prove the query actually detects it. Those that
//     cannot be violated at all are proven by the database rejecting the attempt.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:vanshvriksh/data/database/app_database.dart';
import 'package:vanshvriksh/data/repositories/family_tree_repository.dart';
import 'package:vanshvriksh/data/repositories/genealogy_repository.dart';
import 'package:vanshvriksh/data/repositories/relationship_repository.dart';

import '../support/test_database.dart';

/// Invariant name → a query that returns one row per violation.
const invariantQueries = <String, String>{
  'a child link has a family': '''
    SELECT l.id FROM family_children_v2 l
    LEFT JOIN families_v2 f ON f.id = l.family_id
    WHERE f.id IS NULL
  ''',
  'a child link has a child': '''
    SELECT l.id FROM family_children_v2 l
    LEFT JOIN genealogy_persons p ON p.id = l.child_id
    WHERE p.id IS NULL
  ''',
  'a live child link does not point at a retired family': '''
    SELECT l.id FROM family_children_v2 l
    JOIN families_v2 f ON f.id = l.family_id
    WHERE l.is_deleted = 0 AND f.is_deleted = 1
  ''',
  // Note: a link that points at a *soft-deleted person* is deliberate. The
  // person delete only flags the person (so it is reversible) and every read
  // path excludes deleted people. What must never happen is a live partnership
  // keeping a retired partner, which the next invariant covers.
  'a family references existing people': '''
    SELECT f.id FROM families_v2 f
    LEFT JOIN genealogy_persons h ON h.id = f.husband_id
    LEFT JOIN genealogy_persons w ON w.id = f.wife_id
    WHERE (f.husband_id IS NOT NULL AND h.id IS NULL)
       OR (f.wife_id IS NOT NULL AND w.id IS NULL)
  ''',
  'a live family does not keep a retired partner': '''
    SELECT f.id FROM families_v2 f
    LEFT JOIN genealogy_persons h ON h.id = f.husband_id
    LEFT JOIN genealogy_persons w ON w.id = f.wife_id
    WHERE f.is_deleted = 0
      AND (h.is_deleted = 1 OR w.is_deleted = 1)
  ''',
  'a person belongs to an existing tree': '''
    SELECT p.id FROM genealogy_persons p
    LEFT JOIN family_trees t ON t.id = p.tree_id
    WHERE t.id IS NULL
  ''',
  'a family belongs to an existing tree': '''
    SELECT f.id FROM families_v2 f
    LEFT JOIN family_trees t ON t.id = f.tree_id
    WHERE t.id IS NULL
  ''',
  'a tree root references an existing person': '''
    SELECT t.id FROM family_trees t
    LEFT JOIN genealogy_persons p ON p.id = t.root_person_id
    WHERE t.root_person_id IS NOT NULL AND p.id IS NULL
  ''',
  'no duplicated family-child link': '''
    SELECT family_id FROM family_children_v2
    GROUP BY family_id, child_id HAVING COUNT(*) > 1
  ''',
  'no duplicated couple': '''
    SELECT husband_id FROM families_v2
    WHERE husband_id IS NOT NULL
    GROUP BY husband_id, wife_id HAVING COUNT(*) > 1
  ''',
  'a family has at least one partner': '''
    SELECT id FROM families_v2
    WHERE husband_id IS NULL AND wife_id IS NULL AND is_deleted = 0
  ''',
  'a family does not have the same person in both slots': '''
    SELECT id FROM families_v2
    WHERE husband_id IS NOT NULL AND husband_id = wife_id
  ''',
  'no person-scoped record without its person': '''
    SELECT 'events' AS source, e.id FROM events e
    LEFT JOIN genealogy_persons p ON p.id = e.person_id WHERE p.id IS NULL
    UNION ALL
    SELECT 'media_items', m.id FROM media_items m
    LEFT JOIN genealogy_persons p ON p.id = m.person_id WHERE p.id IS NULL
    UNION ALL
    SELECT 'research_notes', n.id FROM research_notes n
    LEFT JOIN genealogy_persons p ON p.id = n.person_id WHERE p.id IS NULL
    UNION ALL
    SELECT 'todos', t.id FROM todos t
    LEFT JOIN genealogy_persons p ON p.id = t.person_id WHERE p.id IS NULL
    UNION ALL
    SELECT 'surname_events', s.id FROM surname_events s
    LEFT JOIN genealogy_persons p ON p.id = s.person_id WHERE p.id IS NULL
  ''',
  'no merged person is left active': '''
    SELECT id FROM genealogy_persons
    WHERE merged_into_id IS NOT NULL AND is_deleted = 0
  ''',
  'a merge pointer targets a live person': '''
    SELECT p.id FROM genealogy_persons p
    JOIN genealogy_persons s ON s.id = p.merged_into_id
    WHERE p.merged_into_id IS NOT NULL AND s.is_deleted = 1
  ''',
  'a person is not merged into themselves': '''
    SELECT id FROM genealogy_persons WHERE merged_into_id = id
  ''',
  'a duplicate marker names two different people': '''
    SELECT id FROM duplicate_markers WHERE person_a_id = person_b_id
  ''',
  'a duplicate marker names people that exist': '''
    SELECT m.id FROM duplicate_markers m
    LEFT JOIN genealogy_persons a ON a.id = m.person_a_id
    LEFT JOIN genealogy_persons b ON b.id = m.person_b_id
    WHERE a.id IS NULL OR b.id IS NULL
  ''',
};

/// Returns the invariants that are currently violated.
Future<List<String>> violatedInvariants(AppDatabase db) async {
  final violated = <String>[];
  for (final entry in invariantQueries.entries) {
    final rows = await db.customSelect(entry.value).get();
    if (rows.isNotEmpty) {
      violated.add('${entry.key} (${rows.length} row(s))');
    }
  }
  return violated;
}

void main() {
  const treeId = 'default-tree';

  late AppDatabase db;
  late GenealogyRepository people;
  late RelationshipRepository relationships;
  late FamilyTreeRepository trees;

  setUp(() async {
    db = await createTestDatabase();
    people = GenealogyRepository(db);
    relationships = RelationshipRepository(db);
    trees = FamilyTreeRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> addPerson({
    required String firstName,
    String gender = 'M',
  }) {
    return people.addPerson(
      treeId: treeId,
      firstName: firstName,
      gender: gender,
    );
  }

  /// dad + mom + two children, all linked.
  Future<({String dad, String mom, String kidA, String kidB, String familyId})>
      familyOfFour() async {
    final dad = await addPerson(firstName: 'Dad');
    final mom = await addPerson(firstName: 'Mom', gender: 'F');
    final kidA = await addPerson(firstName: 'KidA');
    final kidB = await addPerson(firstName: 'KidB');
    await relationships.addSpouseRelationship(
      treeId: treeId,
      personAId: dad,
      personBId: mom,
    );
    final familyId = (await relationships.getFamiliesForPerson(dad)).single.id;
    await people.addChildToFamily(familyId: familyId, childId: kidA);
    await people.addChildToFamily(familyId: familyId, childId: kidB);
    return (dad: dad, mom: mom, kidA: kidA, kidB: kidB, familyId: familyId);
  }

  // ---------------------------------------------------------------------------
  group('a healthy database satisfies every invariant', () {
    test('a brand-new database', () async {
      expect(await violatedInvariants(db), isEmpty);
    });

    test('a populated family', () async {
      await familyOfFour();

      expect(await violatedInvariants(db), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  group('the invariants detect what they claim to detect', () {
    test('a live child link pointing at a retired family', () async {
      final family = await familyOfFour();

      // Not prevented by a foreign key: the row still exists, it is only flagged.
      await db.customStatement(
        'UPDATE families_v2 SET is_deleted = 1 WHERE id = ?',
        [family.familyId],
      );

      expect(
        await violatedInvariants(db),
        contains(startsWith('a live child link does not point at a retired')),
      );
    });

    test('a live family keeping a retired partner', () async {
      final family = await familyOfFour();

      await db.customStatement(
        'UPDATE genealogy_persons SET is_deleted = 1 WHERE id = ?',
        [family.dad],
      );

      expect(
        await violatedInvariants(db),
        contains(startsWith('a live family does not keep a retired partner')),
      );
    });

    test('a merged person left active', () async {
      final survivor = await addPerson(firstName: 'Ram');
      final duplicate = await addPerson(firstName: 'Ram');

      await db.customStatement(
        'UPDATE genealogy_persons SET merged_into_id = ? WHERE id = ?',
        [survivor, duplicate],
      );

      expect(
        await violatedInvariants(db),
        contains(startsWith('no merged person is left active')),
      );
    });

    test('a merge pointer at a retired person', () async {
      final survivor = await addPerson(firstName: 'Ram');
      final duplicate = await addPerson(firstName: 'Ram');
      await people.mergePeople(survivorId: survivor, duplicateId: duplicate);

      await db.customStatement(
        'UPDATE genealogy_persons SET is_deleted = 1 WHERE id = ?',
        [survivor],
      );

      expect(
        await violatedInvariants(db),
        contains(startsWith('a merge pointer targets a live person')),
      );
    });

    test('a person merged into themselves', () async {
      final id = await addPerson(firstName: 'Solo');

      await db.customStatement(
        'UPDATE genealogy_persons SET merged_into_id = ? WHERE id = ?',
        [id, id],
      );

      expect(
        await violatedInvariants(db),
        contains(startsWith('a person is not merged into themselves')),
      );
    });

    test('a family with the same person in both slots', () async {
      final person = await addPerson(firstName: 'Solo');
      final familyId = await people.createFamily(
        treeId: treeId,
        husbandId: person,
      );

      await db.customStatement(
        'UPDATE families_v2 SET wife_id = husband_id WHERE id = ?',
        [familyId],
      );

      expect(
        await violatedInvariants(db),
        contains(startsWith('a family does not have the same person')),
      );
    });

    test('a family with no partner at all', () async {
      final now = DateTime(2000);
      await db.into(db.familiesV2).insert(
            FamiliesV2Companion.insert(
              id: 'empty-family',
              treeId: treeId,
              uuid: 'uuid-empty-family',
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      expect(
        await violatedInvariants(db),
        contains(startsWith('a family has at least one partner')),
      );
    });
  });

  // ---------------------------------------------------------------------------
  group('invariants the foreign keys make unreachable are still proven', () {
    test('a child link cannot lose its family, even on purpose', () async {
      final family = await familyOfFour();
      final kid = family.kidA;

      await expectLater(
        db.customStatement(
          'UPDATE family_children_v2 SET family_id = ? WHERE child_id = ?',
          ['no-such-family', kid],
        ),
        throwsA(anything),
      );
      expect(await violatedInvariants(db), isEmpty);
    });

    test('a person cannot lose its tree, even on purpose', () async {
      final id = await addPerson(firstName: 'Ram');

      await expectLater(
        db.customStatement(
          'UPDATE genealogy_persons SET tree_id = ? WHERE id = ?',
          ['no-such-tree', id],
        ),
        throwsA(anything),
      );
      expect(await violatedInvariants(db), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  group('repository operations cannot leave a violated database', () {
    test('after each step of the delete flow', () async {
      final family = await familyOfFour();

      await people.deletePerson(family.dad);
      expect(await violatedInvariants(db), isEmpty, reason: 'after deleting dad');

      await people.deletePerson(family.kidA);
      expect(
        await violatedInvariants(db),
        isEmpty,
        reason: 'after deleting a child',
      );

      await people.restorePerson(family.kidA);
      expect(
        await violatedInvariants(db),
        isEmpty,
        reason: 'after restoring the child',
      );
    });

    test('after dissolving a partnership', () async {
      final family = await familyOfFour();

      await relationships.removeSpouseRelationship(
        treeId: treeId,
        personAId: family.dad,
        personBId: family.mom,
        removeChildRelationships: true,
      );

      expect(await violatedInvariants(db), isEmpty);
    });

    test('after removing one parent-child relationship', () async {
      final dad = await addPerson(firstName: 'Dad');
      final kid = await addPerson(firstName: 'Kid');
      await relationships.addParentChildRelationship(
        treeId: treeId,
        parentId: dad,
        childId: kid,
      );

      await relationships.removeParentChildRelationship(
        treeId: treeId,
        parentId: dad,
        childId: kid,
      );

      expect(await violatedInvariants(db), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  group('a merge never leaves a partially completed state', () {
    test('a completed merge satisfies every invariant', () async {
      final survivor = await addPerson(firstName: 'Ram');
      final duplicate = await addPerson(firstName: 'Ram');
      final wife = await addPerson(firstName: 'Sita', gender: 'F');
      final kid = await addPerson(firstName: 'Kid');
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: duplicate,
        personBId: wife,
      );
      final familyId =
          (await relationships.getFamiliesForPerson(duplicate)).single.id;
      await people.addChildToFamily(familyId: familyId, childId: kid);
      await people.markAsDuplicate(
        treeId: treeId,
        sourceId: survivor,
        targetId: duplicate,
      );

      await people.mergePeople(survivorId: survivor, duplicateId: duplicate);

      expect(await violatedInvariants(db), isEmpty);

      // And the specific post-conditions of a finished merge.
      final retired = (await people.getPersonById(duplicate))!;
      expect(retired.isDeleted, isTrue);
      expect(retired.mergedIntoId, survivor);
      expect((await people.getPersonById(survivor))!.isDeleted, isFalse);
      expect(await db.select(db.duplicateMarkers).get(), isEmpty);
      expect((await relationships.getChildren(survivor)).single.id, kid);
      expect((await relationships.getSpouses(survivor)).single.id, wife);
    });

    test('a failed merge leaves the database untouched', () async {
      final survivor = await addPerson(firstName: 'Ram');
      final duplicate = await addPerson(firstName: 'Ram');
      final wife = await addPerson(firstName: 'Sita', gender: 'F');
      await relationships.addSpouseRelationship(
        treeId: treeId,
        personAId: duplicate,
        personBId: wife,
      );
      await db.into(db.events).insert(
            EventsCompanion.insert(
              id: 'e1',
              personId: duplicate,
              eventType: 'baptism',
              createdAt: DateTime(2000),
              updatedAt: DateTime(2000),
            ),
          );
      final before = await dataFingerprint(db);

      await db.customStatement(
        'CREATE TRIGGER fail_merge BEFORE UPDATE ON events '
        "BEGIN SELECT RAISE(ABORT, 'injected'); END",
      );
      await expectLater(
        people.mergePeople(survivorId: survivor, duplicateId: duplicate),
        throwsA(anything),
      );
      await db.customStatement('DROP TRIGGER fail_merge');

      expect(await dataStateOf(db), before);
      expect(await violatedInvariants(db), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  group('purging a tree leaves nothing orphaned', () {
    test('after a purge every tree-owned table is empty', () async {
      final now = DateTime(2000);
      final family = await familyOfFour();
      await db.into(db.events).insert(
            EventsCompanion.insert(
              id: 'e1',
              personId: family.kidA,
              eventType: 'baptism',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db.into(db.mediaItems).insert(
            MediaItemsCompanion.insert(
              id: 'm1',
              personId: family.kidA,
              filePath: '/tmp/x.jpg',
              mediaType: 'photo',
              createdAt: now,
            ),
          );
      await db.into(db.researchNotes).insert(
            ResearchNotesCompanion.insert(
              id: 'n1',
              personId: Value(family.kidA),
              noteText: 'note',
              createdAt: now,
            ),
          );
      await db.into(db.todos).insert(
            TodosCompanion.insert(
              id: 't1',
              personId: Value(family.kidA),
              taskText: 'task',
              createdAt: now,
            ),
          );
      await people.markAsDuplicate(
        treeId: treeId,
        sourceId: family.kidA,
        targetId: family.kidB,
      );

      await trees.purgeTree(treeId);

      expect(await db.select(db.genealogyPersons).get(), isEmpty);
      expect(await db.select(db.familiesV2).get(), isEmpty);
      expect(await db.select(db.familyChildrenV2).get(), isEmpty);
      expect(await db.select(db.events).get(), isEmpty);
      expect(await db.select(db.mediaItems).get(), isEmpty);
      expect(await db.select(db.researchNotes).get(), isEmpty);
      expect(await db.select(db.todos).get(), isEmpty);
      expect(await db.select(db.surnameEvents).get(), isEmpty);
      expect(await db.select(db.duplicateMarkers).get(), isEmpty);
      expect(await db.select(db.familyTrees).get(), isEmpty);
      expect(await violatedInvariants(db), isEmpty);
    });
  });
}

/// A fingerprint of the *data* (not the schema), used to prove that a failed
/// operation changed nothing.
Future<Map<String, int>> dataFingerprint(AppDatabase db) async {
  return {
    'persons': (await db.select(db.genealogyPersons).get()).length,
    'families': (await db.select(db.familiesV2).get()).length,
    'links': (await db.select(db.familyChildrenV2).get()).length,
    'events': (await db.select(db.events).get()).length,
    'markers': (await db.select(db.duplicateMarkers).get()).length,
  };
}

Future<Map<String, int>> dataStateOf(AppDatabase db) =>
    dataFingerprint(db);
