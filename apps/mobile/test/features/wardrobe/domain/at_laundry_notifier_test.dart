import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/wardrobe/data/at_laundry_model.dart';
import 'package:vaulted/features/wardrobe/data/at_laundry_repository.dart';
import 'package:vaulted/features/wardrobe/domain/at_laundry_notifier.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockAtLaundryRepository extends Mock implements AtLaundryRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

AtLaundryData _fakeData() {
  return AtLaundryData(
    totalItems: 2,
    overdueItems: 1,
    overdueThresholdDays: 7,
    byProperty: [
      AtLaundryProperty(
        propertyId: 'prop-1',
        propertyName: 'Miami House',
        items: [
          AtLaundryItem(
            recordId: 'rec-1',
            itemId: 'item-1',
            itemName: 'Blue Shirt',
            sentDate: DateTime(2026, 1, 10),
            daysAtCleaner: 10,
            isOverdue: true,
          ),
          AtLaundryItem(
            recordId: 'rec-2',
            itemId: 'item-2',
            itemName: 'Black Suit',
            sentDate: DateTime(2026, 1, 15),
            daysAtCleaner: 5,
            isOverdue: false,
          ),
        ],
      ),
    ],
  );
}

ProviderContainer _makeContainer({required MockAtLaundryRepository repo}) {
  return ProviderContainer(
    overrides: [
      atLaundryRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockAtLaundryRepository mockRepo;

  setUp(() {
    mockRepo = MockAtLaundryRepository();
  });

  // -------------------------------------------------------------------------
  // Build / initial state
  // -------------------------------------------------------------------------
  group('AtLaundryNotifier — build', () {
    test('should_load_data_successfully_when_repository_returns_data', () async {
      final data = _fakeData();
      when(() => mockRepo.getAtLaundry()).thenAnswer((_) async => data);

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      final state = await container.read(atLaundryNotifierProvider.future);
      expect(state, data);
    });

    test('should_return_async_error_when_repository_throws_on_build', () async {
      when(() => mockRepo.getAtLaundry()).thenThrow(Exception('network'));

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(atLaundryNotifierProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // refresh()
  // -------------------------------------------------------------------------
  group('AtLaundryNotifier.refresh', () {
    test('should_reload_data_when_refresh_is_called', () async {
      when(() => mockRepo.getAtLaundry()).thenAnswer((_) async => _fakeData());

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await container.read(atLaundryNotifierProvider.future);

      final updated = _fakeData().copyWith(totalItems: 99);
      when(() => mockRepo.getAtLaundry()).thenAnswer((_) async => updated);

      await container.read(atLaundryNotifierProvider.notifier).refresh();

      expect(
        container.read(atLaundryNotifierProvider).value?.totalItems,
        99,
      );
    });

    test('should_transition_through_async_loading_when_refresh_is_called',
        () async {
      when(() => mockRepo.getAtLaundry()).thenAnswer((_) async => _fakeData());

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await container.read(atLaundryNotifierProvider.future);

      final states = <AsyncValue<AtLaundryData?>>[];
      container.listen(
        atLaundryNotifierProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      when(() => mockRepo.getAtLaundry()).thenAnswer((_) async => _fakeData());
      await container.read(atLaundryNotifierProvider.notifier).refresh();

      expect(states.first, isA<AsyncLoading<AtLaundryData?>>());
    });
  });
}
