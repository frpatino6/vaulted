// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'at_laundry_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AtLaundryItemImpl _$$AtLaundryItemImplFromJson(Map<String, dynamic> json) =>
    _$AtLaundryItemImpl(
      recordId: json['recordId'] as String,
      itemId: json['itemId'] as String,
      itemName: json['itemName'] as String,
      photoUrl: json['photoUrl'] as String?,
      cleanerName: json['cleanerName'] as String?,
      sentDate: DateTime.parse(json['sentDate'] as String),
      daysAtCleaner: (json['daysAtCleaner'] as num).toInt(),
      isOverdue: json['isOverdue'] as bool,
      cost: (json['cost'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'USD',
    );

Map<String, dynamic> _$$AtLaundryItemImplToJson(_$AtLaundryItemImpl instance) =>
    <String, dynamic>{
      'recordId': instance.recordId,
      'itemId': instance.itemId,
      'itemName': instance.itemName,
      'photoUrl': instance.photoUrl,
      'cleanerName': instance.cleanerName,
      'sentDate': instance.sentDate.toIso8601String(),
      'daysAtCleaner': instance.daysAtCleaner,
      'isOverdue': instance.isOverdue,
      'cost': instance.cost,
      'currency': instance.currency,
    };

_$AtLaundryPropertyImpl _$$AtLaundryPropertyImplFromJson(
  Map<String, dynamic> json,
) => _$AtLaundryPropertyImpl(
  propertyId: json['propertyId'] as String,
  propertyName: json['propertyName'] as String,
  items:
      (json['items'] as List<dynamic>)
          .map((e) => AtLaundryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$$AtLaundryPropertyImplToJson(
  _$AtLaundryPropertyImpl instance,
) => <String, dynamic>{
  'propertyId': instance.propertyId,
  'propertyName': instance.propertyName,
  'items': instance.items,
};

_$AtLaundryDataImpl _$$AtLaundryDataImplFromJson(Map<String, dynamic> json) =>
    _$AtLaundryDataImpl(
      totalItems: (json['totalItems'] as num).toInt(),
      overdueItems: (json['overdueItems'] as num).toInt(),
      overdueThresholdDays:
          (json['overdueThresholdDays'] as num?)?.toInt() ?? 7,
      byProperty:
          (json['byProperty'] as List<dynamic>)
              .map((e) => AtLaundryProperty.fromJson(e as Map<String, dynamic>))
              .toList(),
    );

Map<String, dynamic> _$$AtLaundryDataImplToJson(_$AtLaundryDataImpl instance) =>
    <String, dynamic>{
      'totalItems': instance.totalItems,
      'overdueItems': instance.overdueItems,
      'overdueThresholdDays': instance.overdueThresholdDays,
      'byProperty': instance.byProperty,
    };
