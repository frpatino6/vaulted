// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insurance_policy_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$InsuredItemModelImpl _$$InsuredItemModelImplFromJson(
  Map<String, dynamic> json,
) => _$InsuredItemModelImpl(
  id: json['id'] as String,
  policyId: json['policyId'] as String,
  itemId: json['itemId'] as String,
  coveredValue:
      json['coveredValue'] == null ? 0.0 : _parseDouble(json['coveredValue']),
  currency: json['currency'] as String? ?? 'USD',
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$$InsuredItemModelImplToJson(
  _$InsuredItemModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'policyId': instance.policyId,
  'itemId': instance.itemId,
  'coveredValue': instance.coveredValue,
  'currency': instance.currency,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};

_$InsurancePolicyModelImpl _$$InsurancePolicyModelImplFromJson(
  Map<String, dynamic> json,
) => _$InsurancePolicyModelImpl(
  id: json['id'] as String,
  tenantId: json['tenantId'] as String,
  provider: json['provider'] as String,
  policyNumber: json['policyNumber'] as String,
  coverageType: json['coverageType'] as String,
  totalCoverageAmount:
      json['totalCoverageAmount'] == null
          ? 0.0
          : _parseDouble(json['totalCoverageAmount']),
  premium: _parseDoubleNullable(json['premium']),
  currency: json['currency'] as String? ?? 'USD',
  startDate: json['startDate'] as String,
  expiresAt: json['expiresAt'] as String,
  status: json['status'] as String? ?? 'active',
  notes: json['notes'] as String?,
  insuredItems:
      (json['insuredItems'] as List<dynamic>?)
          ?.map((e) => InsuredItemModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$$InsurancePolicyModelImplToJson(
  _$InsurancePolicyModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'tenantId': instance.tenantId,
  'provider': instance.provider,
  'policyNumber': instance.policyNumber,
  'coverageType': instance.coverageType,
  'totalCoverageAmount': instance.totalCoverageAmount,
  'premium': instance.premium,
  'currency': instance.currency,
  'startDate': instance.startDate,
  'expiresAt': instance.expiresAt,
  'status': instance.status,
  'notes': instance.notes,
  'insuredItems': instance.insuredItems,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};

_$CoverageGapItemModelImpl _$$CoverageGapItemModelImplFromJson(
  Map<String, dynamic> json,
) => _$CoverageGapItemModelImpl(
  itemId: json['itemId'] as String,
  itemName: json['itemName'] as String,
  currentValue: (json['currentValue'] as num).toDouble(),
  coveredValue: (json['coveredValue'] as num?)?.toDouble(),
  gap: (json['gap'] as num).toDouble(),
  fullyUninsured: json['fullyUninsured'] as bool,
);

Map<String, dynamic> _$$CoverageGapItemModelImplToJson(
  _$CoverageGapItemModelImpl instance,
) => <String, dynamic>{
  'itemId': instance.itemId,
  'itemName': instance.itemName,
  'currentValue': instance.currentValue,
  'coveredValue': instance.coveredValue,
  'gap': instance.gap,
  'fullyUninsured': instance.fullyUninsured,
};

_$CoverageGapReportModelImpl _$$CoverageGapReportModelImplFromJson(
  Map<String, dynamic> json,
) => _$CoverageGapReportModelImpl(
  policyId: json['policyId'] as String,
  totalInventoryValue: (json['totalInventoryValue'] as num).toDouble(),
  totalCoveredValue: (json['totalCoveredValue'] as num).toDouble(),
  totalGap: (json['totalGap'] as num).toDouble(),
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => CoverageGapItemModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$$CoverageGapReportModelImplToJson(
  _$CoverageGapReportModelImpl instance,
) => <String, dynamic>{
  'policyId': instance.policyId,
  'totalInventoryValue': instance.totalInventoryValue,
  'totalCoveredValue': instance.totalCoveredValue,
  'totalGap': instance.totalGap,
  'items': instance.items,
};
