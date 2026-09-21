import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'tables/family_trees_table.dart';
import 'tables/families_v2_table.dart';
import 'tables/citation_links_table.dart';
import 'tables/citations_table.dart';
import 'tables/family_children_v2_table.dart';
import 'tables/duplicate_markers_table.dart';
import 'tables/events_table.dart';
import 'tables/genealogy_persons_table.dart';
import 'tables/media_items_table.dart';
import 'tables/persons_table.dart';
import 'tables/relationships_table.dart';
import 'tables/research_notes_table.dart';
import 'tables/sync_change_log_table.dart';
import 'tables/surname_events_table.dart';
import 'tables/todos_table.dart';
import 'daos/events_dao.dart';
import 'daos/genealogy_person_dao.dart';
import 'daos/person_dao.dart';
import 'daos/research_notes_dao.dart';

import 'app_database_open_connection.dart'
    if (dart.library.html) 'app_database_open_connection_web.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    FamilyTrees,
    GenealogyPersons,
    SurnameEvents,
    FamiliesV2,
    FamilyChildrenV2,
    Persons,
    Relationships,
    MediaItems,
    Events,
    DuplicateMarkers,
    Citations,
    CitationLinks,
    ResearchNotes,
    Todos,
    SyncChangeLog,
  ],
  daos: [
    GenealogyPersonDao,
    PersonDao,
    EventsDao,
    ResearchNotesDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 3) {
            await m.createTable(events);
            await m.createTable(citations);
            await m.createTable(citationLinks);
            await m.createTable(researchNotes);
            await m.createTable(todos);
            await m.createTable(syncChangeLog);
          }
          if (from < 4) {
            await customStatement(
              'ALTER TABLE research_notes ADD COLUMN note_date_sort REAL',
            );
            await customStatement(
              'ALTER TABLE research_notes ADD COLUMN note_date_display TEXT',
            );
          }
          if (from < 5) {
            await m.createTable(duplicateMarkers);
          }
          if (from < 6) {
            await customStatement(
              'ALTER TABLE persons ADD COLUMN birth_surname TEXT',
            );
            await customStatement(
              'ALTER TABLE persons ADD COLUMN married_surname TEXT',
            );
          }
          if (from < 7) {
            await m.createTable(genealogyPersons);
            await m.createTable(surnameEvents);
            await m.createTable(familiesV2);
            await m.createTable(familyChildrenV2);
          }
          if (from < 8) {
            await _migrateLegacyPersonsToGenealogy();
          }
          if (from < 9) {
            // Add indexes on all FK and frequently-queried columns.
            await customStatement('CREATE INDEX IF NOT EXISTS idx_persons_tree_id ON persons(tree_id)');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_relationships_person_id ON relationships(person_id)');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_relationships_related_person_id ON relationships(related_person_id)');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_relationships_tree_id ON relationships(tree_id)');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_relationships_type ON relationships(relationship_type)');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_events_person_id ON events(person_id)');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_media_items_person_id ON media_items(person_id)');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_research_notes_person_id ON research_notes(person_id)');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_todos_person_id ON todos(person_id)');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_genealogy_persons_tree_id ON genealogy_persons(tree_id)');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_surname_events_person_id ON surname_events(person_id)');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_families_v2_husband_id ON families_v2(husband_id)');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_families_v2_wife_id ON families_v2(wife_id)');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_family_children_v2_family_id ON family_children_v2(family_id)');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_family_children_v2_child_id ON family_children_v2(child_id)');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_citation_links_entity ON citation_links(entity_type, entity_id)');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_duplicate_markers_tree_id ON duplicate_markers(tree_id)');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_sync_change_log_status ON sync_change_log(sync_status)');
          }
          if (from < 10) {
            await _migrateLegacyRelationshipsToFamilies();
            await m.alterTable(TableMigration(events));
            await m.alterTable(TableMigration(mediaItems));
            await m.alterTable(TableMigration(researchNotes));
            await m.alterTable(TableMigration(todos));
            await customStatement('DROP TABLE IF EXISTS persons');
            await customStatement('DROP TABLE IF EXISTS relationships');
          }
          if (from < 11) {
            // Add profile photo storage to the V2 person table.
            await m.alterTable(TableMigration(genealogyPersons));
          }
        },
        beforeOpen: (details) async {
          // Enable foreign keys on EVERY connection, not just first create.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _migrateLegacyRelationshipsToFamilies() async {
    final familyCount = await customSelect('SELECT COUNT(*) AS count FROM families_v2').getSingle();
    final familyTotal = familyCount.data['count'] as int? ?? 0;
    if (familyTotal > 0) return; // already migrated

    final legacyRels = await select(relationships).get();
    final uuid = const Uuid();

    // 1. Migrate Marriages First
    final marriages = legacyRels.where((r) => r.relationshipType == 'marriage').toList();
    for (final rel in marriages) {
      final existingFamily = await (select(familiesV2)
            ..where((f) =>
                (f.husbandId.equals(rel.personId) & f.wifeId.equals(rel.relatedPersonId)) |
                (f.wifeId.equals(rel.personId) & f.husbandId.equals(rel.relatedPersonId))))
          .getSingleOrNull();

      if (existingFamily == null) {
        final person1 = await (select(genealogyPersons)..where((p) => p.id.equals(rel.personId))).getSingleOrNull();
        String? husbandId;
        String? wifeId;
        if (person1?.gender == 'female') {
          wifeId = rel.personId;
          husbandId = rel.relatedPersonId;
        } else {
          husbandId = rel.personId;
          wifeId = rel.relatedPersonId;
        }
        await into(familiesV2).insert(
          FamiliesV2Companion.insert(
            id: uuid.v4(),
            husbandId: Value(husbandId),
            wifeId: Value(wifeId),
            uuid: uuid.v4(),
          ),
        );
      }
    }

    // 2. Migrate Parent-Child relationships
    final parentChildRels = legacyRels.where((r) => r.relationshipType == 'parent_child').toList();
    // Group by child (relatedPersonId)
    final Map<String, List<String>> childToParents = {};
    for (final rel in parentChildRels) {
      childToParents.putIfAbsent(rel.relatedPersonId, () => []).add(rel.personId);
    }

    for (final entry in childToParents.entries) {
      final childId = entry.key;
      final parents = entry.value;

      String familyId;
      if (parents.length >= 2) {
        final p1 = parents[0];
        final p2 = parents[1];
        // Find family with both parents
        final family = await (select(familiesV2)
              ..where((f) =>
                  (f.husbandId.equals(p1) & f.wifeId.equals(p2)) |
                  (f.wifeId.equals(p1) & f.husbandId.equals(p2))))
            .getSingleOrNull();
        
        if (family != null) {
          familyId = family.id;
        } else {
          // Create family
          final person1 = await (select(genealogyPersons)..where((p) => p.id.equals(p1))).getSingleOrNull();
          String? hId, wId;
          if (person1?.gender == 'female') { wId = p1; hId = p2; } else { hId = p1; wId = p2; }
          familyId = uuid.v4();
          await into(familiesV2).insert(
            FamiliesV2Companion.insert(id: familyId, husbandId: Value(hId), wifeId: Value(wId), uuid: uuid.v4()),
          );
        }
      } else {
        // Single parent
        final p1 = parents.first;
        final family = await (select(familiesV2)
              ..where((f) => f.husbandId.equals(p1) | f.wifeId.equals(p1)))
            .getSingleOrNull();
        
        if (family != null) {
          familyId = family.id;
        } else {
          final person1 = await (select(genealogyPersons)..where((p) => p.id.equals(p1))).getSingleOrNull();
          familyId = uuid.v4();
          if (person1?.gender == 'female') {
            await into(familiesV2).insert(FamiliesV2Companion.insert(id: familyId, wifeId: Value(p1), uuid: uuid.v4()));
          } else {
            await into(familiesV2).insert(FamiliesV2Companion.insert(id: familyId, husbandId: Value(p1), uuid: uuid.v4()));
          }
        }
      }

      // Insert child into family
      await into(familyChildrenV2).insert(
        FamilyChildrenV2Companion.insert(
          id: uuid.v4(),
          familyId: familyId,
          childId: childId,
          uuid: uuid.v4(),
        ),
      );
    }
  }

  Future<void> _migrateLegacyPersonsToGenealogy() async {
    final legacyCount = await customSelect(
      'SELECT COUNT(*) AS count FROM persons',
    ).getSingle();
    final genealogyCount = await customSelect(
      'SELECT COUNT(*) AS count FROM genealogy_persons',
    ).getSingle();

    final legacyTotal = legacyCount.data['count'] as int? ?? 0;
    final genealogyTotal = genealogyCount.data['count'] as int? ?? 0;
    if (legacyTotal == 0 || genealogyTotal > 0) return;

    final legacyPeople = await select(persons).get();
    for (final person in legacyPeople) {
      final createdAt = person.createdAt;
      final updatedAt = person.updatedAt;
      final birthSurname = person.birthSurname ?? person.lastName;
      final marriedSurname =
          person.gender == 'female' ? person.marriedSurname : null;
      final displayNameFormat =
          person.gender == 'female' && marriedSurname != null
              ? 'birth_married'
              : 'birth_married';

      await into(genealogyPersons).insert(
        GenealogyPersonsCompanion.insert(
          id: person.id,
          firstName: person.firstName ?? '',
          treeId: person.treeId,
          gender: person.gender,
          uuid: person.id,
          createdAt: Value(createdAt),
          updatedAt: Value(updatedAt),
          middleName: Value(person.middleName),
          lastName: Value(person.lastName),
          birthSurname: Value(birthSurname),
          marriedSurname: Value(marriedSurname),
          prefix: Value(person.prefix),
          suffix: Value(person.suffix),
          nickname: Value(person.nickname),
          birthDate: Value(person.birthDate),
          birthDateQualifier: const Value(null),
          birthPlace: Value(person.birthPlace),
          birthPlaceLat: const Value(null),
          birthPlaceLng: const Value(null),
          deathDate: Value(person.deathDate),
          deathDateQualifier: const Value(null),
          deathPlace: const Value(null),
          deathPlaceLat: const Value(null),
          deathPlaceLng: const Value(null),
          currentPlace: Value(person.currentPlace),
          isLiving: Value(person.isLiving),
          biography: Value(person.bio),
          notes: Value(person.notes),
          occupation: const Value(null),
          religion: const Value(null),
          ethnicity: const Value(null),
          isPrivate: Value(person.private),
          privacyLevel: const Value(0),
          displayNameFormat: Value(displayNameFormat),
          customDisplayName: Value(person.fullName),
          syncStatus: const Value('pending'),
          isDeleted: const Value(false),
          version: const Value(1),
          mergedIntoId: const Value(null),
        ),
      );

      final now = DateTime.now();
      if (birthSurname != null && birthSurname.trim().isNotEmpty) {
        await into(surnameEvents).insert(
          SurnameEventsCompanion.insert(
            id: '${person.id}-birth-surname',
            personId: person.id,
            surname: birthSurname.trim(),
            surnameType: 'birth',
            uuid: '${person.id}-birth-surname',
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      }
      if (marriedSurname != null &&
          marriedSurname.trim().isNotEmpty &&
          marriedSurname.trim() != birthSurname?.trim()) {
        await into(surnameEvents).insert(
          SurnameEventsCompanion.insert(
            id: '${person.id}-married-surname',
            personId: person.id,
            surname: marriedSurname.trim(),
            surnameType: 'marriage',
            uuid: '${person.id}-married-surname',
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      }
    }
  }
}
