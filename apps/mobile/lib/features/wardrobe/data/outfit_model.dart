import 'package:freezed_annotation/freezed_annotation.dart';

part 'outfit_model.freezed.dart';
part 'outfit_model.g.dart';

@freezed
class OutfitItemPreviewModel with _$OutfitItemPreviewModel {
  const factory OutfitItemPreviewModel({
    required String id,
    required String name,
    String? photo,
    String? category,
    String? type,
    String? cleaningStatus,
  }) = _OutfitItemPreviewModel;

  factory OutfitItemPreviewModel.fromJson(Map<String, dynamic> json) =>
      _$OutfitItemPreviewModelFromJson({
        ...json,
        if (json['id'] == null && json['_id'] != null)
          'id': json['_id'].toString(),
      });
}

@freezed
class OutfitModel with _$OutfitModel {
  const factory OutfitModel({
    required String id,
    required String name,
    String? description,
    @Default(<String>[]) List<String> itemIds,
    String? season,
    String? occasion,
    @Default(<String>[]) List<String> photos,
    @Default(<OutfitItemPreviewModel>[]) List<OutfitItemPreviewModel> items,
    String? createdAt,
  }) = _OutfitModel;

  factory OutfitModel.fromJson(Map<String, dynamic> json) =>
      _$OutfitModelFromJson({
        ...json,
        if (json['id'] == null && json['_id'] != null)
          'id': json['_id'].toString(),
      });
}
