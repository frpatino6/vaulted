import 'package:freezed_annotation/freezed_annotation.dart';

part 'item_model.freezed.dart';
part 'item_model.g.dart';

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
    required String category,
    @Default('') String subcategory,
    @Default('active') String status,
    @Default([]) List<String> photos,
    @Default([]) List<String> tags,
    String? serialNumber,
    ItemValuationModel? valuation,
    @Default([]) List<String> documents,
    String? createdAt,
  }) = _ItemModel;

  factory ItemModel.fromJson(Map<String, dynamic> json) =>
      _$ItemModelFromJson(json);
}
