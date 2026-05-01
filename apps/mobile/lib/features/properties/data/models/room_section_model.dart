import 'package:freezed_annotation/freezed_annotation.dart';

part 'room_section_model.freezed.dart';
part 'room_section_model.g.dart';

class SectionBoundingBox {
  const SectionBoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
  final double x, y, width, height;

  factory SectionBoundingBox.fromJson(Map<String, dynamic> json) =>
      SectionBoundingBox(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };
}

SectionBoundingBox? _boundingBoxFromJson(Object? json) {
  if (json == null) return null;
  return SectionBoundingBox.fromJson(Map<String, dynamic>.from(json as Map));
}

Object? _boundingBoxToJson(SectionBoundingBox? bb) => bb?.toJson();

@freezed
class RoomSectionModel with _$RoomSectionModel {
  const factory RoomSectionModel({
    required String sectionId,
    required String code,
    required String name,
    required String type,
    String? notes,
    String? photo,
    @JsonKey(fromJson: _boundingBoxFromJson, toJson: _boundingBoxToJson)
    SectionBoundingBox? boundingBox,
  }) = _RoomSectionModel;

  factory RoomSectionModel.fromJson(Map<String, dynamic> json) =>
      _$RoomSectionModelFromJson(json);
}
