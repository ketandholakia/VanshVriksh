class DashboardStats {
  const DashboardStats({
    required this.totalMembers,
    required this.totalRelationships,
    required this.membersWithPhotos,
    required this.missingPhotos,
    required this.livingMembers,
    required this.deceasedMembers,
    required this.upcomingBirthdays,
  });

  final int totalMembers;
  final int totalRelationships;
  final int membersWithPhotos;
  final int missingPhotos;
  final int livingMembers;
  final int deceasedMembers;
  final int upcomingBirthdays;
}
