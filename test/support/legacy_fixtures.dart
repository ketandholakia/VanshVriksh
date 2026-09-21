import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
// Transitive dependency of drift; used only to build fixtures.
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'package:vanshvriksh/data/database/app_database.dart';

/// A person row as the pre-v10 `persons` table stored it.
typedef LegacyPerson = ({
  String id,
  String gender,
  String? firstName,
  String? lastName,
  String? birthSurname,
  String? marriedSurname,
});

/// A `relationships` row: (person, related person, type).
typedef LegacyRelationship = (String personId, String relatedPersonId, String type);

/// The two legacy tables, exactly as an old database would have them. They are
/// not part of the model any more — the upgrade reads them once, then drops them.
const legacySchemaDdl = <String>[
  '''
  CREATE TABLE persons (
    id TEXT NOT NULL, tree_id TEXT NOT NULL, full_name TEXT NOT NULL,
    first_name TEXT, middle_name TEXT, last_name TEXT, birth_surname TEXT,
    married_surname TEXT, prefix TEXT, suffix TEXT, nickname TEXT,
    gender TEXT NOT NULL, birth_date INTEGER, birth_date_display TEXT,
    birth_date_sort REAL, death_date INTEGER, death_date_display TEXT,
    death_date_sort REAL, birth_place TEXT, current_place TEXT,
    profile_photo_path TEXT, bio TEXT, notes TEXT,
    private INTEGER NOT NULL DEFAULT 0, is_living INTEGER NOT NULL DEFAULT 1,
    created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL,
    PRIMARY KEY (id)
  )
  ''',
  '''
  CREATE TABLE relationships (
    id TEXT NOT NULL, tree_id TEXT NOT NULL, person_id TEXT NOT NULL,
    related_person_id TEXT NOT NULL, relationship_type TEXT NOT NULL,
    created_at INTEGER NOT NULL, PRIMARY KEY (id)
  )
  ''',
];

/// Builds a database that looks like an older installation: the current schema is
/// created first (so the file is a real database), then the legacy tables are
/// injected and `user_version` is rewound. Opening it runs the upgrade.
///
/// Used by every migration test, so all of them exercise the same fixture.
Future<void> seedLegacyDatabase(
  String path, {
  required int version,
  List<LegacyPerson> people = const [],
  List<LegacyRelationship> relationships = const [],
}) async {
  final setup = AppDatabase.forTesting(NativeDatabase(File(path)));
  await setup.customStatement('SELECT 1'); // open → onCreate
  await setup.close();

  final raw = sqlite.sqlite3.open(path);
  try {
    for (final statement in legacySchemaDdl) {
      raw.execute(statement);
    }

    const createdAt = 1600000000; // seconds, as drift stores DateTimes
    final insertPerson = raw.prepare(
      'INSERT INTO persons (id, tree_id, full_name, first_name, last_name, '
      'birth_surname, married_surname, gender, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    );
    try {
      for (final person in people) {
        insertPerson.execute([
          person.id,
          'default-tree',
          [person.firstName, person.lastName].whereType<String>().join(' '),
          person.firstName,
          person.lastName,
          person.birthSurname,
          person.marriedSurname,
          person.gender,
          createdAt,
          createdAt,
        ]);
      }
    } finally {
      insertPerson.close();
    }

    final insertRelationship = raw.prepare(
      'INSERT INTO relationships (id, tree_id, person_id, related_person_id, '
      'relationship_type, created_at) VALUES (?, ?, ?, ?, ?, ?)',
    );
    try {
      var index = 0;
      for (final (personId, relatedPersonId, type) in relationships) {
        insertRelationship.execute([
          'rel-${index++}',
          'default-tree',
          personId,
          relatedPersonId,
          type,
          createdAt,
        ]);
      }
    } finally {
      insertRelationship.close();
    }

    raw.execute('PRAGMA user_version = $version');
  } finally {
    raw.close();
  }
}

/// Opens a seeded database so its upgrade runs.
Future<AppDatabase> openAndUpgrade(String path) async {
  final db = AppDatabase.forTesting(NativeDatabase(File(path)));
  await db.customStatement('SELECT 1');
  return db;
}

/// Reads the stored schema version without triggering the app's migration.
int storedUserVersion(String path) {
  final raw = sqlite.sqlite3.open(path);
  try {
    return raw.select('PRAGMA user_version').first.values.first! as int;
  } finally {
    raw.close();
  }
}

/// Physical table names in the file.
Set<String> storedTables(String path) {
  final raw = sqlite.sqlite3.open(path);
  try {
    return raw
        .select("SELECT name FROM sqlite_master WHERE type = 'table'")
        .map((row) => row['name'] as String)
        .toSet();
  } finally {
    raw.close();
  }
}
