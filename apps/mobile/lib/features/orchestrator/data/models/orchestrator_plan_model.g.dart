// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orchestrator_plan_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrchestratorStepModelImpl _$$OrchestratorStepModelImplFromJson(
  Map<String, dynamic> json,
) => _$OrchestratorStepModelImpl(
  stepId: json['stepId'] as String,
  itemId: json['itemId'] as String,
  itemName: json['itemName'] as String,
  itemCategory: json['itemCategory'] as String,
  itemPhoto: json['itemPhoto'] as String?,
  roomId: json['roomId'] as String?,
  roomName: json['roomName'] as String?,
  roomPhoto: json['roomPhoto'] as String?,
  sectionId: json['sectionId'] as String?,
  sectionPhoto: json['sectionPhoto'] as String?,
  sectionCode: json['sectionCode'] as String?,
  sectionFurnitureName: json['sectionFurnitureName'] as String?,
  boundingBox: _boundingBoxFromJson(json['boundingBox']),
  instruction: json['instruction'] as String,
  status: json['status'] as String? ?? 'pending',
  completedByUserId: json['completedByUserId'] as String?,
  completedAt: json['completedAt'] as String?,
  note: json['note'] as String?,
  completionPhotoUrl: json['completionPhotoUrl'] as String?,
);

Map<String, dynamic> _$$OrchestratorStepModelImplToJson(
  _$OrchestratorStepModelImpl instance,
) => <String, dynamic>{
  'stepId': instance.stepId,
  'itemId': instance.itemId,
  'itemName': instance.itemName,
  'itemCategory': instance.itemCategory,
  'itemPhoto': instance.itemPhoto,
  'roomId': instance.roomId,
  'roomName': instance.roomName,
  'roomPhoto': instance.roomPhoto,
  'sectionId': instance.sectionId,
  'sectionPhoto': instance.sectionPhoto,
  'sectionCode': instance.sectionCode,
  'sectionFurnitureName': instance.sectionFurnitureName,
  'boundingBox': _boundingBoxToJson(instance.boundingBox),
  'instruction': instance.instruction,
  'status': instance.status,
  'completedByUserId': instance.completedByUserId,
  'completedAt': instance.completedAt,
  'note': instance.note,
  'completionPhotoUrl': instance.completionPhotoUrl,
};

