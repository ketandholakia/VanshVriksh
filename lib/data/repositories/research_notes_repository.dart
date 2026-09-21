import 'package:drift/drift.dart';

import '../../core/utils/id_generator.dart';
import '../database/app_database.dart';
import '../database/daos/research_notes_dao.dart';

class ResearchNotesRepository {
  ResearchNotesRepository(this._database);

  final AppDatabase _database;

  ResearchNotesDao get _researchNotesDao => _database.researchNotesDao;

  Future<String> addResearchNote({
    String? personId,
    required String noteText,
    String? researchQuestion,
    DateTime? noteDate,
    String? noteDateDisplay,
  }) async {
    final id = IdGenerator.newId();

    await _researchNotesDao.createResearchNote(
      ResearchNotesCompanion.insert(
        id: id,
        personId: Value(personId),
        noteText: noteText.trim(),
        researchQuestion: Value(researchQuestion?.trim()),
        noteDateSort: Value(noteDate?.millisecondsSinceEpoch.toDouble()),
        noteDateDisplay: Value(noteDateDisplay?.trim()),
        createdAt: DateTime.now(),
      ),
    );

    return id;
  }

  Stream<List<ResearchNote>> watchNotesForPerson(String personId) {
    return _researchNotesDao.watchNotesForPerson(personId);
  }

  Future<bool> updateResearchNote({
    required String id,
    String? personId,
    required String noteText,
    String? researchQuestion,
    DateTime? noteDate,
    String? noteDateDisplay,
    required bool resolved,
    required DateTime createdAt,
  }) {
    return _researchNotesDao.updateResearchNote(
      ResearchNotesCompanion(
        id: Value(id),
        personId: Value(personId),
        noteText: Value(noteText.trim()),
        researchQuestion: Value(researchQuestion?.trim()),
        noteDateSort: Value(noteDate?.millisecondsSinceEpoch.toDouble()),
        noteDateDisplay: Value(noteDateDisplay?.trim()),
        resolved: Value(resolved),
        createdAt: Value(createdAt),
      ),
    );
  }

  Future<ResearchNote?> getResearchNoteById(String noteId) {
    return _researchNotesDao.getResearchNoteById(noteId);
  }

  Future<int> deleteResearchNote(String noteId) {
    return _researchNotesDao.deleteResearchNote(noteId);
  }
}
