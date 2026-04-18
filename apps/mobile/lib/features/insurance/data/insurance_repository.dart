import 'models/insurance_policy_model.dart';
import 'insurance_remote_data_source.dart';

class InsuranceRepository {
  InsuranceRepository(this._remote);

  final InsuranceRemoteDataSource _remote;

  Future<List<InsurancePolicyModel>> getPolicies() => _remote.getPolicies();

  Future<InsurancePolicyModel> getPolicy(String id) => _remote.getPolicy(id);

  Future<InsurancePolicyModel> createPolicy({
    required String provider,
    required String policyNumber,
    required String coverageType,
    required double totalCoverageAmount,
    double? premium,
    String currency = 'USD',
    required String startDate,
    required String expiresAt,
    String? notes,
  }) {
    final body = <String, dynamic>{
      'provider': provider,
      'policyNumber': policyNumber,
      'coverageType': coverageType,
      'totalCoverageAmount': totalCoverageAmount,
      if (premium != null) 'premium': premium,
      'currency': currency,
      'startDate': startDate,
      'expiresAt': expiresAt,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
    return _remote.createPolicy(body);
  }

  Future<InsurancePolicyModel> updatePolicy(
    String id, {
    String? provider,
    String? policyNumber,
    String? coverageType,
    double? totalCoverageAmount,
    double? premium,
    String? startDate,
    String? expiresAt,
    String? status,
    String? notes,
  }) {
    final body = <String, dynamic>{};
    if (provider != null) body['provider'] = provider;
    if (policyNumber != null) body['policyNumber'] = policyNumber;
    if (coverageType != null) body['coverageType'] = coverageType;
    if (totalCoverageAmount != null) {
      body['totalCoverageAmount'] = totalCoverageAmount;
    }
    if (premium != null) body['premium'] = premium;
    if (startDate != null) body['startDate'] = startDate;
    if (expiresAt != null) body['expiresAt'] = expiresAt;
    if (status != null) body['status'] = status;
    if (notes != null) body['notes'] = notes;
    return _remote.updatePolicy(id, body);
  }

  Future<void> deletePolicy(String id) => _remote.deletePolicy(id);

  Future<InsurancePolicyModel> attachItem(
    String policyId, {
    required String itemId,
    required double coveredValue,
    String currency = 'USD',
  }) {
    return _remote.attachItem(policyId, {
      'itemId': itemId,
      'coveredValue': coveredValue,
      'currency': currency,
    });
  }

  Future<InsurancePolicyModel> detachItem(
          String policyId, String itemId) =>
      _remote.detachItem(policyId, itemId);

  Future<CoverageGapReportModel> getCoverageGaps(String policyId) =>
      _remote.getCoverageGaps(policyId);
}
