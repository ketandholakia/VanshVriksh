import 'package:flutter_test/flutter_test.dart';

import 'package:vanshvriksh/data/database/app_database.dart';

import 'schema_expectations.dart';

/// Asserts that [db] is exactly the canonical schema: the expected tables, their
/// columns (name, nullability, primary-key position, default), their foreign keys
/// with delete actions, the declared indexes, and the UNIQUE constraints.
///
/// Used for both a brand-new database and migrated ones, so a migrated database
/// cannot drift away from a fresh one — and neither can drift away from what this
/// project intends the schema to be.
Future<void> expectCanonicalSchema(
  AppDatabase db, {
  String because = '',
}) async {
  final suffix = because.isEmpty ? '' : ' ($because)';

  final tableRows = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name",
      )
      .get();
  final tables = tableRows.map((row) => row.data['name'] as String).toList();
  expect(
    tables,
    expectedColumns.keys.toList(),
    reason: 'table set$suffix',
  );

  for (final entry in expectedColumns.entries) {
    final rows = await db.customSelect('PRAGMA table_info(${entry.key})').get();
    final actual = [
      for (final row in rows)
        '${row.data['name']}|${row.data['notnull']}|${row.data['pk']}|'
            '${row.data['dflt_value']}',
    ];
    expect(actual, entry.value, reason: 'columns of ${entry.key}$suffix');
  }

  for (final entry in expectedForeignKeys.entries) {
    final rows = await db
        .customSelect('PRAGMA foreign_key_list(${entry.key})')
        .get();
    final actual = [
      for (final row in rows)
        '${row.data['from']}|${row.data['table']}|${row.data['on_delete']}',
    ]..sort();
    final expected = [...entry.value]..sort();
    expect(actual, expected, reason: 'foreign keys of ${entry.key}$suffix');
  }

  final indexRows = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'index' "
        "AND name NOT LIKE 'sqlite_autoindex%'",
      )
      .get();
  final indexes = indexRows.map((row) => row.data['name'] as String).toSet();
  expect(indexes, expectedIndexes, reason: 'named indexes$suffix');

  final uniqueByTable = <String, Set<String>>{};
  for (final table in expectedColumns.keys) {
    final list = await db.customSelect("PRAGMA index_list('$table')").get();
    final constraints = <String>{};
    for (final entry in list) {
      if (entry.data['unique'] != 1) continue;
      if (entry.data['origin'] != 'u') continue;
      final info = await db
          .customSelect("PRAGMA index_info('${entry.data['name']}')")
          .get();
      constraints.add(info.map((column) => column.data['name']).join(', '));
    }
    if (constraints.isNotEmpty) uniqueByTable[table] = constraints;
  }
  expect(
    uniqueByTable,
    expectedUniqueConstraints,
    reason: 'unique constraints$suffix',
  );

  final version = await db.customSelect('PRAGMA user_version').getSingle();
  expect(
    version.data['user_version'],
    expectedSchemaVersion,
    reason: 'schema version$suffix',
  );
}

/// A comparable fingerprint of everything `PRAGMA` can tell us about a schema.
/// Two databases with equal fingerprints are structurally the same database.
Future<Map<String, Object?>> schemaFingerprint(AppDatabase db) async {
  final fingerprint = <String, Object?>{};

  final tables = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name",
      )
      .get();
  fingerprint['tables'] = tables.map((row) => row.data['name']).toList();

  for (final table in tables) {
    final name = table.data['name'] as String;
    final columns = await db.customSelect('PRAGMA table_info($name)').get();
    final foreignKeys =
        await db.customSelect('PRAGMA foreign_key_list($name)').get();
    final indexes = await db.customSelect("PRAGMA index_list('$name')").get();

    fingerprint[name] = {
      'columns': [
        for (final column in columns)
          '${column.data['name']}|${column.data['type']}|'
              '${column.data['notnull']}|${column.data['dflt_value']}|'
              '${column.data['pk']}',
      ]..sort(),
      'foreignKeys': [
        for (final fk in foreignKeys)
          '${fk.data['from']}->${fk.data['table']}.${fk.data['to']}|'
              '${fk.data['on_delete']}|${fk.data['on_update']}',
      ]..sort(),
      'indexes': [
        for (final index in indexes)
          '${index.data['name']}|${index.data['unique']}|'
              '${index.data['origin']}',
      ]..sort(),
      'sql': (table.data['sql'] as String? ?? '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim(),
    };
  }

  final namedIndexes = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'index' "
        "AND name NOT LIKE 'sqlite_autoindex%' ORDER BY name",
      )
      .get();
  fingerprint['namedIndexes'] =
      namedIndexes.map((row) => row.data['name']).toList();

  return fingerprint;
}
