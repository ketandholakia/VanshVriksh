import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/research_notes_table.dart';

part 'research_notes_dao.g.dart';

@DriftAccessor(tables: [ResearchNotes])
class ResearchNotesDao extends DatabaseAccessor<AppDatabase>
    with _$ResearchNotesDaoMixin {
  ResearchNotesDao(super.db);

  Future<void> createResearchNote(ResearchNotesCompanion note) {
    return into(researchNotes).insert(note);
  }

  Future<bool> updateResearchNote(ResearchNotesCompanion note) {
    return update(researchNotes).replace(note);
  }

  Future<int> deleteResearchNote(String noteId) {
    return (delete(researchNotes)..where((tbl) => tbl.id.equals(noteId))).go();
  }

  Stream<List<ResearchNote>> watchNotesForPerson(String personId) {
    return (select(researchNotes)
          ..where((tbl) => tbl.personId.equals(personId))
          ..orderBy([
            (tbl) => OrderingTerm.desc(tbl.noteDateSort),
            (tbl) => OrderingTerm.desc(tbl.createdAt),
          ]))
        .watch();
  }

  Future<ResearchNote?> getResearchNoteById(String noteId) {
    return (select(
      researchNotes,
    )..where((tbl) => tbl.id.equals(noteId))).getSingleOrNull();
  }
}
