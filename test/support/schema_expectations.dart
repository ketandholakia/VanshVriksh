// The canonical schema, declared as data.
//
// This file is the **expected** state of the database, not a description of what
// the code currently produces. `schema_verification_test.dart` compares a fresh
// database and migrated databases against it, so any accidental schema change —
// a dropped constraint, a lost index, a renamed column — fails the suite and has
// to be an explicit decision here.
//
// Column entries are `name|notnull|primaryKeyPosition|default` as reported by
// `PRAGMA table_info`.
//
// Schema version: 13. Last reviewed: 2026-09-21.
//
// `citations`, `citation_links` and `todos` are deliberately absent. Earlier
// versions created them, but no code ever produced or read them, so they were
// removed instead of being carried as dead architecture. A feature that needs
// them can add them back through a normal schema change.

/// Table name → its columns, in physical order.
const Map<String, List<String>> expectedColumns = {
  'duplicate_markers': [
    'id|1|1|null',
    'person_a_id|1|0|null',
    'person_b_id|1|0|null',
    'reason|0|0|null',
    'created_at|1|0|null',
  ],
  'events': [
    'id|1|1|null',
    'person_id|1|0|null',
    'event_type|1|0|null',
    'date_sort|0|0|null',
    'date_display|0|0|null',
    'place|0|0|null',
    'description|0|0|null',
    'is_primary|1|0|1',
    'latitude|0|0|null',
    'longitude|0|0|null',
    'created_at|1|0|null',
    'updated_at|1|0|null',
  ],
  'families_v2': [
    'id|1|1|null',
    'tree_id|1|0|null',
    'husband_id|0|0|null',
    'wife_id|0|0|null',
    'marriage_date|0|0|null',
    'marriage_date_qualifier|0|0|null',
    'marriage_place|0|0|null',
    'marriage_place_lat|0|0|null',
    'marriage_place_lng|0|0|null',
    'wife_took_husband_name|1|0|0',
    'husband_took_wife_name|1|0|0',
    'hyphenated_surname|1|0|0',
    'no_name_change|1|0|0',
    'custom_surname_change|0|0|null',
    'wife_married_surname|0|0|null',
    'wife_name_change_type|0|0|null',
    'husband_married_surname|0|0|null',
    'husband_name_change_type|0|0|null',
    'divorce_date|0|0|null',
    'divorce_date_qualifier|0|0|null',
    'divorce_place|0|0|null',
    'wife_reverted_to_maiden|1|0|0',
    'husband_reverted_name|1|0|0',
    "relationship_type|1|0|'marriage'",
    'is_primary_marriage|1|0|0',
    'notes|0|0|null',
    'private_notes|0|0|null',
    'uuid|1|0|null',
    'is_deleted|1|0|0',
    "created_at|1|0|CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)",
    "updated_at|1|0|CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)",
  ],
  'family_children_v2': [
    'id|1|1|null',
    'family_id|1|0|null',
    'child_id|1|0|null',
    'birth_order|0|0|null',
    "relationship_type|1|0|'biological'",
    'child_surname_at_birth|0|0|null',
    'paternal_relationship|0|0|null',
    'maternal_relationship|0|0|null',
    'notes|0|0|null',
    'uuid|1|0|null',
    'is_deleted|1|0|0',
    "created_at|1|0|CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)",
    "updated_at|1|0|CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)",
  ],
  'family_trees': [
    'id|1|1|null',
    'tree_name|1|0|null',
    'description|0|0|null',
    'root_person_id|0|0|null',
    'created_at|1|0|null',
    'updated_at|1|0|null',
  ],
  'genealogy_persons': [
    'id|1|1|null',
    'first_name|1|0|null',
    'middle_name|0|0|null',
    'last_name|0|0|null',
    'birth_surname|0|0|null',
    'married_surname|0|0|null',
    'suffix|0|0|null',
    'prefix|0|0|null',
    'nickname|0|0|null',
    "display_name_format|1|0|'birth_married'",
    'custom_display_name|0|0|null',
    'gender|1|0|null',
    'birth_date|0|0|null',
    'birth_date_qualifier|0|0|null',
    'birth_place|0|0|null',
    'birth_place_lat|0|0|null',
    'birth_place_lng|0|0|null',
    'death_date|0|0|null',
    'death_date_qualifier|0|0|null',
    'death_place|0|0|null',
    'death_place_lat|0|0|null',
    'death_place_lng|0|0|null',
    'current_place|0|0|null',
    'is_living|1|0|1',
    'profile_photo_path|0|0|null',
    'biography|0|0|null',
    'notes|0|0|null',
    'occupation|0|0|null',
    'religion|0|0|null',
    'ethnicity|0|0|null',
    'is_private|1|0|0',
    'privacy_level|1|0|0',
    'tree_id|1|0|null',
    'uuid|1|0|null',
    'is_deleted|1|0|0',
    "created_at|1|0|CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)",
    "updated_at|1|0|CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)",
    'merged_into_id|0|0|null',
  ],
  'media_items': [
    'id|1|1|null',
    'person_id|1|0|null',
    'file_path|1|0|null',
    'media_type|1|0|null',
    'title|0|0|null',
    'description|0|0|null',
    'created_at|1|0|null',
  ],
  'research_notes': [
    'id|1|1|null',
    'person_id|0|0|null',
    'note_text|1|0|null',
    'research_question|0|0|null',
    'note_date_sort|0|0|null',
    'note_date_display|0|0|null',
    'resolved|1|0|0',
    'created_at|1|0|null',
  ],
  'surname_events': [
    'id|1|1|null',
    'person_id|1|0|null',
    'surname|1|0|null',
    'surname_type|1|0|null',
    'start_date|0|0|null',
    'start_date_qualifier|0|0|null',
    'end_date|0|0|null',
    'end_date_qualifier|0|0|null',
    'related_person_id|0|0|null',
    'related_event_id|0|0|null',
    'location|0|0|null',
    'legal_document|0|0|null',
    'notes|0|0|null',
    'sort_order|1|0|0',
    'is_primary|1|0|0',
    'uuid|1|0|null',
    "created_at|1|0|CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)",
    "updated_at|1|0|CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)",
  ],
};

