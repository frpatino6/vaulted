import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/insurance/data/insurance_ai_remote_data_source.dart';
import 'package:vaulted/features/insurance/data/insurance_ai_remote_data_source_provider.dart';
import 'package:vaulted/features/insurance/data/models/insurance_ai_model.dart';
import 'package:vaulted/features/insurance/domain/insurance_ai_notifier.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockInsuranceAiRemoteDataSource extends Mock
    implements InsuranceAiRemoteDataSource {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CoverageAnalysisModel _fakeCoverageAnalysis() {
  return const CoverageAnalysisModel(
    overallRisk: 'medium',
    summary: 'Coverage is adequate but some items are underinsured.',
    recommendations: ['Add jewelry coverage'],
    renewalUrgency: 'low',
  );
}

ClaimDraftModel _fakeClaimDraft() {
  return const ClaimDraftModel(
    subject: 'Theft Claim',
    body: 'Dear AllState, I am writing to report a theft...',
    keyPoints: ['Item stolen', 'Police report filed'],
    nextSteps: ['Submit police report', 'Take photos'],
  );
}

ProviderContainer _makeContainer({
  required MockInsuranceAiRemoteDataSource dataSource,
}) {
  return ProviderContainer(
    overrides: [
      insuranceAiRemoteDataSourceProvider.overrideWithValue(dataSource),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockInsuranceAiRemoteDataSource mockDataSource;
  late ProviderContainer container;

  setUp(() {
    mockDataSource = MockInsuranceAiRemoteDataSource();
    container = _makeContainer(dataSource: mockDataSource);
  });

  tearDown(() {
    container.dispose();
  });

  // =========================================================================
  // CoverageAnalysisNotifier
  // =========================================================================
  group('CoverageAnalysisNotifier', () {
    group('initial state', () {
      test('starts as AsyncData with null after build', () async {
        await container.read(coverageAnalysisNotifierProvider.future);
        final state = container.read(coverageAnalysisNotifierProvider);
        expect(state, isA<AsyncData<CoverageAnalysisModel?>>());
        expect(state.value, isNull);
      });
    });

    group('load()', () {
      test('sets state to AsyncData with analysis on success', () async {
        final analysis = _fakeCoverageAnalysis();
        when(() => mockDataSource.analyzeCoverage('pol-1'))
            .thenAnswer((_) async => analysis);

        await container.read(coverageAnalysisNotifierProvider.future);
        await container
            .read(coverageAnalysisNotifierProvider.notifier)
            .load('pol-1');

        final state = container.read(coverageAnalysisNotifierProvider);
        expect(state.value, analysis);
      });

      test('transitions through AsyncLoading', () async {
        when(() => mockDataSource.analyzeCoverage(any()))
            .thenAnswer((_) async => _fakeCoverageAnalysis());

        // Wait for initial build to settle
        await container.read(coverageAnalysisNotifierProvider.future);

        final states = <AsyncValue<CoverageAnalysisModel?>>[];
        container.listen(
          coverageAnalysisNotifierProvider,
          (_, next) => states.add(next),
          fireImmediately: false,
        );

        await container
            .read(coverageAnalysisNotifierProvider.notifier)
            .load('pol-1');

        expect(states.first, isA<AsyncLoading<CoverageAnalysisModel?>>());
        expect(states.last, isA<AsyncData<CoverageAnalysisModel?>>());
      });

      test('sets AsyncError when data source throws', () async {
        when(() => mockDataSource.analyzeCoverage(any()))
            .thenThrow(Exception('AI error'));

        await container.read(coverageAnalysisNotifierProvider.future);
        await container
            .read(coverageAnalysisNotifierProvider.notifier)
            .load('pol-1');

        expect(
          container.read(coverageAnalysisNotifierProvider),
          isA<AsyncError<CoverageAnalysisModel?>>(),
        );
      });
    });

    group('message()', () {
      test('returns rate-limit message for 429 DioException', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/ai/insurance'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/ai/insurance'),
            statusCode: 429,
          ),
        );

        expect(
          CoverageAnalysisNotifier.message(error),
          'AI rate limit reached. Please try again in an hour.',
        );
      });

      test('extracts message from DioException response body', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/ai/insurance'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/ai/insurance'),
            statusCode: 422,
            data: {
              'error': {'message': 'Policy has no items'},
            },
          ),
        );

        expect(CoverageAnalysisNotifier.message(error), 'Policy has no items');
      });

      test('returns generic fallback for non-DioException', () {
        expect(
          CoverageAnalysisNotifier.message(Exception('boom')),
          'Something went wrong. Please try again.',
        );
      });
    });
  });

  // =========================================================================
  // ClaimDraftNotifier
  // =========================================================================
  group('ClaimDraftNotifier', () {
    group('initial state', () {
      test('starts as AsyncData with null after build', () async {
        await container.read(claimDraftNotifierProvider.future);
        final state = container.read(claimDraftNotifierProvider);
        expect(state, isA<AsyncData<ClaimDraftModel?>>());
        expect(state.value, isNull);
      });
    });

    group('draft()', () {
      test('sets state to AsyncData with draft on success', () async {
        final draft = _fakeClaimDraft();
        when(
          () => mockDataSource.draftClaim(
            policyId: 'pol-1',
            itemId: 'item-1',
            incidentDescription: 'Theft occurred on 2024-01-15',
          ),
        ).thenAnswer((_) async => draft);

        await container.read(claimDraftNotifierProvider.future);
        await container.read(claimDraftNotifierProvider.notifier).draft(
              'pol-1',
              'item-1',
              'Theft occurred on 2024-01-15',
            );

        expect(container.read(claimDraftNotifierProvider).value, draft);
      });

      test('accepts null itemId', () async {
        final draft = _fakeClaimDraft();
        when(
          () => mockDataSource.draftClaim(
            policyId: 'pol-1',
            itemId: null,
            incidentDescription: 'Fire damage',
          ),
        ).thenAnswer((_) async => draft);

        await container.read(claimDraftNotifierProvider.future);
        await container.read(claimDraftNotifierProvider.notifier).draft(
              'pol-1',
              null,
              'Fire damage',
            );

        expect(container.read(claimDraftNotifierProvider).value, draft);
      });

      test('sets AsyncError when data source throws', () async {
        when(
          () => mockDataSource.draftClaim(
            policyId: any(named: 'policyId'),
            itemId: any(named: 'itemId'),
            incidentDescription: any(named: 'incidentDescription'),
          ),
        ).thenThrow(Exception('AI error'));

        await container.read(claimDraftNotifierProvider.future);
        await container.read(claimDraftNotifierProvider.notifier).draft(
              'pol-1',
              null,
              'description',
            );

        expect(
          container.read(claimDraftNotifierProvider),
          isA<AsyncError<ClaimDraftModel?>>(),
        );
      });

      test('transitions through AsyncLoading', () async {
        when(
          () => mockDataSource.draftClaim(
            policyId: any(named: 'policyId'),
            itemId: any(named: 'itemId'),
            incidentDescription: any(named: 'incidentDescription'),
          ),
        ).thenAnswer((_) async => _fakeClaimDraft());

        // Wait for initial build to settle
        await container.read(claimDraftNotifierProvider.future);

        final states = <AsyncValue<ClaimDraftModel?>>[];
        container.listen(
          claimDraftNotifierProvider,
          (_, next) => states.add(next),
          fireImmediately: false,
        );

        await container.read(claimDraftNotifierProvider.notifier).draft(
              'pol-1',
              null,
              'description',
            );

        expect(states.first, isA<AsyncLoading<ClaimDraftModel?>>());
        expect(states.last, isA<AsyncData<ClaimDraftModel?>>());
      });
    });

    group('message()', () {
      test('returns rate-limit message for 429 DioException', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/ai/claim-draft'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/ai/claim-draft'),
            statusCode: 429,
          ),
        );

        expect(
          ClaimDraftNotifier.message(error),
          'AI rate limit reached. Please try again in an hour.',
        );
      });

      test('returns generic fallback for non-DioException', () {
        expect(
          ClaimDraftNotifier.message(Exception('fail')),
          'Something went wrong. Please try again.',
        );
      });
    });
  });
}