_$OrchestratorTaskGroupModelImpl _$$OrchestratorTaskGroupModelImplFromJson(
  Map<String, dynamic> json,
) => _$OrchestratorTaskGroupModelImpl(
  groupId: json['groupId'] as String,
  title: json['title'] as String,
  assignedUserId: json['assignedUserId'] as String?,
  assignedUserName: json['assignedUserName'] as String?,
  status: json['status'] as String? ?? 'pending',
  steps:
      (json['steps'] as List<dynamic>?)
          ?.map(
            (e) => OrchestratorStepModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  startedAt: json['startedAt'] as String?,
  completedAt: json['completedAt'] as String?,
);

Map<String, dynamic> _$$OrchestratorTaskGroupModelImplToJson(
  _$OrchestratorTaskGroupModelImpl instance,
) => <String, dynamic>{
  'groupId': instance.groupId,
  'title': instance.title,
  'assignedUserId': instance.assignedUserId,
  'assignedUserName': instance.assignedUserName,
  'status': instance.status,
  'steps': instance.steps,
  'startedAt': instance.startedAt,
  'completedAt': instance.completedAt,
};

_$OrchestratorPlanModelImpl _$$OrchestratorPlanModelImplFromJson(
  Map<String, dynamic> json,
) => _$OrchestratorPlanModelImpl(
  id: json['_id'] as String,
  tenantId: json['tenantId'] as String,
  title: json['title'] as String,
  originalCommand: json['originalCommand'] as String,
  commandType: json['commandType'] as String? ?? 'general',
  targetDate: json['targetDate'] as String?,
  targetPropertyId: json['targetPropertyId'] as String?,
  destinationPropertyId: json['destinationPropertyId'] as String?,
  status: json['status'] as String? ?? 'draft',
  aiSummary: json['aiSummary'] as String? ?? '',
  taskGroups:
      (json['taskGroups'] as List<dynamic>?)
          ?.map(
            (e) =>
                OrchestratorTaskGroupModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  createdBy: json['createdBy'] as String,
  publishedAt: json['publishedAt'] as String?,
  completedAt: json['completedAt'] as String?,
  cancelledAt: json['cancelledAt'] as String?,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
);

Map<String, dynamic> _$$OrchestratorPlanModelImplToJson(
  _$OrchestratorPlanModelImpl instance,
) => <String, dynamic>{
  '_id': instance.id,
  'tenantId': instance.tenantId,
  'title': instance.title,
  'originalCommand': instance.originalCommand,
  'commandType': instance.commandType,
  'targetDate': instance.targetDate,
  'targetPropertyId': instance.targetPropertyId,
  'destinationPropertyId': instance.destinationPropertyId,
  'status': instance.status,
  'aiSummary': instance.aiSummary,
  'taskGroups': instance.taskGroups,
  'createdBy': instance.createdBy,
  'publishedAt': instance.publishedAt,
  'completedAt': instance.completedAt,
  'cancelledAt': instance.cancelledAt,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};

_$ParsedPlanModelImpl _$$ParsedPlanModelImplFromJson(
  Map<String, dynamic> json,
) => _$ParsedPlanModelImpl(
  commandType: json['commandType'] as String? ?? 'general',
  title: json['title'] as String,
  aiSummary: json['aiSummary'] as String,
  targetDate: json['targetDate'] as String?,
  targetPropertyId: json['targetPropertyId'] as String?,
  destinationPropertyId: json['destinationPropertyId'] as String?,
  taskGroups:
      (json['taskGroups'] as List<dynamic>?)
          ?.map(
            (e) =>
                OrchestratorTaskGroupModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
);

Map<String, dynamic> _$$ParsedPlanModelImplToJson(
  _$ParsedPlanModelImpl instance,
) => <String, dynamic>{
  'commandType': instance.commandType,
  'title': instance.title,
  'aiSummary': instance.aiSummary,
  'targetDate': instance.targetDate,
  'targetPropertyId': instance.targetPropertyId,
  'destinationPropertyId': instance.destinationPropertyId,
  'taskGroups': instance.taskGroups,
};

_$GroupProgressModelImpl _$$GroupProgressModelImplFromJson(
  Map<String, dynamic> json,
) => _$GroupProgressModelImpl(
  groupId: json['groupId'] as String,
  title: json['title'] as String,
  assignedUserId: json['assignedUserId'] as String? ?? '',
  assignedUserName: json['assignedUserName'] as String? ?? '',
  status: json['status'] as String? ?? 'pending',
  totalSteps: (json['totalSteps'] as num?)?.toInt() ?? 0,
  completedSteps: (json['completedSteps'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$GroupProgressModelImplToJson(
  _$GroupProgressModelImpl instance,
) => <String, dynamic>{
  'groupId': instance.groupId,
  'title': instance.title,
  'assignedUserId': instance.assignedUserId,
  'assignedUserName': instance.assignedUserName,
  'status': instance.status,
  'totalSteps': instance.totalSteps,
  'completedSteps': instance.completedSteps,
};

_$PlanProgressModelImpl _$$PlanProgressModelImplFromJson(
  Map<String, dynamic> json,
) => _$PlanProgressModelImpl(
  planId: json['planId'] as String,
  status: json['status'] as String,
  totalSteps: (json['totalSteps'] as num?)?.toInt() ?? 0,
  completedSteps: (json['completedSteps'] as num?)?.toInt() ?? 0,
  percentComplete: (json['percentComplete'] as num?)?.toDouble() ?? 0.0,
  byGroup:
      (json['byGroup'] as List<dynamic>?)
          ?.map((e) => GroupProgressModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$$PlanProgressModelImplToJson(
  _$PlanProgressModelImpl instance,
) => <String, dynamic>{
  'planId': instance.planId,
  'status': instance.status,
  'totalSteps': instance.totalSteps,
  'completedSteps': instance.completedSteps,
  'percentComplete': instance.percentComplete,
  'byGroup': instance.byGroup,
};
