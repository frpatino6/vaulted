import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/insurance/data/insurance_repository.dart';
import 'package:vaulted/features/insurance/data/insurance_repository_provider.dart';
import 'package:vaulted/features/insurance/data/models/insurance_policy_model.dart';
import 'package:vaulted/features/insurance/domain/insurance_detail_notifier.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockInsuranceRepository extends Mock implements InsuranceRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

InsurancePolicyModel _fakePolicy({
  String id = 'pol-1',
  String provider = 'AllState',
}) {
  return InsurancePolicyModel(
    id: id,
    tenantId: 'tenant-1',
    provider: provider,
    policyNumber: 'PN-001',
    coverageType: 'all-risk',
    startDate: '2024-01-01',
    expiresAt: '2025-01-01',
  );
}

ProviderContainer _makeContainer({required MockInsuranceRepository repo}) {
  return ProviderContainer(
    overrides: [
      insuranceRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockInsuranceRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockInsuranceRepository();
    container = _makeContainer(repo: mockRepo);
  });

  tearDown(() {
    container.dispose();
  });

  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------
  group('InsuranceDetailNotifier — initial state', () {
    test('starts as AsyncData with null after build', () async {
      await container.read(insuranceDetailNotifierProvider.future);
      final state = container.read(insuranceDetailNotifierProvider);
      expect(state, isA<AsyncData<InsurancePolicyModel?>>());
      expect(state.value, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // load()
  // -------------------------------------------------------------------------
  group('InsuranceDetailNotifier.load', () {
    test('sets state to AsyncData with policy on success', () async {
      final policy = _fakePolicy();
      when(() => mockRepo.getPolicy('pol-1')).thenAnswer((_) async => policy);

      await container.read(insuranceDetailNotifierProvider.future);
      await container.read(insuranceDetailNotifierProvider.notifier).load('pol-1');

      final state = container.read(insuranceDetailNotifierProvider);
      expect(state.value, policy);
    });

    test('sets state to AsyncError when repository throws', () async {
      when(() => mockRepo.getPolicy(any())).thenThrow(Exception('not found'));

      await container.read(insuranceDetailNotifierProvider.future);
      await container.read(insuranceDetailNotifierProvider.notifier).load('bad');

      final state = container.read(insuranceDetailNotifierProvider);
      expect(state, isA<AsyncError<InsurancePolicyModel?>>());
    });

    test('transitions through AsyncLoading before settling', () async {
      final policy = _fakePolicy();
      when(() => mockRepo.getPolicy('pol-1')).thenAnswer((_) async => policy);

      // Wait for the initial build to complete
      await container.read(insuranceDetailNotifierProvider.future);

      final states = <AsyncValue<InsurancePolicyModel?>>[];
      container.listen(
        insuranceDetailNotifierProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container.read(insuranceDetailNotifierProvider.notifier).load('pol-1');

      expect(states.first, isA<AsyncLoading<InsurancePolicyModel?>>());
      expect(states.last, isA<AsyncData<InsurancePolicyModel?>>());
    });
  });

  // -------------------------------------------------------------------------
  // attachItem()
  // -------------------------------------------------------------------------
  group('InsuranceDetailNotifier.attachItem', () {
    test('updates state with the returned policy', () async {
      final initial = _fakePolicy();
      final updated = _fakePolicy(provider: 'Updated Provider');

      when(() => mockRepo.getPolicy('pol-1')).thenAnswer((_) async => initial);
      when(
        () => mockRepo.attachItem(
          'pol-1',
          itemId: 'item-1',
          coveredValue: 5000.0,
          currency: 'USD',
        ),
      ).thenAnswer((_) async => updated);

      final notifier = container.read(insuranceDetailNotifierProvider.notifier);
      await notifier.load('pol-1');
      await notifier.attachItem('pol-1', itemId: 'item-1', coveredValue: 5000.0);

      expect(container.read(insuranceDetailNotifierProvider).value, updated);
    });

    test('uses default currency USD', () async {
      final policy = _fakePolicy();
      when(() => mockRepo.getPolicy('pol-1')).thenAnswer((_) async => policy);
      when(
        () => mockRepo.attachItem(
          'pol-1',
          itemId: any(named: 'itemId'),
          coveredValue: any(named: 'coveredValue'),
          currency: 'USD',
        ),
      ).thenAnswer((_) async => policy);

      final notifier = container.read(insuranceDetailNotifierProvider.notifier);
      await notifier.load('pol-1');
      await notifier.attachItem('pol-1', itemId: 'item-1', coveredValue: 1000.0);

      verify(
        () => mockRepo.attachItem(
          'pol-1',
          itemId: 'item-1',
          coveredValue: 1000.0,
          currency: 'USD',
        ),
      ).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // detachItem()
  // -------------------------------------------------------------------------
  group('InsuranceDetailNotifier.detachItem', () {
    test('updates state with the returned policy after detach', () async {
      final initial = _fakePolicy();
      final updated = _fakePolicy(provider: 'After Detach');

      when(() => mockRepo.getPolicy('pol-1')).thenAnswer((_) async => initial);
      when(() => mockRepo.detachItem('pol-1', 'item-1'))
          .thenAnswer((_) async => updated);

      final notifier = container.read(insuranceDetailNotifierProvider.notifier);
      await notifier.load('pol-1');
      await notifier.detachItem('pol-1', 'item-1');

      expect(container.read(insuranceDetailNotifierProvider).value, updated);
    });
  });

  // -------------------------------------------------------------------------
  // message()
  // -------------------------------------------------------------------------
  group('InsuranceDetailNotifier.message', () {
    test('extracts message from DioException response body', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/insurance/pol-1'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/insurance/pol-1'),
          statusCode: 404,
          data: {
            'error': {'message': 'Policy not found'},
          },
        ),
      );

      expect(InsuranceDetailNotifier.message(error), 'Policy not found');
    });

    test('returns generic fallback for generic exception', () {
      expect(
        InsuranceDetailNotifier.message(Exception('fail')),
        'Something went wrong. Please try again.',
      );
    });
  });
}
