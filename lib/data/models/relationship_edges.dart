/// Canonical relationship edges used by the read API.
///
/// The previous model exposed a single `Relationship` type whose `id` could be
/// either a `families_v2` row or a `family_children_v2` row, and whose
/// `relationshipType` string decided what the row meant. These two types make
/// the distinction structural: a caller always knows whether it holds a
/// parent-child link or a partnership, and which identifier each carries.
library;

/// True when [gender] is recorded as female.
///
/// Used only to choose a display slot or a single-parent slot. Nothing in the
/// model requires a partnership to have one male and one female partner.
bool isFemaleGender(String gender) {
  final normalised = gender.trim().toLowerCase();
  return normalised == 'f' || normalised == 'female';
}

/// The partner slots a couple occupies, **independent of argument order**.
///
/// `husband`/`wife` are display slot names used by the tree views, not a claim
/// about the people:
///  * when the two recorded genders differ, the person recorded as female takes
///    the `wife` slot;
///  * when they match (same-sex couple, or either gender unknown) the pair is
///    ordered by id.
///
/// Canonical ordering is what makes `UNIQUE(husband_id, wife_id)` mean "this
/// couple exists once": the same two people always map to the same pair of
/// slots, whichever order the caller passed them in.
({String husbandId, String wifeId}) canonicalPartnerSlots({
  required String firstId,
  required String firstGender,
  required String secondId,
  required String secondGender,
}) {
  final firstIsFemale = isFemaleGender(firstGender);
  final secondIsFemale = isFemaleGender(secondGender);
  if (firstIsFemale != secondIsFemale) {
    return firstIsFemale
        ? (husbandId: secondId, wifeId: firstId)
        : (husbandId: firstId, wifeId: secondId);
  }
  return firstId.compareTo(secondId) <= 0
      ? (husbandId: firstId, wifeId: secondId)
      : (husbandId: secondId, wifeId: firstId);
}

/// One parent → child edge.
///
/// [linkId] identifies the `family_children_v2` row (the row you delete to
/// remove this parentage), [familyId] the family that produced it. A child with
/// two parents therefore has two edges that share a [linkId].
class ParentChildRelationship {
  const ParentChildRelationship({
    required this.linkId,
    required this.familyId,
    required this.parentId,
    required this.childId,
    required this.relationshipType,
    this.birthOrder,
  });

  final String linkId;
  final String familyId;
  final String parentId;
  final String childId;

  /// biological / adopted / foster / step / unknown
  final String relationshipType;

  final int? birthOrder;
}

/// A partnership: one `families_v2` row.
///
/// The two partner slots are named for historical reasons and either may be
/// null (a single-parent family). Slot assignment is deterministic, so the same
/// couple cannot appear twice.
class Partnership {
  const Partnership({
    required this.familyId,
    required this.treeId,
    this.husbandId,
    this.wifeId,
    this.marriageDate,
    this.isPrimary = false,
  });

  final String familyId;
  final String treeId;
  final String? husbandId;
  final String? wifeId;
  final DateTime? marriageDate;
  final bool isPrimary;

  /// The partners that are actually recorded, in slot order.
  List<String> get partnerIds =>
      [husbandId, wifeId].whereType<String>().toList();
}
