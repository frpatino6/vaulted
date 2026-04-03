// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dry_cleaning_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DryCleaningModelImpl _$$DryCleaningModelImplFromJson(
  Map<String, dynamic> json,
) => _$DryCleaningModelImpl(
  id: json['id'] as String,
  itemId: json['itemId'] as String,
  sentDate: DateTime.parse(json['sentDate'] as String),
  returnedDate: json['returnedDate'] == null
      ? null
      : DateTime.parse(json['returnedDate'] as String),
  cleanerName: json['cleanerName'] as String?,
  cost: (json['cost'] as num?)?.toDouble(),
  currency: json['currency'] as String? ?? 'USD',
  notes: json['notes'] as String?,
  createdAt: json['createdAt'] as String?,
);

Map<String, dynamic> _$$DryCleaningModelImplToJson(
  _$DryCleaningModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'itemId': instance.itemId,
  'sentDate': instance.sentDate.toIso8601String(),
  'returnedDate': instance.returnedDate?.toIso8601String(),
  'cleanerName': instance.cleanerName,
  'cost': instance.cost,
  'currency': instance.currency,
  'notes': instance.notes,
  'createdAt': instance.createdAt,
};
