import 'package:freezed_annotation/freezed_annotation.dart';

import 'room_section_model.dart';

part 'room_model.freezed.dart';
part 'room_model.g.dart';

@freezed
class RoomModel with _$RoomModel {
  const factory RoomModel({
    required String roomId,
    required String name,
    required String type,
    @Default([]) List<RoomSectionModel> sections,
  }) = _RoomModel;

  factory RoomModel.fromJson(Map<String, dynamic> json) =>
      _$RoomModelFromJson(json);
}
