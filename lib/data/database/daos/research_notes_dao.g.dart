// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'research_notes_dao.dart';

// ignore_for_file: type=lint
mixin _$ResearchNotesDaoMixin on DatabaseAccessor<AppDatabase> {
  $GenealogyPersonsTable get genealogyPersons =>
      attachedDatabase.genealogyPersons;
  $ResearchNotesTable get researchNotes => attachedDatabase.researchNotes;
  ResearchNotesDaoManager get managers => ResearchNotesDaoManager(this);
}

class ResearchNotesDaoManager {
  final _$ResearchNotesDaoMixin _db;
  ResearchNotesDaoManager(this._db);
  $$GenealogyPersonsTableTableManager get genealogyPersons =>
      $$GenealogyPersonsTableTableManager(
        _db.attachedDatabase,
        _db.genealogyPersons,
      );
  $$ResearchNotesTableTableManager get researchNotes =>
      $$ResearchNotesTableTableManager(_db.attachedDatabase, _db.researchNotes);
}
