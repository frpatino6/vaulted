import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/insurance/data/insurance_ai_remote_data_source.dart';

import '../../../support/dio_test_support.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late InsuranceAiRemoteDataSource dataSource;
  late RequestOptions requestOptions;

  setUp(() {
    mockDio = MockDio();
    dataSource = InsuranceAiRemoteDataSource(mockDio);
    requestOptions = RequestOptions(path: '/test');
  });

  group('analyzeCoverage', () {
    test('POSTs analyze endpoint and unwraps model', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          'ai/insurance/policies/pol-9/analyze',
        ),
      ).thenAnswer(
        (_) async => makeMapResponse(
          requestOptions: requestOptions,
          data: {
            'success': true,
            'data': {
              'overallRisk': 'medium',
              'summary': 'Review limits',
              'recommendations': ['Add rider'],
              'priorityItems': <dynamic>[],
              'renewalUrgency': 'soon',
            },
          },
        ),
      );

      final analysis = await dataSource.analyzeCoverage('pol-9');

      expect(analysis.overallRisk, 'medium');
      expect(analysis.summary, 'Review limits');
      expect(analysis.recommendations, ['Add rider']);
      expect(analysis.renewalUrgency, 'soon');
    });
  });

  group('draftClaim', () {
    test('POSTs body with optional itemId omitted when null', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          'ai/insurance/claim-draft',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => makeMapResponse(
          requestOptions: requestOptions,
          data: {
            'success': true,
            'data': {
              'subject': 'Claim',
              'body': 'Dear insurer',
              'keyPoints': <String>[],
              'nextSteps': <String>[],
            },
          },
        ),
      );

      final draft = await dataSource.draftClaim(
        policyId: 'p1',
        incidentDescription: 'Hail damage',
      );

      expect(draft.subject, 'Claim');
      final body = verify(
        () => mockDio.post<Map<String, dynamic>>(
          'ai/insurance/claim-draft',
          data: captureAny(named: 'data'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(body.keys.toSet(), {'policyId', 'incidentDescription'});
    });

    test('includes itemId when provided', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          'ai/insurance/claim-draft',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => makeMapResponse(
          requestOptions: requestOptions,
          data: {
            'success': true,
            'data': {
              'subject': 'S',
              'body': 'B',
              'keyPoints': <String>[],
              'nextSteps': <String>[],
            },
          },
        ),
      );

      await dataSource.draftClaim(
        policyId: 'p1',
        itemId: 'it-1',
        incidentDescription: 'Theft',
      );

      final body = verify(
        () => mockDio.post<Map<String, dynamic>>(
          'ai/insurance/claim-draft',
          data: captureAny(named: 'data'),
        ),
      ).captured.single as Map<String, dynamic>;

      expect(body['itemId'], 'it-1');
    });
  });

  test('throws DioException on failure envelope', () async {
    when(
      () => mockDio.post<Map<String, dynamic>>(
        'ai/insurance/policies/x/analyze',
      ),
    ).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': false, 'error': {'message': 'busy'}},
      ),
    );

    expect(
      () => dataSource.analyzeCoverage('x'),
      throwsA(
        isA<DioException>().having(
          (e) => e.error,
          'error',
          'busy',
        ),
      ),
    );
  });
}
