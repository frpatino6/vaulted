import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/insurance/data/insurance_repository.dart';
import 'package:vaulted/features/insurance/data/insurance_repository_provider.dart';
import 'package:vaulted/features/insurance/data/models/insurance_policy_model.dart';
import 'package:vaulted/features/insurance/domain/coverage_gaps_notifier.dart';

class MockInsuranceRepository extends Mock implements InsuranceRepository {}

CoverageGapReportModel _fakeReport() {
  return CoverageGapReportModel(
    uncovered: const [
      CoverageGapItemModel(
        itemId: 'item-1',
        name: 'Painting',
        category: 'art',
        currentValue: 50_000,
        coveredValue: 0,
        gap: 50_000,
        currency: 'USD',
      ),
    ],
    underinsured: const [],
    totalUncoveredValue: 50_000,
    totalUnderinsuredGap: 0,
  );
}

ProviderContainer _makeContainer(MockInsuranceRepository repo) {
  return ProviderContainer(
    overrides: [
      insuranceRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

void main() {
  late MockInsuranceRepository mockRepo;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    mockRepo = MockInsuranceRepository();
  });

  group('CoverageGapsNotifier — build', () {
    test('initial future completes to null without calling repository', () async {
      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      final initial = await container.read(coverageGapsNotifierProvider.future);

      expect(initial, isNull);
      verifyNever(() => mockRepo.getCoverageGaps(any()));
    });
  });

  group('CoverageGapsNotifier.load', () {
    test('loads report and sets AsyncData', () async {
      final report = _fakeReport();
      when(() => mockRepo.getCoverageGaps('pol-99')).thenAnswer((_) async => report);

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container.read(coverageGapsNotifierProvider.future);

      await container.read(coverageGapsNotifierProvider.notifier).load('pol-99');

      expect(container.read(coverageGapsNotifierProvider).value, report);
      verify(() => mockRepo.getCoverageGaps('pol-99')).called(1);
    });

    test('sets AsyncError when repository throws', () async {
      when(() => mockRepo.getCoverageGaps(any())).thenThrow(Exception('network'));

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container.read(coverageGapsNotifierProvider.future);
      await container.read(coverageGapsNotifierProvider.notifier).load('pol-1');

      final async = container.read(coverageGapsNotifierProvider);
      expect(async.hasError, true);
      expect(async.error, isA<Exception>());
    });
  });

  group('CoverageGapsNotifier.message', () {
    test('returns nested error message for DioException with map body', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          data: <String, dynamic>{
            'error': <String, dynamic>{'message': 'Gap analysis unavailable'},
          },
        ),
      );

      expect(CoverageGapsNotifier.message(e), 'Gap analysis unavailable');
    });

    test('returns fallback when error is not DioException', () {
      expect(
        CoverageGapsNotifier.message(Exception('x')),
        'Something went wrong. Please try again.',
      );
    });

    test('returns fallback when DioException body has no string message', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          data: <String, dynamic>{'error': <String, dynamic>{}},
        ),
      );

      expect(
        CoverageGapsNotifier.message(e),
        'Something went wrong. Please try again.',
      );
    });
  });
}
