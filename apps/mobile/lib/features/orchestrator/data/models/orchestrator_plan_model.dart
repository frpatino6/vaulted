import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../properties/data/models/room_section_model.dart';

part 'orchestrator_plan_model.freezed.dart';
part 'orchestrator_plan_model.g.dart';

// ---------------------------------------------------------------------------
// BoundingBox helpers (reuses the existing SectionBoundingBox from properties)
// ---------------------------------------------------------------------------

SectionBoundingBox? _boundingBoxFromJson(Object? json) {
  if (json == null) return null;
  return SectionBoundingBox.fromJson(Map<String, dynamic>.from(json as Map));
}

Object? _boundingBoxToJson(SectionBoundingBox? bb) => bb?.toJson();

// ---------------------------------------------------------------------------
// OrchestratorStepModel
// ---------------------------------------------------------------------------

@freezed
class OrchestratorStepModel with _$OrchestratorStepModel {
  const factory OrchestratorStepModel({
    required String stepId,
    required String itemId,
    required String itemName,
    required String itemCategory,
    String? itemPhoto,
    String? roomId,
    String? roomName,
    String? roomPhoto,
    String? sectionId,
    String? sectionPhoto,
    String? sectionCode,
    String? sectionFurnitureName,
    @JsonKey(fromJson: _boundingBoxFromJson, toJson: _boundingBoxToJson)
    SectionBoundingBox? boundingBox,
    required String instruction,
    @Default('pending') String status,
    String? completedByUserId,
    String? completedAt,
    String? note,
    String? completionPhotoUrl,
  }) = _OrchestratorStepModel;

  factory OrchestratorStepModel.fromJson(Map<String, dynamic> json) =>
      _$OrchestratorStepModelFromJson(json);
}

// ---------------------------------------------------------------------------
// OrchestratorTaskGroupModel
// ---------------------------------------------------------------------------

@freezed
class OrchestratorTaskGroupModel with _$OrchestratorTaskGroupModel {
  const factory OrchestratorTaskGroupModel({
    required String groupId,
    required String title,
    String? assignedUserId,
    String? assignedUserName,
    @Default('pending') String status,
    @Default([]) List<OrchestratorStepModel> steps,
    String? startedAt,
    String? completedAt,
  }) = _OrchestratorTaskGroupModel;

  factory OrchestratorTaskGroupModel.fromJson(Map<String, dynamic> json) =>
      _$OrchestratorTaskGroupModelFromJson(json);
}

// ---------------------------------------------------------------------------
// OrchestratorPlanModel
// ---------------------------------------------------------------------------

@freezed
class OrchestratorPlanModel with _$OrchestratorPlanModel {
  const factory OrchestratorPlanModel({
    @JsonKey(name: '_id') required String id,
    required String tenantId,
    required String title,
    required String originalCommand,
    @Default('general') String commandType,
    String? targetDate,
    String? targetPropertyId,
    String? destinationPropertyId,
    @Default('draft') String status,
    @Default('') String aiSummary,
    @Default([]) List<OrchestratorTaskGroupModel> taskGroups,
    required String createdBy,
    String? publishedAt,
    String? completedAt,
    String? cancelledAt,
    required String createdAt,
    required String updatedAt,
  }) = _OrchestratorPlanModel;

  factory OrchestratorPlanModel.fromJson(Map<String, dynamic> json) =>
      _$OrchestratorPlanModelFromJson(json);
}

extension OrchestratorPlanModelX on OrchestratorPlanModel {
  bool get isDraft => status == 'draft';
  bool get isPublished => status == 'published';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  int get totalSteps =>
      taskGroups.fold(0, (sum, g) => sum + g.steps.length);

  int get completedSteps => taskGroups.fold(
        0,
        (sum, g) =>
            sum + g.steps.where((s) => s.status == 'done').length,
      );

  double get percentComplete =>
      totalSteps == 0 ? 0.0 : completedSteps / totalSteps;
}

// ---------------------------------------------------------------------------
// ParsedPlanModel — ephemeral, returned by /parse, not persisted
// ---------------------------------------------------------------------------

@freezed
class ParsedPlanModel with _$ParsedPlanModel {
  const factory ParsedPlanModel({
    @Default('general') String commandType,
    required String title,
    required String aiSummary,
    String? targetDate,
    String? targetPropertyId,
    String? destinationPropertyId,
    @Default([]) List<OrchestratorTaskGroupModel> taskGroups,
  }) = _ParsedPlanModel;

  factory ParsedPlanModel.fromJson(Map<String, dynamic> json) =>
      _$ParsedPlanModelFromJson(json);
}

// ---------------------------------------------------------------------------
// GroupProgressModel
// ---------------------------------------------------------------------------

@freezed
class GroupProgressModel with _$GroupProgressModel {
  const factory GroupProgressModel({
    required String groupId,
    required String title,
    @Default('') String assignedUserId,
    @Default('') String assignedUserName,
    @Default('pending') String status,
    @Default(0) int totalSteps,
    @Default(0) int completedSteps,
  }) = _GroupProgressModel;

  factory GroupProgressModel.fromJson(Map<String, dynamic> json) =>
      _$GroupProgressModelFromJson(json);
}

// ---------------------------------------------------------------------------
// PlanProgressModel
// ---------------------------------------------------------------------------

@freezed
class PlanProgressModel with _$PlanProgressModel {
  const factory PlanProgressModel({
    required String planId,
    required String status,
    @Default(0) int totalSteps,
    @Default(0) int completedSteps,
    @Default(0.0) double percentComplete,
    @Default([]) List<GroupProgressModel> byGroup,
  }) = _PlanProgressModel;

  factory PlanProgressModel.fromJson(Map<String, dynamic> json) =>
      _$PlanProgressModelFromJson(json);
}
