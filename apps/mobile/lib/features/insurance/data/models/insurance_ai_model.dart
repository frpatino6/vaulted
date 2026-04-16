import 'package:freezed_annotation/freezed_annotation.dart';

part 'insurance_ai_model.freezed.dart';
part 'insurance_ai_model.g.dart';

@freezed
class CoverageAnalysisModel with _$CoverageAnalysisModel {
  const factory CoverageAnalysisModel({
    required String overallRisk,
    required String summary,
    @Default([]) List<String> recommendations,
    @Default([]) List<PriorityItemModel> priorityItems,
    required String renewalUrgency,
  }) = _CoverageAnalysisModel;

  factory CoverageAnalysisModel.fromJson(Map<String, dynamic> json) =>
      _$CoverageAnalysisModelFromJson(json);
}

@freezed
class PriorityItemModel with _$PriorityItemModel {
  const factory PriorityItemModel({
    required String itemId,
    required String itemName,
    required String issue,
  }) = _PriorityItemModel;

  factory PriorityItemModel.fromJson(Map<String, dynamic> json) =>
      _$PriorityItemModelFromJson(json);
}

@freezed
class ClaimDraftModel with _$ClaimDraftModel {
  const factory ClaimDraftModel({
    required String subject,
    required String body,
    @Default([]) List<String> keyPoints,
    @Default([]) List<String> nextSteps,
  }) = _ClaimDraftModel;

  factory ClaimDraftModel.fromJson(Map<String, dynamic> json) =>
      _$ClaimDraftModelFromJson(json);
}
