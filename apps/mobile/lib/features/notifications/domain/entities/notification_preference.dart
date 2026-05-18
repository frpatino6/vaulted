class NotificationPreference {
  const NotificationPreference({
    required this.pushEnabled,
    required this.emailEnabled,
    required this.dryCleaningOverdue,
    required this.maintenanceDue,
    required this.itemAdded,
  });

  final bool pushEnabled;
  final bool emailEnabled;
  final bool dryCleaningOverdue;
  final bool maintenanceDue;
  final bool itemAdded;

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      emailEnabled: json['emailEnabled'] as bool? ?? true,
      dryCleaningOverdue: json['dryCleaningOverdue'] as bool? ?? true,
      maintenanceDue: json['maintenanceDue'] as bool? ?? true,
      itemAdded: json['itemAdded'] as bool? ?? true,
    );
  }

  NotificationPreference copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? dryCleaningOverdue,
    bool? maintenanceDue,
    bool? itemAdded,
  }) {
    return NotificationPreference(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      dryCleaningOverdue: dryCleaningOverdue ?? this.dryCleaningOverdue,
      maintenanceDue: maintenanceDue ?? this.maintenanceDue,
      itemAdded: itemAdded ?? this.itemAdded,
    );
  }
}
