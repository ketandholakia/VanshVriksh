import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/person_save_service.dart';
import 'database_provider.dart';

final personSaveServiceProvider = Provider<PersonSaveService>((ref) {
  final database = ref.watch(databaseProvider);
  return PersonSaveService(database);
});
