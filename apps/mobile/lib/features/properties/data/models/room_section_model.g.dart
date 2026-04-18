// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_section_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RoomSectionModelImpl _$$RoomSectionModelImplFromJson(
  Map<String, dynamic> json,
) => _$RoomSectionModelImpl(
  sectionId: json['sectionId'] as String,
  code: json['code'] as String,
  name: json['name'] as String,
  type: json['type'] as String,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$$RoomSectionModelImplToJson(
  _$RoomSectionModelImpl instance,
) => <String, dynamic>{
  'sectionId': instance.sectionId,
  'code': instance.code,
  'name': instance.name,
  'type': instance.type,
  'notes': instance.notes,
};
