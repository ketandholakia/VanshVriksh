import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';

/// The application's database handle.
///
/// Disposed when the provider is disposed (app teardown, a test container, or a
/// provider scope being replaced), so the underlying SQLite connection and its
/// file handle are released instead of leaking for the process lifetime.
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
