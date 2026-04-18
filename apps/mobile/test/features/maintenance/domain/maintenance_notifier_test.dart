import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/maintenance/data/maintenance_repository.dart';
import 'package:vaulted/features/maintenance/data/maintenance_repository_provider.dart';
import 'package:vaulted/features/maintenance/data/models/maintenance_model.dart';
import 'package:vaulted/features/maintenance/domain/maintenance_notifier.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockMaintenanceRepository extends Mock implements MaintenanceRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

MaintenanceModel _fakeRecord({
  String id = 'rec-1',
  String status = 'pending',
  String itemId = 'item-1',
}) {
  return MaintenanceModel(
    id: id,
    itemId: itemId,
    tenantId: 'tenant-1',
    title: 'Oil Change',
    status: status,
    scheduledDate: '2025-06-01',
  );
}

ProviderContainer _makeContainer({required MockMaintenanceRepository repo}) {
  return ProviderContainer(
    overrides: [
      maintenanceRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockMaintenanceRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockMaintenanceRepository();
    container = _makeContainer(repo: mockRepo);
  });

  tearDown(() {
    container.dispose();
  });

  // =========================================================================
  // MaintenanceListNotifier
  // =========================================================================
  group('MaintenanceListNotifier', () {
    group('initial state', () {
      test('starts as AsyncData with empty list after build', () async {
        await container.read(maintenanceListNotifierProvider.future);
        final state = container.read(maintenanceListNotifierProvider);
        expect(state, isA<AsyncData<List<MaintenanceModel>>>());
        expect(state.value, isEmpty);
      });
    });

    group('load()', () {
      test('sets state to AsyncData with records on success', () async {
        final records = [_fakeRecord(id: 'r1'), _fakeRecord(id: 'r2')];
        when(
          () => mockRepo.getAll(
            status: any(named: 'status'),
            itemId: any(named: 'itemId'),
            upcoming: any(named: 'upcoming'),
            daysAhead: any(named: 'daysAhead'),
          ),
        ).thenAnswer((_) async => records);

        await container.read(maintenanceListNotifierProvider.future);
        await container.read(maintenanceListNotifierProvider.notifier).load();

        expect(container.read(maintenanceListNotifierProvider).value, records);
      });

      test('passes status and itemId filters', () async {
        when(
          () => mockRepo.getAll(
            status: 'pending',
            itemId: 'item-42',
            upcoming: false,
            daysAhead: 30,
          ),
        ).thenAnswer((_) async => []);

        await container
            .read(maintenanceListNotifierProvider.notifier)
            .load(status: 'pending', itemId: 'item-42');

        verify(
          () => mockRepo.getAll(
            status: 'pending',
            itemId: 'item-42',
            upcoming: false,
            daysAhead: 30,
          ),
        ).called(1);
      });

      test('passes upcoming and daysAhead flags', () async {
        when(
          () => mockRepo.getAll(
            status: null,
            itemId: null,
            upcoming: true,
            daysAhead: 14,
          ),
        ).thenAnswer((_) async => []);

        await container
            .read(maintenanceListNotifierProvider.notifier)
            .load(upcoming: true, daysAhead: 14);

        verify(
          () => mockRepo.getAll(
            status: null,
            itemId: null,
            upcoming: true,
            daysAhead: 14,
          ),
        ).called(1);
      });

      test('sets AsyncError when repository throws', () async {
        // Build succeeds (returns [] without calling repo)
        await container.read(maintenanceListNotifierProvider.future);

        // Now stub the repo to throw for the explicit load() call
        when(
          () => mockRepo.getAll(
            status: any(named: 'status'),
            itemId: any(named: 'itemId'),
            upcoming: any(named: 'upcoming'),
            daysAhead: any(named: 'daysAhead'),
          ),
        ).thenThrow(Exception('server error'));

        await container.read(maintenanceListNotifierProvider.notifier).load();

        expect(
          container.read(maintenanceListNotifierProvider),
          isA<AsyncError<List<MaintenanceModel>>>(),
        );
      });
    });

    group('complete()', () {
      test('replaces record with completed version in state', () async {
        final pending = _fakeRecord(id: 'r1', status: 'pending');
        final completed = _fakeRecord(id: 'r1', status: 'completed');

        when(
          () => mockRepo.getAll(
            status: any(named: 'status'),
            itemId: any(named: 'itemId'),
            upcoming: any(named: 'upcoming'),
            daysAhead: any(named: 'daysAhead'),
          ),
        ).thenAnswer((_) async => [pending]);
        when(() => mockRepo.complete('r1')).thenAnswer((_) async => completed);

        final notifier =
            container.read(maintenanceListNotifierProvider.notifier);
        await notifier.load();
        await notifier.complete('r1');

        final items =
            container.read(maintenanceListNotifierProvider).value!;
        expect(items.first.status, 'completed');
      });

      test('sets AsyncError when repository throws', () async {
        when(
          () => mockRepo.getAll(
            status: any(named: 'status'),
            itemId: any(named: 'itemId'),
            upcoming: any(named: 'upcoming'),
            daysAhead: any(named: 'daysAhead'),
          ),
        ).thenAnswer((_) async => [_fakeRecord()]);
        when(() => mockRepo.complete(any())).thenThrow(Exception('fail'));

        final notifier =
            container.read(maintenanceListNotifierProvider.notifier);
        await notifier.load();
        await notifier.complete('r1');

        expect(
          container.read(maintenanceListNotifierProvider),
          isA<AsyncError<List<MaintenanceModel>>>(),
        );
      });
    });

    group('cancel()', () {
      test('replaces record with cancelled version in state', () async {
        final pending = _fakeRecord(id: 'r1', status: 'pending');
        final cancelled = _fakeRecord(id: 'r1', status: 'cancelled');

        when(
          () => mockRepo.getAll(
            status: any(named: 'status'),
            itemId: any(named: 'itemId'),
            upcoming: any(named: 'upcoming'),
            daysAhead: any(named: 'daysAhead'),
          ),
        ).thenAnswer((_) async => [pending]);
        when(() => mockRepo.cancel('r1')).thenAnswer((_) async => cancelled);

        final notifier =
            container.read(maintenanceListNotifierProvider.notifier);
        await notifier.load();
        await notifier.cancel('r1');

        expect(
          container.read(maintenanceListNotifierProvider).value!.first.status,
          'cancelled',
        );
      });
    });

    group('delete()', () {
      test('removes the record from state', () async {
        final r1 = _fakeRecord(id: 'r1');
        final r2 = _fakeRecord(id: 'r2');

        when(
          () => mockRepo.getAll(
            status: any(named: 'status'),
            itemId: any(named: 'itemId'),
            upcoming: any(named: 'upcoming'),
            daysAhead: any(named: 'daysAhead'),
          ),
        ).thenAnswer((_) async => [r1, r2]);
        when(() => mockRepo.delete('r1')).thenAnswer((_) async {});

        final notifier =
            container.read(maintenanceListNotifierProvider.notifier);
        await notifier.load();
        await notifier.delete('r1');

        final items =
            container.read(maintenanceListNotifierProvider).value!;
        expect(items.length, 1);
        expect(items.first.id, 'r2');
      });
    });

    group('errorMessage()', () {
      test('extracts message from DioException response body', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/maintenance'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/maintenance'),
            statusCode: 422,
            data: {
              'error': {'message': 'Invalid date'},
            },
          ),
        );

        expect(MaintenanceListNotifier.errorMessage(error), 'Invalid date');
      });

      test('returns generic fallback for non-DioException', () {
        expect(
          MaintenanceListNotifier.errorMessage(Exception('boom')),
          'Something went wrong. Please try again.',
        );
      });
    });
  });

  // =========================================================================
  // ItemMaintenanceNotifier
  // =========================================================================
  group('ItemMaintenanceNotifier', () {
    group('build()', () {
      test('loads records for the given itemId', () async {
        final records = [_fakeRecord(id: 'r1', itemId: 'item-99')];
        when(() => mockRepo.getByItem('item-99'))
            .thenAnswer((_) async => records);

        final state = await container
            .read(itemMaintenanceNotifierProvider('item-99').future);

        expect(state, records);
      });
    });

    group('reload()', () {
      test('re-fetches records and updates state', () async {
        final initial = [_fakeRecord(id: 'r1', itemId: 'item-1')];
        when(() => mockRepo.getByItem('item-1'))
            .thenAnswer((_) async => initial);

        final freshContainer = _makeContainer(repo: mockRepo);
        addTearDown(freshContainer.dispose);

        await freshContainer
            .read(itemMaintenanceNotifierProvider('item-1').future);

        final updated = [
          _fakeRecord(id: 'r1', itemId: 'item-1'),
          _fakeRecord(id: 'r2', itemId: 'item-1'),
        ];
        when(() => mockRepo.getByItem('item-1'))
            .thenAnswer((_) async => updated);

        await freshContainer
            .read(itemMaintenanceNotifierProvider('item-1').notifier)
            .reload();

        expect(
          freshContainer
              .read(itemMaintenanceNotifierProvider('item-1'))
              .value,
          updated,
        );
      });
    });

    group('schedule()', () {
      test('prepends new record to the list on success', () async {
        when(() => mockRepo.getByItem('item-1')).thenAnswer((_) async => []);
        final newRecord = _fakeRecord(id: 'new-rec', itemId: 'item-1');
        when(
          () => mockRepo.schedule(
            itemId: 'item-1',
            title: any(named: 'title'),
            scheduledDate: any(named: 'scheduledDate'),
            description: any(named: 'description'),
            isRecurring: any(named: 'isRecurring'),
            recurrenceIntervalDays: any(named: 'recurrenceIntervalDays'),
            providerName: any(named: 'providerName'),
            providerContact: any(named: 'providerContact'),
            cost: any(named: 'cost'),
            currency: any(named: 'currency'),
            notes: any(named: 'notes'),
          ),
        ).thenAnswer((_) async => newRecord);

        final freshContainer = _makeContainer(repo: mockRepo);
        addTearDown(freshContainer.dispose);

        await freshContainer
            .read(itemMaintenanceNotifierProvider('item-1').future);

        await freshContainer
            .read(itemMaintenanceNotifierProvider('item-1').notifier)
            .schedule(
              title: 'Oil Change',
              scheduledDate: DateTime(2025, 6, 1),
            );

        final items = freshContainer
            .read(itemMaintenanceNotifierProvider('item-1'))
            .value!;
        expect(items.first.id, 'new-rec');
      });

      test('returns null and sets AsyncError on failure', () async {
        when(() => mockRepo.getByItem('item-1')).thenAnswer((_) async => []);
        when(
          () => mockRepo.schedule(
            itemId: any(named: 'itemId'),
            title: any(named: 'title'),
            scheduledDate: any(named: 'scheduledDate'),
            description: any(named: 'description'),
            isRecurring: any(named: 'isRecurring'),
            recurrenceIntervalDays: any(named: 'recurrenceIntervalDays'),
            providerName: any(named: 'providerName'),
            providerContact: any(named: 'providerContact'),
            cost: any(named: 'cost'),
            currency: any(named: 'currency'),
            notes: any(named: 'notes'),
          ),
        ).thenThrow(Exception('schedule failed'));

        final freshContainer = _makeContainer(repo: mockRepo);
        addTearDown(freshContainer.dispose);

        await freshContainer
            .read(itemMaintenanceNotifierProvider('item-1').future);

        final result = await freshContainer
            .read(itemMaintenanceNotifierProvider('item-1').notifier)
            .schedule(
              title: 'Oil Change',
              scheduledDate: DateTime(2025, 6, 1),
            );

        expect(result, isNull);
        expect(
          freshContainer.read(itemMaintenanceNotifierProvider('item-1')),
          isA<AsyncError<List<MaintenanceModel>>>(),
        );
      });
    });

    group('complete()', () {
      test('replaces record with completed version', () async {
        final pending = _fakeRecord(id: 'r1', itemId: 'item-1', status: 'pending');
        final completed = _fakeRecord(id: 'r1', itemId: 'item-1', status: 'completed');

        when(() => mockRepo.getByItem('item-1'))
            .thenAnswer((_) async => [pending]);
        when(() => mockRepo.complete('r1')).thenAnswer((_) async => completed);

        final freshContainer = _makeContainer(repo: mockRepo);
        addTearDown(freshContainer.dispose);

        await freshContainer
            .read(itemMaintenanceNotifierProvider('item-1').future);
        await freshContainer
            .read(itemMaintenanceNotifierProvider('item-1').notifier)
            .complete('r1');

        expect(
          freshContainer
              .read(itemMaintenanceNotifierProvider('item-1'))
              .value!
              .first
              .status,
          'completed',
        );
      });
    });

    group('delete()', () {
      test('removes the record from state', () async {
        final r1 = _fakeRecord(id: 'r1', itemId: 'item-1');
        final r2 = _fakeRecord(id: 'r2', itemId: 'item-1');

        when(() => mockRepo.getByItem('item-1'))
            .thenAnswer((_) async => [r1, r2]);
        when(() => mockRepo.delete('r1')).thenAnswer((_) async {});

        final freshContainer = _makeContainer(repo: mockRepo);
        addTearDown(freshContainer.dispose);

        await freshContainer
            .read(itemMaintenanceNotifierProvider('item-1').future);
        await freshContainer
            .read(itemMaintenanceNotifierProvider('item-1').notifier)
            .delete('r1');

        final items = freshContainer
            .read(itemMaintenanceNotifierProvider('item-1'))
            .value!;
        expect(items.length, 1);
        expect(items.first.id, 'r2');
      });
    });

    group('analyzeWithAi()', () {
      test('returns result map on success', () async {
        when(() => mockRepo.getByItem('item-1')).thenAnswer((_) async => []);
        when(() => mockRepo.analyzeWithAi('item-1'))
            .thenAnswer((_) async => {'recordCreated': false, 'risk': 'low'});

        final freshContainer = _makeContainer(repo: mockRepo);
        addTearDown(freshContainer.dispose);

        await freshContainer
            .read(itemMaintenanceNotifierProvider('item-1').future);

        final result = await freshContainer
            .read(itemMaintenanceNotifierProvider('item-1').notifier)
            .analyzeWithAi();

        expect(result, isNotNull);
        expect(result!['risk'], 'low');
      });

      test('reloads list when recordCreated is true', () async {
        final initial = <MaintenanceModel>[];
        final afterAi = [_fakeRecord(id: 'ai-rec', itemId: 'item-1')];

        when(() => mockRepo.getByItem('item-1'))
            .thenAnswer((_) async => initial);
        when(() => mockRepo.analyzeWithAi('item-1'))
            .thenAnswer((_) async => {'recordCreated': true});

        final freshContainer = _makeContainer(repo: mockRepo);
        addTearDown(freshContainer.dispose);

        await freshContainer
            .read(itemMaintenanceNotifierProvider('item-1').future);

        when(() => mockRepo.getByItem('item-1'))
            .thenAnswer((_) async => afterAi);

        await freshContainer
            .read(itemMaintenanceNotifierProvider('item-1').notifier)
            .analyzeWithAi();

        expect(
          freshContainer
              .read(itemMaintenanceNotifierProvider('item-1'))
              .value!
              .length,
          1,
        );
      });

      test('returns null on exception', () async {
        when(() => mockRepo.getByItem('item-1')).thenAnswer((_) async => []);
        when(() => mockRepo.analyzeWithAi('item-1'))
            .thenThrow(Exception('AI error'));

        final freshContainer = _makeContainer(repo: mockRepo);
        addTearDown(freshContainer.dispose);

        await freshContainer
            .read(itemMaintenanceNotifierProvider('item-1').future);

        final result = await freshContainer
            .read(itemMaintenanceNotifierProvider('item-1').notifier)
            .analyzeWithAi();

        expect(result, isNull);
      });
    });
  });
}
