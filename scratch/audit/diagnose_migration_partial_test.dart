import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'package:vanshvriksh/data/database/app_database.dart';

void main() {
  test('diagnose migration partial-application', () async {
    final tempDir = Directory.systemTemp.createTempSync('vv_diag_');
    final dbPath = '${tempDir.path}${Platform.pathSeparator}vv.sqlite';

    // ---- build fixture ----
    final setup = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    final now = DateTime.now();
    await setup.into(setup.familyTrees).insert(
          FamilyTreesCompanion.insert(
            id: 'tree-1',
            treeName: 'My Family',
            createdAt: now,
            updatedAt: now,
          ),
        );
    for (final id in ['p1', 'p2', 'childA', 'childB', 'childC']) {
      final gender = id == 'p2' ? 'female' : 'male';
      await setup.into(setup.persons).insert(
            PersonsCompanion.insert(
              id: id,
              treeId: 'tree-1',
              fullName: id,
              gender: gender,
              createdAt: now,
              updatedAt: now,
            ),
          );
      await setup.into(setup.genealogyPersons).insert(
            GenealogyPersonsCompanion.insert(
              id: id,
              firstName: id,
              treeId: 'tree-1',
              gender: gender,
              uuid: 'uuid-$id',
            ),
          );
    }
    var i = 0;
    for (final rel in [
      ('p1', 'childA', 'parent_child'),
      ('p1', 'childB', 'parent_child'),
      ('p2', 'childB', 'parent_child'),
      ('p1', 'childC', 'parent_child'),
    ]) {
      await setup.into(setup.relationships).insert(
            RelationshipsCompanion.insert(
              id: 'rel-${i++}',
              treeId: 'tree-1',
              personId: rel.$1,
              relatedPersonId: rel.$2,
              relationshipType: rel.$3,
              createdAt: now,
            ),
          );
    }
    await setup.customStatement('PRAGMA user_version = 9');
    await setup.close();

    void snapshot(String label) {
      final raw = sqlite.sqlite3.open(dbPath);
      try {
        final version = raw.select('PRAGMA user_version').first.values.first;
        final tables = raw
            .select("SELECT name FROM sqlite_master WHERE type='table'")
            .map((r) => r['name'])
            .toSet();
        int count(String t) =>
            tables.contains(t) ? raw.select('SELECT COUNT(*) c FROM $t').first['c'] as int : -1;
        // ignore: avoid_print
        print(
          '[$label] user_version=$version families_v2=${count('families_v2')} '
          'links=${count('family_children_v2')} relationships=${count('relationships')} '
          'persons_table=${count('persons')} genealogy_persons=${count('genealogy_persons')}',
        );
      } finally {
        raw.close();
      }
    }

    snapshot('before any open');
    // ignore: avoid_print
    print('---');

    for (var attempt = 1; attempt <= 3; attempt++) {
      final db = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
      Object? failure;
      try {
        await db.select(db.genealogyPersons).get();
      } catch (e) {
        failure = e;
      }
      try {
        await db.close();
      } catch (_) {
        // ignore
      }
      // ignore: avoid_print
      print('[$attempt] failure=${failure?.runtimeType}: ${failure?.toString().split('\n').first}');
      snapshot('after attempt $attempt');
    }

    tempDir.deleteSync(recursive: true);
  });
}
