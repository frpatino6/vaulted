import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/insurance/data/insurance_remote_data_source.dart';

import '../../../support/dio_test_support.dart';

class MockDio extends Mock implements Dio {}

Map<String, dynamic> _policyPayload({String id = 'pol-1'}) => {
      'id': id,
      'tenantId': 'ten-1',
      'provider': 'Acme',
      'policyNumber': 'PN-100',
      'coverageType': 'all-risk',
      'totalCoverageAmount': 250000,
      'premium': 1200,
      'currency': 'USD',
      'startDate': '2025-01-01',
      'expiresAt': '2027-01-01',
      'status': 'active',
      'insuredItems': <dynamic>[],
    };

void main() {
  late MockDio mockDio;
  late InsuranceRemoteDataSource dataSource;
  late RequestOptions requestOptions;

  setUp(() {
    mockDio = MockDio();
    dataSource = InsuranceRemoteDataSource(mockDio);
    requestOptions = RequestOptions(path: '/test');
  });

  group('getPolicies', () {
    test('returns list of policies on success', () async {
      when(() => mockDio.get<Map<String, dynamic>>('insurance/policies'))
          .thenAnswer(
        (_) async => makeMapResponse(
          requestOptions: requestOptions,
          data: {
            'success': true,
            'data': [_policyPayload(id: 'a'), _policyPayload(id: 'b')],
          },
        ),
      );

      final list = await dataSource.getPolicies();

      expect(list, hasLength(2));
      expect(list.map((p) => p.id).toList(), ['a', 'b']);
    });

    test('returns empty list when data is not a List', () async {
      when(() => mockDio.get<Map<String, dynamic>>('insurance/policies'))
          .thenAnswer(
        (_) async => makeMapResponse(
          requestOptions: requestOptions,
          data: {'success': true, 'data': <String, dynamic>{}},
        ),
      );

      expect(await dataSource.getPolicies(), isEmpty);
    });
  });

  group('getPolicy', () {
    test('unwraps single policy', () async {
      when(() => mockDio.get<Map<String, dynamic>>('insurance/policies/x'))
          .thenAnswer(
        (_) async => makeMapResponse(
          requestOptions: requestOptions,
          data: {'success': true, 'data': _policyPayload(id: 'x')},
        ),
      );

      final policy = await dataSource.getPolicy('x');

      expect(policy.id, 'x');
      expect(policy.provider, 'Acme');
    });
  });

  group('createPolicy', () {
    test('POSTs JSON body and returns model', () async {
      final body = _policyPayload();
      when(
        () => mockDio.post<Map<String, dynamic>>(
          'insurance/policies',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => makeMapResponse(
          requestOptions: requestOptions,
          data: {'success': true, 'data': _policyPayload()},
        ),
      );

      final created = await dataSource.createPolicy(body);

      expect(created.policyNumber, 'PN-100');
      verify(
        () => mockDio.post<Map<String, dynamic>>(
          'insurance/policies',
          data: body,
        ),
      ).called(1);
    });
  });

  group('updatePolicy', () {
    test('PUTs partial body', () async {
      when(
        () => mockDio.put<Map<String, dynamic>>(
          'insurance/policies/p1',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => makeMapResponse(
          requestOptions: requestOptions,
          data: {'success': true, 'data': _policyPayload()},
        ),
      );

      await dataSource.updatePolicy('p1', {'status': 'cancelled'});

      verify(
        () => mockDio.put<Map<String, dynamic>>(
          'insurance/policies/p1',
          data: {'status': 'cancelled'},
        ),
      ).called(1);
    });
  });

  group('deletePolicy', () {
    test('calls DELETE and tolerates success without data', () async {
      when(
        () => mockDio.delete<Map<String, dynamic>>('insurance/policies/p1'),
      ).thenAnswer(
        (_) async => makeMapResponse(
          requestOptions: requestOptions,
          data: {'success': true},
        ),
      );

      await expectLater(dataSource.deletePolicy('p1'), completes);
      verify(
        () => mockDio.delete<Map<String, dynamic>>('insurance/policies/p1'),
      ).called(1);
    });
  });

  group('attachItem / detachItem', () {
    test('attachItem POSTs, re-fetches policy and returns it', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          'insurance/policies/p1/items',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => makeMapResponse(
          requestOptions: requestOptions,
          // API returns only the InsuredItem row — not the full policy
          data: {'success': true, 'data': <String, dynamic>{}},
        ),
      );
      // Re-fetch the full policy after the POST
      when(() => mockDio.get<Map<String, dynamic>>('insurance/policies/p1'))
          .thenAnswer(
        (_) async => makeMapResponse(
          requestOptions: requestOptions,
          data: {'success': true, 'data': _policyPayload()},
        ),
      );

      final result = await dataSource.attachItem('p1', {
        'itemId': 'i1',
        'coveredValue': 5000.0,
        'currency': 'USD',
      });

      expect(result.policyNumber, 'PN-100');
      verify(
        () => mockDio.post<Map<String, dynamic>>(
          'insurance/policies/p1/items',
          data: {'itemId': 'i1', 'coveredValue': 5000.0, 'currency': 'USD'},
        ),
      ).called(1);
      verify(
        () => mockDio.get<Map<String, dynamic>>('insurance/policies/p1'),
      ).called(1);
    });

    test('detachItem DELETEs, re-fetches policy and returns it', () async {
      when(
        () => mockDio.delete<Map<String, dynamic>>(
          'insurance/policies/p1/items/i9',
        ),
      ).thenAnswer(
        (_) async => makeMapResponse(
          requestOptions: requestOptions,
          // DELETE returns {success: true} with no data body
          data: {'success': true},
        ),
      );
      // Re-fetch the full policy after the DELETE
      when(() => mockDio.get<Map<String, dynamic>>('insurance/policies/p1'))
          .thenAnswer(
        (_) async => makeMapResponse(
          requestOptions: requestOptions,
          data: {'success': true, 'data': _policyPayload()},
        ),
      );

      final policy = await dataSource.detachItem('p1', 'i9');

      expect(policy.id, 'pol-1');
      verify(
        () =>
            mockDio.delete<Map<String, dynamic>>('insurance/policies/p1/items/i9'),
      ).called(1);
      verify(
        () => mockDio.get<Map<String, dynamic>>('insurance/policies/p1'),
      ).called(1);
    });
  });

  group('getCoverageGaps', () {
    test('GETs coverage-gaps and parses report', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>('insurance/coverage-gaps'),
      ).thenAnswer(
        (_) async => makeMapResponse(
          requestOptions: requestOptions,
          data: {
            'success': true,
            'data': {
              'policyId': 'p1',
              'totalInventoryValue': 100,
              'totalCoveredValue': 40,
              'totalGap': 60,
              'items': <dynamic>[],
            },
          },
        ),
      );

      final report = await dataSource.getCoverageGaps('p1');

      expect(report.policyId, 'p1');
      expect(report.totalGap, 60);
      verify(
        () => mockDio.get<Map<String, dynamic>>('insurance/coverage-gaps'),
      ).called(1);
    });
  });

  test('throws DioException on error envelope', () async {
    when(() => mockDio.get<Map<String, dynamic>>('insurance/policies'))
        .thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {
          'success': false,
          'error': {'message': 'denied'},
        },
      ),
    );

    expect(
      () => dataSource.getPolicies(),
      throwsA(
        isA<DioException>().having(
          (e) => e.error,
          'error',
          'denied',
        ),
      ),
    );
  });
}
