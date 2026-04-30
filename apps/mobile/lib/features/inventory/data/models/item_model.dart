import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../wardrobe/data/models/wardrobe_attributes.dart';
import '../../../properties/data/models/room_section_model.dart';

part 'item_model.freezed.dart';
part 'item_model.g.dart';

SectionBoundingBox? _itemBoundingBoxFromJson(Object? json) {
  if (json == null) return null;
  return SectionBoundingBox.fromJson(Map<String, dynamic>.from(json as Map));
}

Object? _itemBoundingBoxToJson(SectionBoundingBox? bb) => bb?.toJson();

@freezed
class ItemValuationModel with _$ItemValuationModel {
  const factory ItemValuationModel({
    @Default(0) int purchasePrice,
    @Default(0) int currentValue,
    @Default('USD') String currency,
    DateTime? purchaseDate,
  }) = _ItemValuationModel;

  factory ItemValuationModel.fromJson(Map<String, dynamic> json) =>
      _$ItemValuationModelFromJson(json);
}

@freezed
class ItemModel with _$ItemModel {
  const factory ItemModel({
    required String id,
    required String name,
    String? propertyId,
    String? propertyName,
    String? roomId,
    String? roomName,
    required String category,
    @Default('') String subcategory,
    @Default('active') String status,
    @Default([]) List<String> photos,
    @Default([]) List<String> tags,
    String? serialNumber,
    String? locationDetail,
    String? sectionId,
    String? sectionPhoto,
    @JsonKey(fromJson: _itemBoundingBoxFromJson, toJson: _itemBoundingBoxToJson)
    SectionBoundingBox? sectionBoundingBox,
    @Default(1) int quantity,
    ItemValuationModel? valuation,
    // ignore: invalid_annotation_target
    @JsonKey(includeIfNull: false) Map<String, dynamic>? attributes,
    @Default([]) List<String> documents,
    String? createdAt,
    String? qrCode,
  }) = _ItemModel;

  factory ItemModel.fromJson(Map<String, dynamic> json) =>
      _$ItemModelFromJson(json);
}

extension ItemModelWardrobe on ItemModel {
  WardrobeAttributes get wardrobeAttributes =>
      WardrobeAttributes.fromMap(attributes);

  bool get isWardrobe => category == 'wardrobe';

  bool get hasWardrobeDetails {
    final attrs = wardrobeAttributes;
    return attrs.type != null ||
        attrs.brand != null ||
        attrs.size != null ||
        attrs.color != null ||
        attrs.material != null ||
        attrs.season != null ||
        attrs.cleaningStatus != null;
  }
}
