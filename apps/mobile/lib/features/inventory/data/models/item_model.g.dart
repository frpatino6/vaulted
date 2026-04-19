// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ItemValuationModelImpl _$$ItemValuationModelImplFromJson(
  Map<String, dynamic> json,
) => _$ItemValuationModelImpl(
  purchasePrice: (json['purchasePrice'] as num?)?.toInt() ?? 0,
  currentValue: (json['currentValue'] as num?)?.toInt() ?? 0,
  currency: json['currency'] as String? ?? 'USD',
  purchaseDate:
      json['purchaseDate'] == null
          ? null
          : DateTime.parse(json['purchaseDate'] as String),
);

Map<String, dynamic> _$$ItemValuationModelImplToJson(
  _$ItemValuationModelImpl instance,
) => <String, dynamic>{
  'purchasePrice': instance.purchasePrice,
  'currentValue': instance.currentValue,
  'currency': instance.currency,
  'purchaseDate': instance.purchaseDate?.toIso8601String(),
};

_$ItemModelImpl _$$ItemModelImplFromJson(
  Map<String, dynamic> json,
) => _$ItemModelImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  propertyId: json['propertyId'] as String?,
  propertyName: json['propertyName'] as String?,
  roomId: json['roomId'] as String?,
  roomName: json['roomName'] as String?,
  category: json['category'] as String,
  subcategory: json['subcategory'] as String? ?? '',
  status: json['status'] as String? ?? 'active',
  photos:
      (json['photos'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  serialNumber: json['serialNumber'] as String?,
  locationDetail: json['locationDetail'] as String?,
  sectionId: json['sectionId'] as String?,
  valuation:
      json['valuation'] == null
          ? null
          : ItemValuationModel.fromJson(
            json['valuation'] as Map<String, dynamic>,
          ),
  attributes: json['attributes'] as Map<String, dynamic>?,
  documents:
      (json['documents'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  createdAt: json['createdAt'] as String?,
  qrCode: json['qrCode'] as String?,
);

Map<String, dynamic> _$$ItemModelImplToJson(_$ItemModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'propertyId': instance.propertyId,
      'propertyName': instance.propertyName,
      'roomId': instance.roomId,
      'roomName': instance.roomName,
      'category': instance.category,
      'subcategory': instance.subcategory,
      'status': instance.status,
      'photos': instance.photos,
      'tags': instance.tags,
      'serialNumber': instance.serialNumber,
      'locationDetail': instance.locationDetail,
      'sectionId': instance.sectionId,
      'valuation': instance.valuation,
      if (instance.attributes case final value?) 'attributes': value,
      'documents': instance.documents,
      'createdAt': instance.createdAt,
      'qrCode': instance.qrCode,
    };
