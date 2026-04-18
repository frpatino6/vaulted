import 'package:freezed_annotation/freezed_annotation.dart';

part 'room_section_model.freezed.dart';
part 'room_section_model.g.dart';

@freezed
class RoomSectionModel with _$RoomSectionModel {
  const factory RoomSectionModel({
    required String sectionId,
    required String code,
    required String name,
    required String type,
    String? notes,
  }) = _RoomSectionModel;

  factory RoomSectionModel.fromJson(Map<String, dynamic> json) =>
      _$RoomSectionModelFromJson(json);
}
