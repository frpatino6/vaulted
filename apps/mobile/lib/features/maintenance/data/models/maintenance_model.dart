import 'package:freezed_annotation/freezed_annotation.dart';

part 'maintenance_model.freezed.dart';
part 'maintenance_model.g.dart';

@freezed
class MaintenanceModel with _$MaintenanceModel {
  const factory MaintenanceModel({
    required String id,
    required String itemId,
    required String tenantId,
    required String title,
    String? description,
    @Default('pending') String status,
    required String scheduledDate,
    String? completedDate,
    @Default(false) bool isRecurring,
    int? recurrenceIntervalDays,
    String? nextScheduledDate,
    String? providerName,
    String? providerContact,
    double? cost,
    @Default('USD') String currency,
    String? notes,
    @Default([]) List<String> documents,
    @Default(false) bool isAiSuggested,
    double? aiRiskScore,
    String? aiReason,
    String? createdAt,
    String? updatedAt,
  }) = _MaintenanceModel;

  factory MaintenanceModel.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceModelFromJson(json);
}

extension MaintenanceModelX on MaintenanceModel {
  bool get isPending => status == 'pending';
  bool get isOverdue => status == 'overdue';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  bool get isUrgent {
    if (!isPending && !isOverdue) return false;
    final date = DateTime.tryParse(scheduledDate);
    if (date == null) return false;
    final diff = date.difference(DateTime.now()).inDays;
    return diff <= 1;
  }

  bool get isDueSoon {
    if (!isPending) return false;
    final date = DateTime.tryParse(scheduledDate);
    if (date == null) return false;
    final diff = date.difference(DateTime.now()).inDays;
    return diff > 1 && diff <= 7;
  }
}
