import 'package:freezed_annotation/freezed_annotation.dart';

part 'dry_cleaning_model.freezed.dart';
part 'dry_cleaning_model.g.dart';

@freezed
class DryCleaningModel with _$DryCleaningModel {
  const factory DryCleaningModel({
    required String id,
    required String itemId,
    required DateTime sentDate,
    DateTime? returnedDate,
    String? cleanerName,
    double? cost,
    @Default('USD') String currency,
    String? notes,
    String? createdAt,
  }) = _DryCleaningModel;

  factory DryCleaningModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> normalized = Map<String, dynamic>.from(json);
    if (normalized['id'] == null && normalized['_id'] != null) {
      normalized['id'] = normalized['_id'].toString();
    }
    return _$DryCleaningModelFromJson(normalized);
  }
}
