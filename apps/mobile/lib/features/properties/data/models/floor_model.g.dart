// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'floor_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FloorModelImpl _$$FloorModelImplFromJson(Map<String, dynamic> json) =>
    _$FloorModelImpl(
      floorId: json['floorId'] as String,
      name: json['name'] as String,
      rooms:
          (json['rooms'] as List<dynamic>?)
              ?.map((e) => RoomModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$FloorModelImplToJson(_$FloorModelImpl instance) =>
    <String, dynamic>{
      'floorId': instance.floorId,
      'name': instance.name,
      'rooms': instance.rooms,
    };
