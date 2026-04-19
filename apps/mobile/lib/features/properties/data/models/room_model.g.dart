// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RoomModelImpl _$$RoomModelImplFromJson(Map<String, dynamic> json) =>
    _$RoomModelImpl(
      roomId: json['roomId'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      sections:
          (json['sections'] as List<dynamic>?)
              ?.map((e) => RoomSectionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$RoomModelImplToJson(_$RoomModelImpl instance) =>
    <String, dynamic>{
      'roomId': instance.roomId,
      'name': instance.name,
      'type': instance.type,
      'sections': instance.sections,
    };
