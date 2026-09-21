/// Canonical relationship edges used by the read API.
///
/// The previous model exposed a single `Relationship` type whose `id` could be
/// either a `families_v2` row or a `family_children_v2` row, and whose
/// `relationshipType` string decided what the row meant. These two types make
/// the distinction structural: a caller always knows whether it holds a
/// parent-child link or a partnership, and which identifier each carries.
library;

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
