import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/dashboard/data/dashboard_repository.dart';
import 'package:vaulted/features/dashboard/data/dashboard_repository_provider.dart';
import 'package:vaulted/features/dashboard/data/models/dashboard_model.dart';
import 'package:vaulted/features/dashboard/domain/dashboard_notifier.dart';

class MockDashboardRepository extends Mock implements DashboardRepository {}

DashboardModel _fakeDashboard() {
  return const DashboardModel(
    totalProperties: 2,
    totalItems: 42,
    itemsByStatus: {'active': 40},
    itemsByCategory: {'furniture': 10},
    totalValuation: 1_250_000,
    currency: 'USD',
  );
}

ProviderContainer _makeContainer(MockDashboardRepository repo) {
  return ProviderContainer(
    overrides: [
      dashboardRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

void main() {
  late MockDashboardRepository mockRepo;

  setUp(() {
    mockRepo = MockDashboardRepository();
  });

  group('DashboardNotifier — build', () {
    test('loads dashboard from repository on first read', () async {
      final model = _fakeDashboard();
      when(() => mockRepo.getDashboard()).thenAnswer((_) async => model);

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      final result = await container.read(dashboardNotifierProvider.future);

      expect(result, model);
      verify(() => mockRepo.getDashboard()).called(1);
    });

    test('sets AsyncError and future throws when getDashboard fails', () async {
      when(() => mockRepo.getDashboard()).thenThrow(Exception('server down'));

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(dashboardNotifierProvider.future),
        throwsA(isA<Exception>()),
      );

      expect(container.read(dashboardNotifierProvider).hasError, true);
    });
  });

  group('DashboardNotifier.load', () {
    test('refreshes dashboard and returns data', () async {
      final first = _fakeDashboard();
      final second = DashboardModel(
        totalProperties: first.totalProperties,
        totalItems: 99,
        itemsByStatus: first.itemsByStatus,
        itemsByCategory: first.itemsByCategory,
        totalValuation: first.totalValuation,
        currency: first.currency,
      );

      when(() => mockRepo.getDashboard()).thenAnswer((_) async => first);

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container.read(dashboardNotifierProvider.future);

      when(() => mockRepo.getDashboard()).thenAnswer((_) async => second);

      final returned =
          await container.read(dashboardNotifierProvider.notifier).load();

      expect(returned, second);
      expect(container.read(dashboardNotifierProvider).value, second);
      verify(() => mockRepo.getDashboard()).called(2);
    });

    test('sets AsyncError and rethrows when repository throws', () async {
      final model = _fakeDashboard();
      when(() => mockRepo.getDashboard()).thenAnswer((_) async => model);

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container.read(dashboardNotifierProvider.future);

      when(() => mockRepo.getDashboard()).thenThrow(Exception('refresh failed'));

      await expectLater(
        () => container.read(dashboardNotifierProvider.notifier).load(),
        throwsA(isA<Exception>()),
      );

      expect(container.read(dashboardNotifierProvider).hasError, true);
    });
  });

  group('DashboardNotifier.message', () {
    test('strips DioException prefix from toString', () {
      final err = _ToStringError('DioException: connection timed out');

      expect(DashboardNotifier.message(err), 'connection timed out');
    });

    test('leaves toString unchanged when prefix absent', () {
      expect(DashboardNotifier.message(Exception('plain')), 'Exception: plain');
    });
  });
}

class _ToStringError implements Exception {
  _ToStringError(this._s);
  final String _s;

  @override
  String toString() => _s;
}
