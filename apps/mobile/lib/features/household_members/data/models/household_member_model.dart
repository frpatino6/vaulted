class HouseholdMemberModel {
  const HouseholdMemberModel({
    required this.id,
    required this.name,
    this.relationship,
    required this.isMinor,
    required this.isActive,
    this.linkedUserId,
    this.notes,
  });

  final String id;
  final String name;
  final String? relationship;
  final bool isMinor;
  final bool isActive;
  final String? linkedUserId;
  final String? notes;

  factory HouseholdMemberModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawId = json['id'] ?? json['_id'];
    return HouseholdMemberModel(
      id: rawId?.toString() ?? '',
      name: (json['name'] as String?) ?? '',
      relationship: json['relationship'] as String?,
      isMinor: (json['isMinor'] as bool?) ?? false,
      isActive: (json['isActive'] as bool?) ?? true,
      linkedUserId: json['linkedUserId'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