/// Table → its foreign keys: `column|parent table|on delete`.
const Map<String, List<String>> expectedForeignKeys = {
  'duplicate_markers': [
    'person_a_id|genealogy_persons|CASCADE',
    'person_b_id|genealogy_persons|CASCADE',
  ],
  'events': [
    'person_id|genealogy_persons|RESTRICT',
  ],
  'families_v2': [
    'husband_id|genealogy_persons|RESTRICT',
    'wife_id|genealogy_persons|RESTRICT',
    'tree_id|family_trees|RESTRICT',
  ],
  'family_children_v2': [
    'family_id|families_v2|RESTRICT',
    'child_id|genealogy_persons|RESTRICT',
  ],
  'family_trees': [
    'root_person_id|genealogy_persons|SET NULL',
  ],
  'genealogy_persons': [
    'tree_id|family_trees|RESTRICT',
    'merged_into_id|genealogy_persons|SET NULL',
  ],
  'media_items': [
    'person_id|genealogy_persons|RESTRICT',
  ],
  'research_notes': [
    'person_id|genealogy_persons|RESTRICT',
  ],
  'surname_events': [
    'person_id|genealogy_persons|RESTRICT',
    'related_person_id|genealogy_persons|SET NULL',
    'related_event_id|events|SET NULL',
  ],
};

/// Every named index the canonical schema declares.
const Set<String> expectedIndexes = {
  'idx_duplicate_markers_person_b',
  'idx_events_person_id',
  'idx_families_v2_husband_id',
  'idx_families_v2_tree_id',
  'idx_families_v2_wife_id',
  'idx_family_children_v2_child_id',
  'idx_family_trees_root_person',
  'idx_genealogy_persons_merged_into',
  'idx_genealogy_persons_tree_id',
  'idx_media_items_person_id',
  'idx_research_notes_person_id',
  'idx_surname_events_person_id',
  'idx_surname_events_related_event_id',
  'idx_surname_events_related_person_id',
};

/// Table → its UNIQUE constraints, as comma-joined column lists.
const Map<String, Set<String>> expectedUniqueConstraints = {
  'duplicate_markers': {'person_a_id, person_b_id'},
  'families_v2': {'husband_id, wife_id', 'uuid'},
  'family_children_v2': {'family_id, child_id', 'uuid'},
  'genealogy_persons': {'uuid'},
  'surname_events': {'uuid'},
};

/// The schema version these expectations describe.
const int expectedSchemaVersion = 13;
