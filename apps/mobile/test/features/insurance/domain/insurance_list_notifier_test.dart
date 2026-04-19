import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/insurance/data/insurance_repository.dart';
import 'package:vaulted/features/insurance/data/insurance_repository_provider.dart';
import 'package:vaulted/features/insurance/data/models/insurance_policy_model.dart';
import 'package:vaulted/features/insurance/domain/insurance_list_notifier.dart';

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
  group('InsuranceListNotifier — initial state', () {
    test('starts as AsyncData with empty list after build', () async {
      await container.read(insuranceListNotifierProvider.future);
      final state = container.read(insuranceListNotifierProvider);
      expect(state, isA<AsyncData<List<InsurancePolicyModel>>>());
      expect(state.value, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // load()
  // -------------------------------------------------------------------------
  group('InsuranceListNotifier.load', () {
    test('sets state to AsyncData with policies on success', () async {
      final policies = [_fakePolicy(id: 'p1'), _fakePolicy(id: 'p2')];
      when(() => mockRepo.getPolicies()).thenAnswer((_) async => policies);

      await container.read(insuranceListNotifierProvider.future);
      await container.read(insuranceListNotifierProvider.notifier).load();

      final state = container.read(insuranceListNotifierProvider);
      expect(state.value, policies);
    });

    test('transitions through AsyncLoading before settling', () async {
      when(() => mockRepo.getPolicies()).thenAnswer((_) async => []);

      // Wait for the initial build to complete
      await container.read(insuranceListNotifierProvider.future);

      final states = <AsyncValue<List<InsurancePolicyModel>>>[];
      container.listen(
        insuranceListNotifierProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container.read(insuranceListNotifierProvider.notifier).load();

      expect(states.first, isA<AsyncLoading<List<InsurancePolicyModel>>>());
      expect(states.last, isA<AsyncData<List<InsurancePolicyModel>>>());
    });

    test('transitions to AsyncError when repository throws', () async {
      when(() => mockRepo.getPolicies()).thenThrow(Exception('server error'));

      await container.read(insuranceListNotifierProvider.future).catchError((_) => <InsurancePolicyModel>[]);
      await container.read(insuranceListNotifierProvider.notifier).load();

      expect(
        container.read(insuranceListNotifierProvider),
        isA<AsyncError<List<InsurancePolicyModel>>>(),
      );
    });
  });

  // -------------------------------------------------------------------------
  // refresh()
  // -------------------------------------------------------------------------
  group('InsuranceListNotifier.refresh', () {
    test('re-fetches without resetting to AsyncLoading', () async {
      when(() => mockRepo.getPolicies()).thenAnswer((_) async => [_fakePolicy()]);

      final notifier = container.read(insuranceListNotifierProvider.notifier);
      await notifier.load();

      final states = <AsyncValue<List<InsurancePolicyModel>>>[];
      container.listen(
        insuranceListNotifierProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      when(() => mockRepo.getPolicies()).thenAnswer(
        (_) async => [_fakePolicy(id: 'p1'), _fakePolicy(id: 'p2')],
      );
      await notifier.refresh();

      // refresh() does NOT set AsyncLoading first
      expect(states.every((s) => s is! AsyncLoading), isTrue);
      expect(container.read(insuranceListNotifierProvider).value!.length, 2);
    });
  });

  // -------------------------------------------------------------------------
  // deletePolicy()
  // -------------------------------------------------------------------------
  group('InsuranceListNotifier.deletePolicy', () {
    test('removes deleted policy from state', () async {
      final p1 = _fakePolicy(id: 'p1');
      final p2 = _fakePolicy(id: 'p2');
      when(() => mockRepo.getPolicies()).thenAnswer((_) async => [p1, p2]);
      when(() => mockRepo.deletePolicy('p1')).thenAnswer((_) async {});

      final notifier = container.read(insuranceListNotifierProvider.notifier);
      await notifier.load();
      await notifier.deletePolicy('p1');

      final remaining = container.read(insuranceListNotifierProvider).value!;
      expect(remaining.length, 1);
      expect(remaining.first.id, 'p2');
    });

    test('propagates exception from repository', () async {
      when(() => mockRepo.getPolicies()).thenAnswer((_) async => [_fakePolicy()]);
      when(() => mockRepo.deletePolicy(any())).thenThrow(Exception('delete failed'));

      final notifier = container.read(insuranceListNotifierProvider.notifier);
      await notifier.load();

      await expectLater(
        notifier.deletePolicy('pol-1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // message()
  // -------------------------------------------------------------------------
  group('InsuranceListNotifier.message', () {
    test('extracts message from DioException response body', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/insurance'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/insurance'),
          statusCode: 422,
          data: {
            'error': {'message': 'Policy not found'},
          },
        ),
      );

      expect(InsuranceListNotifier.message(error), 'Policy not found');
    });

    test('returns generic fallback for non-DioException', () {
      expect(
        InsuranceListNotifier.message(Exception('boom')),
        'Something went wrong. Please try again.',
      );
    });
  });
}
