import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/wardrobe/data/dry_cleaning_model.dart';
import 'package:vaulted/features/wardrobe/data/dry_cleaning_repository.dart';
import 'package:vaulted/features/wardrobe/data/dry_cleaning_repository_provider.dart';
import 'package:vaulted/features/wardrobe/domain/dry_cleaning_notifier.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockDryCleaningRepository extends Mock implements DryCleaningRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

DryCleaningModel _fakeRecord({
  String id = 'dc-1',
  String itemId = 'item-1',
}) {
  return DryCleaningModel(
    id: id,
    itemId: itemId,
    sentDate: DateTime(2025, 1, 15),
  );
}

ProviderContainer _makeContainer({required MockDryCleaningRepository repo}) {
  return ProviderContainer(
    overrides: [
      dryCleaningRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockDryCleaningRepository mockRepo;

  setUp(() {
    mockRepo = MockDryCleaningRepository();
  });

  // -------------------------------------------------------------------------
  // Build / initial state
  // -------------------------------------------------------------------------
  group('DryCleaningNotifier — build', () {
    test('loads history for the given itemId during build', () async {
      final records = [_fakeRecord(id: 'dc1'), _fakeRecord(id: 'dc2')];
      when(() => mockRepo.getHistory('item-1'))
          .thenAnswer((_) async => records);

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      final state =
          await container.read(dryCleaningNotifierProvider('item-1').future);
      expect(state, records);
    });

    test('sets AsyncError when repository throws on build', () async {
      when(() => mockRepo.getHistory('item-1')).thenThrow(Exception('network'));

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(dryCleaningNotifierProvider('item-1').future),
        throwsA(isA<Exception>()),
      );
    });

    test('different itemIds produce isolated notifiers', () async {
      when(() => mockRepo.getHistory('item-1'))
          .thenAnswer((_) async => [_fakeRecord(id: 'dc1', itemId: 'item-1')]);
      when(() => mockRepo.getHistory('item-2'))
          .thenAnswer((_) async => [_fakeRecord(id: 'dc2', itemId: 'item-2')]);

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      final state1 =
          await container.read(dryCleaningNotifierProvider('item-1').future);
      final state2 =
          await container.read(dryCleaningNotifierProvider('item-2').future);

      expect(state1.first.id, 'dc1');
      expect(state2.first.id, 'dc2');
    });
  });

  // -------------------------------------------------------------------------
  // refresh()
  // -------------------------------------------------------------------------
  group('DryCleaningNotifier.refresh', () {
    test('re-fetches records and updates state', () async {
      when(() => mockRepo.getHistory('item-1'))
          .thenAnswer((_) async => [_fakeRecord(id: 'dc1')]);

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await container.read(dryCleaningNotifierProvider('item-1').future);

      final updated = [_fakeRecord(id: 'dc1'), _fakeRecord(id: 'dc2')];
      when(() => mockRepo.getHistory('item-1')).thenAnswer((_) async => updated);

      await container
          .read(dryCleaningNotifierProvider('item-1').notifier)
          .refresh();

      expect(
        container.read(dryCleaningNotifierProvider('item-1')).value,
        updated,
      );
    });

    test('transitions through AsyncLoading on refresh', () async {
      when(() => mockRepo.getHistory('item-1')).thenAnswer((_) async => []);

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await container.read(dryCleaningNotifierProvider('item-1').future);

      final states = <AsyncValue<List<DryCleaningModel>>>[];
      container.listen(
        dryCleaningNotifierProvider('item-1'),
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      when(() => mockRepo.getHistory('item-1')).thenAnswer((_) async => []);
      await container
          .read(dryCleaningNotifierProvider('item-1').notifier)
          .refresh();

      expect(states.first, isA<AsyncLoading<List<DryCleaningModel>>>());
    });
  });

  // -------------------------------------------------------------------------
  // markReturned()
  // -------------------------------------------------------------------------
  group('DryCleaningNotifier.markReturned', () {
    test('calls markReturned on repository and refreshes list', () async {
      final initial = [_fakeRecord(id: 'dc1'), _fakeRecord(id: 'dc2')];
      final afterReturn = [
        DryCleaningModel(
          id: 'dc1',
          itemId: 'item-1',
          sentDate: DateTime(2025, 1, 15),
          returnedDate: DateTime(2025, 1, 20),
        ),
        _fakeRecord(id: 'dc2'),
      ];

      when(() => mockRepo.getHistory('item-1')).thenAnswer((_) async => initial);
      when(() => mockRepo.markReturned('dc1')).thenAnswer((_) async {});

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await container.read(dryCleaningNotifierProvider('item-1').future);

      when(() => mockRepo.getHistory('item-1'))
          .thenAnswer((_) async => afterReturn);

      await container
          .read(dryCleaningNotifierProvider('item-1').notifier)
          .markReturned('dc1');

      verify(() => mockRepo.markReturned('dc1')).called(1);
      expect(
        container.read(dryCleaningNotifierProvider('item-1')).value!.first.returnedDate,
        isNotNull,
      );
    });

    test('propagates exception from repository', () async {
      when(() => mockRepo.getHistory('item-1'))
          .thenAnswer((_) async => [_fakeRecord()]);
      when(() => mockRepo.markReturned(any()))
          .thenThrow(Exception('mark returned failed'));

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await container.read(dryCleaningNotifierProvider('item-1').future);

      await expectLater(
        container
            .read(dryCleaningNotifierProvider('item-1').notifier)
            .markReturned('dc-1'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
