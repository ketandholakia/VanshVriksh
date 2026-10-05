import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/database_provider.dart';
import 'gedcom_importer.dart';
import 'gedcom_parser.dart';

final gedcomImportProvider =
    AsyncNotifierProvider<GedcomImportNotifier, GedcomImportResult?>(
      GedcomImportNotifier.new,
    );

class GedcomImportNotifier extends AsyncNotifier<GedcomImportResult?> {
  @override
  FutureOr<GedcomImportResult?> build() => null;

  Future<void> importGedcomFile(File file, String treeId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final nodes = await GedcomParser.parseFile(file);
      final db = ref.read(databaseProvider);
      final importer = GedcomImporter(db);
      return importer.importGedcom(nodes, treeId);
    });

    final error = state.error;
    if (error != null) throw error;
  }
}
