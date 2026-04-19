import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaulted/features/insurance/data/insurance_remote_data_source.dart';

/// Minimal policy JSON matching [InsurancePolicyModel.fromJson] (camelCase API).
Map<String, dynamic> samplePolicyJson({
  required String id,
  List<Map<String, dynamic>> insuredItems = const [],
}) {
  return {
    'id': id,
    'tenantId': 'tenant-1',
    'provider': 'Acme Insurance',
    'policyNumber': 'POL-001',
    'coverageType': 'all-risk',
    'totalCoverageAmount': 1000000,
    'premium': 1200.5,
    'currency': 'USD',
    'startDate': '2025-01-01T00:00:00.000Z',
    'expiresAt': '2027-01-01T00:00:00.000Z',
    'status': 'active',
    'notes': null,
    'insuredItems': insuredItems,
    'createdAt': '2025-01-01T00:00:00.000Z',
    'updatedAt': '2025-01-01T00:00:00.000Z',
  };
}

InterceptorsWrapper _stubInsuranceInterceptor({
  required List<String> callLog,
  required String policyId,
  Map<String, dynamic>? insuredItemPayload,
  List<Map<String, dynamic>> policyInsuredItems = const [],
  bool deleteReturnsDataKey = false,
}) {
  return InterceptorsWrapper(
    onRequest: (options, handler) {
      callLog.add('${options.method} ${options.path}');
      final path = options.path;

      if (options.method == 'POST' && path == 'insurance/policies/$policyId/items') {
        return handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': insuredItemPayload ??
                  {
                    'id': 'insured-row-1',
                    'tenantId': 'tenant-1',
                    'policyId': policyId,
                    'itemId': '507f1f77bcf86cd799439011',
                    'coveredValue': '50000.00',
                    'currency': 'USD',
                    'createdAt': '2026-01-01T00:00:00.000Z',
                    'updatedAt': '2026-01-01T00:00:00.000Z',
                  },
            },
          ),
        );
      }

      if (options.method == 'DELETE' &&
          path == 'insurance/policies/$policyId/items/507f1f77bcf86cd799439011') {
        return handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: deleteReturnsDataKey
                ? {'success': true, 'data': null}
                : {'success': true},
          ),
        );
      }

      if (options.method == 'GET' && path == 'insurance/policies/$policyId') {
        return handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': samplePolicyJson(
                id: policyId,
                insuredItems: policyInsuredItems,
              ),
            },
          ),
        );
      }

      return handler.reject(
        DioException(
          requestOptions: options,
          error: 'Unexpected request ${options.method} $path',
        ),
      );
    },
  );
}

void main() {
  group('InsuranceRemoteDataSource', () {
    test(
        'attachItem succeeds when POST data is only InsuredItem — refetches policy',
        () async {
      const policyId = 'p1';
      final callLog = <String>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://test/'));
      dio.interceptors.add(
        _stubInsuranceInterceptor(
          callLog: callLog,
          policyId: policyId,
          policyInsuredItems: [
            {
              'id': 'insured-row-1',
              'policyId': policyId,
              'itemId': '507f1f77bcf86cd799439011',
              'coveredValue': '50000.00',
              'currency': 'USD',
              'createdAt': '2026-01-01T00:00:00.000Z',
              'updatedAt': '2026-01-01T00:00:00.000Z',
            },
          ],
        ),
      );

      final ds = InsuranceRemoteDataSource(dio);
      final policy = await ds.attachItem(policyId, {
        'itemId': '507f1f77bcf86cd799439011',
        'coveredValue': 50000.0,
        'currency': 'USD',
      });

      expect(policy.id, policyId);
      expect(policy.provider, 'Acme Insurance');
      expect(policy.insuredItems, hasLength(1));
      expect(policy.insuredItems.first.itemId, '507f1f77bcf86cd799439011');
      expect(policy.insuredItems.first.coveredValue, 50000.0);

      expect(callLog, [
        'POST insurance/policies/$policyId/items',
        'GET insurance/policies/$policyId',
      ]);
    });

    test('detachItem refetches policy when DELETE returns success without body',
        () async {
      const policyId = 'p1';
      final callLog = <String>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://test/'));
      dio.interceptors.add(
        _stubInsuranceInterceptor(
          callLog: callLog,
          policyId: policyId,
          policyInsuredItems: const [],
          deleteReturnsDataKey: false,
        ),
      );

      final ds = InsuranceRemoteDataSource(dio);
      final policy = await ds.detachItem(
        policyId,
        '507f1f77bcf86cd799439011',
      );

      expect(policy.id, policyId);
      expect(policy.insuredItems, isEmpty);
      expect(callLog, [
        'DELETE insurance/policies/$policyId/items/507f1f77bcf86cd799439011',
        'GET insurance/policies/$policyId',
      ]);
    });

    test('detachItem refetches policy when DELETE returns success with null data',
        () async {
      const policyId = 'p2';
      final callLog = <String>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://test/'));
      dio.interceptors.add(
        _stubInsuranceInterceptor(
          callLog: callLog,
          policyId: policyId,
          deleteReturnsDataKey: true,
        ),
      );

      final ds = InsuranceRemoteDataSource(dio);
      final policy = await ds.detachItem(
        policyId,
        '507f1f77bcf86cd799439011',
      );

      expect(policy.id, policyId);
      expect(callLog, hasLength(2));
      expect(callLog.first, startsWith('DELETE'));
      expect(callLog.last, 'GET insurance/policies/$policyId');
    });
  });
}
