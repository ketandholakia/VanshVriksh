/// The **legacy** relationship vocabulary.
///
/// These are the values the pre-v10 `relationships` table could hold. That table
/// is no longer part of the model: it is read once, by the upgrade path, and then
/// dropped. The constants are kept because the migration needs one authoritative
/// list of what it accepts.
///
/// Investigation of this repository's history (the initial commit and every
/// change since) found exactly two values written by application code:
///
/// * `parent_child` — see [parentChild];
/// * `spouse` — see [spouse].
///
/// [marriage] is accepted **defensively**: it is the documented default of
/// `families_v2.relationship_type`, so a partially migrated or hand-edited
/// database can carry it on a legacy partner row. No other value
/// (`husband`, `wife`, `partner`, `couple`, `married`, …) appears anywhere in
/// the codebase or its history, so none is accepted.
class RelationshipTypes {
  /// Legacy edge: `person_id` is the parent, `related_person_id` the child.
  static const String parentChild = 'parent_child';

  /// Legacy edge: the two people are partners.
  static const String spouse = 'spouse';

  /// Defensive synonym for [spouse] (see the class documentation).
  static const String marriage = 'marriage';

  /// Every value that is treated as a **partner** relationship when reading
  /// legacy rows.
  static const Set<String> partnerTypes = {spouse, marriage};

  /// Every value that is treated as a **parent-child** relationship when reading
  /// legacy rows.
  static const Set<String> parentChildTypes = {parentChild};
}
