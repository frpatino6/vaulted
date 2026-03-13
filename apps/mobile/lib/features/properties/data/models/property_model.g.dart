// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PropertyModelImpl _$$PropertyModelImplFromJson(Map<String, dynamic> json) =>
    _$PropertyModelImpl(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      address: AddressModel.fromJson(json['address'] as Map<String, dynamic>),
      floors: (json['floors'] as List<dynamic>?)
              ?.map((e) => FloorModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$PropertyModelImplToJson(_$PropertyModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenantId': instance.tenantId,
      'name': instance.name,
      'type': instance.type,
      'address': instance.address,
      'floors': instance.floors,
      'photos': instance.photos,
    };
