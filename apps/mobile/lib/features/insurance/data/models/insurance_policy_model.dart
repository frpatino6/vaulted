import 'package:freezed_annotation/freezed_annotation.dart';

part 'insurance_policy_model.freezed.dart';
part 'insurance_policy_model.g.dart';

/// Converts a dynamic value (string or number) to double.
/// TypeORM returns `numeric` columns as strings from PostgreSQL.
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

/// Nullable variant — premium is nullable on the policy.
double? _parseDoubleNullable(dynamic value) {
  if (value == null) return null;
  return _parseDouble(value);
}

@freezed
class InsuredItemModel with _$InsuredItemModel {
  const factory InsuredItemModel({
    required String id,
    required String policyId,
    required String itemId,
    @Default('') String itemName,
    @JsonKey(fromJson: _parseDouble) @Default(0.0) double coveredValue,
    @Default('USD') String currency,
    String? createdAt,
    String? updatedAt,
  }) = _InsuredItemModel;

  factory InsuredItemModel.fromJson(Map<String, dynamic> json) =>
      _$InsuredItemModelFromJson(json);
}

@freezed
class InsurancePolicyModel with _$InsurancePolicyModel {
  const factory InsurancePolicyModel({
    required String id,
    required String tenantId,
    required String provider,
    required String policyNumber,
    required String coverageType,
    @JsonKey(fromJson: _parseDouble) @Default(0.0) double totalCoverageAmount,
    @JsonKey(fromJson: _parseDoubleNullable) double? premium,
    @Default('USD') String currency,
    required String startDate,
    required String expiresAt,
    @Default('active') String status,
    String? notes,
    @Default([]) List<InsuredItemModel> insuredItems,
    String? createdAt,
    String? updatedAt,
  }) = _InsurancePolicyModel;

  factory InsurancePolicyModel.fromJson(Map<String, dynamic> json) =>
      _$InsurancePolicyModelFromJson(json);
}

extension InsurancePolicyModelX on InsurancePolicyModel {
  bool get isActive => status == 'active';
  bool get isExpired => status == 'expired';
  bool get isCancelled => status == 'cancelled';

  bool get isExpiringSoon {
    final expiry = DateTime.tryParse(expiresAt);
    if (expiry == null) return false;
    final daysLeft = expiry.difference(DateTime.now()).inDays;
    return isActive && daysLeft >= 0 && daysLeft <= 30;
  }

  String get coverageTypeLabel {
    switch (coverageType) {
      case 'all-risk':
        return 'All Risk';
      case 'named-peril':
        return 'Named Peril';
      case 'liability':
        return 'Liability';
      case 'scheduled':
        return 'Scheduled';
      default:
        return coverageType;
    }
  }
}

// ─── Coverage Gap Models ───────────────────────────────────────────────────

@freezed
class CoverageGapItemModel with _$CoverageGapItemModel {
  const factory CoverageGapItemModel({
    required String itemId,
    required String itemName,
    required double currentValue,
    double? coveredValue,
    required double gap,
    required bool fullyUninsured,
  }) = _CoverageGapItemModel;

  factory CoverageGapItemModel.fromJson(Map<String, dynamic> json) =>
      _$CoverageGapItemModelFromJson(json);
}

@freezed
class CoverageGapReportModel with _$CoverageGapReportModel {
  const factory CoverageGapReportModel({
    required String policyId,
    required double totalInventoryValue,
    required double totalCoveredValue,
    required double totalGap,
    @Default([]) List<CoverageGapItemModel> items,
  }) = _CoverageGapReportModel;

  factory CoverageGapReportModel.fromJson(Map<String, dynamic> json) =>
      _$CoverageGapReportModelFromJson(json);
}
