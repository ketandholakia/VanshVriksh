import '../../data/database/app_database.dart';

enum PersonRelationGroupType { parents, spouses, children, siblings }

class PersonRelationItem {
  const PersonRelationItem({
    required this.person,
    required this.groupType,
    required this.relationshipId,
  });

  final GenealogyPerson person;
  final PersonRelationGroupType groupType;

  /// For siblings this can be empty because sibling is calculated from parents.
  final String relationshipId;

  bool get canRemove => relationshipId.isNotEmpty;
}
