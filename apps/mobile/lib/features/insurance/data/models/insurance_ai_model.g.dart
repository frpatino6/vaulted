// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insurance_ai_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CoverageAnalysisModelImpl _$$CoverageAnalysisModelImplFromJson(
  Map<String, dynamic> json,
) => _$CoverageAnalysisModelImpl(
  overallRisk: json['overallRisk'] as String,
  summary: json['summary'] as String,
  recommendations:
      (json['recommendations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  priorityItems:
      (json['priorityItems'] as List<dynamic>?)
          ?.map((e) => PriorityItemModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  renewalUrgency: json['renewalUrgency'] as String,
);

Map<String, dynamic> _$$CoverageAnalysisModelImplToJson(
  _$CoverageAnalysisModelImpl instance,
) => <String, dynamic>{
  'overallRisk': instance.overallRisk,
  'summary': instance.summary,
  'recommendations': instance.recommendations,
  'priorityItems': instance.priorityItems,
  'renewalUrgency': instance.renewalUrgency,
};

_$PriorityItemModelImpl _$$PriorityItemModelImplFromJson(
  Map<String, dynamic> json,
) => _$PriorityItemModelImpl(
  itemId: json['itemId'] as String,
  itemName: json['itemName'] as String,
  issue: json['issue'] as String,
);

Map<String, dynamic> _$$PriorityItemModelImplToJson(
  _$PriorityItemModelImpl instance,
) => <String, dynamic>{
  'itemId': instance.itemId,
  'itemName': instance.itemName,
  'issue': instance.issue,
};

_$ClaimDraftModelImpl _$$ClaimDraftModelImplFromJson(
  Map<String, dynamic> json,
) => _$ClaimDraftModelImpl(
  subject: json['subject'] as String,
  body: json['body'] as String,
  keyPoints:
      (json['keyPoints'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  nextSteps:
      (json['nextSteps'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$$ClaimDraftModelImplToJson(
  _$ClaimDraftModelImpl instance,
) => <String, dynamic>{
  'subject': instance.subject,
  'body': instance.body,
  'keyPoints': instance.keyPoints,
  'nextSteps': instance.nextSteps,
};
