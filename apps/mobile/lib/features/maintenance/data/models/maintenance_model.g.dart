// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MaintenanceModelImpl _$$MaintenanceModelImplFromJson(
  Map<String, dynamic> json,
) => _$MaintenanceModelImpl(
  id: json['id'] as String,
  itemId: json['itemId'] as String,
  tenantId: json['tenantId'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  status: json['status'] as String? ?? 'pending',
  scheduledDate: json['scheduledDate'] as String,
  completedDate: json['completedDate'] as String?,
  isRecurring: json['isRecurring'] as bool? ?? false,
  recurrenceIntervalDays:
      (json['recurrenceIntervalDays'] as num?)?.toInt(),
  nextScheduledDate: json['nextScheduledDate'] as String?,
  providerName: json['providerName'] as String?,
  providerContact: json['providerContact'] as String?,
  cost: (json['cost'] as num?)?.toDouble(),
  currency: json['currency'] as String? ?? 'USD',
  notes: json['notes'] as String?,
  documents:
      (json['documents'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  isAiSuggested: json['isAiSuggested'] as bool? ?? false,
  aiRiskScore: (json['aiRiskScore'] as num?)?.toDouble(),
  aiReason: json['aiReason'] as String?,
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$$MaintenanceModelImplToJson(
  _$MaintenanceModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'itemId': instance.itemId,
  'tenantId': instance.tenantId,
  'title': instance.title,
  'description': instance.description,
  'status': instance.status,
  'scheduledDate': instance.scheduledDate,
  'completedDate': instance.completedDate,
  'isRecurring': instance.isRecurring,
  'recurrenceIntervalDays': instance.recurrenceIntervalDays,
  'nextScheduledDate': instance.nextScheduledDate,
  'providerName': instance.providerName,
  'providerContact': instance.providerContact,
  'cost': instance.cost,
  'currency': instance.currency,
  'notes': instance.notes,
  'documents': instance.documents,
  'isAiSuggested': instance.isAiSuggested,
  'aiRiskScore': instance.aiRiskScore,
  'aiReason': instance.aiReason,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};
