import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/inventory/data/item_repository.dart';
import 'package:vaulted/features/inventory/data/item_repository_provider.dart';
import 'package:vaulted/features/inventory/data/models/item_model.dart';
import 'package:vaulted/features/inventory/data/search_repository.dart';
import 'package:vaulted/features/inventory/data/search_repository_provider.dart';
import 'package:vaulted/features/wardrobe/domain/wardrobe_notifier.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockItemRepository extends Mock implements ItemRepository {}

class MockSearchRepository extends Mock implements SearchRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ItemModel _fakeWardrobeItem({
  String id = 'w-item-1',
  String name = 'Blue Shirt',
  Map<String, dynamic>? attributes,
}) {
  return ItemModel(
    id: id,
    name: name,
    category: 'wardrobe',
    attributes: attributes,
  );
}

ItemModel _fakeFurnitureItem({String id = 'f-item-1'}) {
  return ItemModel(id: id, name: 'Sofa', category: 'furniture');
}

ProviderContainer _makeContainer({
  required MockItemRepository itemRepo,
  required MockSearchRepository searchRepo,
}) {
  return ProviderContainer(
    overrides: [
      itemRepositoryProvider.overrideWithValue(itemRepo),
      searchRepositoryProvider.overrideWithValue(searchRepo),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockItemRepository mockItemRepo;
  late MockSearchRepository mockSearchRepo;

  setUp(() {
    mockItemRepo = MockItemRepository();
    mockSearchRepo = MockSearchRepository();
  });

  // -------------------------------------------------------------------------
  // Build / initial state
  // -------------------------------------------------------------------------
  group('WardrobeNotifier — build', () {
    test('loads wardrobe items using searchRepository first', () async {
      final wardrobeItems = [_fakeWardrobeItem(id: 'w1')];
      when(
        () => mockSearchRepo.search(category: 'wardrobe'),
      ).thenAnswer((_) async => wardrobeItems);

      final container = _makeContainer(
        itemRepo: mockItemRepo,
        searchRepo: mockSearchRepo,
      );
      addTearDown(container.dispose);

      final state = await container.read(wardrobeNotifierProvider.future);

      expect(state, wardrobeItems);
      verifyNever(() => mockItemRepo.getItems(
            propertyId: any(named: 'propertyId'),
            roomId: any(named: 'roomId'),
          ));
    });

    test('falls back to itemRepository when search returns empty', () async {
      when(() => mockSearchRepo.search(category: 'wardrobe'))
          .thenAnswer((_) async => []);

      final allItems = [
        _fakeWardrobeItem(id: 'w1'),
        _fakeFurnitureItem(id: 'f1'),
      ];
      when(
        () => mockItemRepo.getItems(propertyId: '', roomId: ''),
      ).thenAnswer((_) async => allItems);

      final container = _makeContainer(
        itemRepo: mockItemRepo,
        searchRepo: mockSearchRepo,
      );
      addTearDown(container.dispose);

      final state = await container.read(wardrobeNotifierProvider.future);

      // Only wardrobe items should be returned (furniture filtered out)
      expect(state.length, 1);
      expect(state.first.id, 'w1');
    });

    test('filters out non-wardrobe items from search results', () async {
      final mixed = [
        _fakeWardrobeItem(id: 'w1'),
        _fakeFurnitureItem(id: 'f1'),
      ];
      when(() => mockSearchRepo.search(category: 'wardrobe'))
          .thenAnswer((_) async => mixed);

      final container = _makeContainer(
        itemRepo: mockItemRepo,
        searchRepo: mockSearchRepo,
      );
      addTearDown(container.dispose);

      final state = await container.read(wardrobeNotifierProvider.future);

      expect(state.length, 1);
      expect(state.first.category, 'wardrobe');
    });
  });

  // -------------------------------------------------------------------------
  // refresh()
  // -------------------------------------------------------------------------
  group('WardrobeNotifier.refresh', () {
    test('re-fetches items and updates state', () async {
      when(() => mockSearchRepo.search(category: 'wardrobe'))
          .thenAnswer((_) async => [_fakeWardrobeItem(id: 'w1')]);

      final container = _makeContainer(
        itemRepo: mockItemRepo,
        searchRepo: mockSearchRepo,
      );
      addTearDown(container.dispose);

      await container.read(wardrobeNotifierProvider.future);

      when(() => mockSearchRepo.search(category: 'wardrobe')).thenAnswer(
        (_) async => [_fakeWardrobeItem(id: 'w1'), _fakeWardrobeItem(id: 'w2')],
      );

      await container.read(wardrobeNotifierProvider.notifier).refresh();

      expect(container.read(wardrobeNotifierProvider).value!.length, 2);
    });

    test('transitions through AsyncLoading on refresh', () async {
      when(() => mockSearchRepo.search(category: 'wardrobe'))
          .thenAnswer((_) async => [_fakeWardrobeItem()]);
      when(() => mockItemRepo.getItems(propertyId: '', roomId: ''))
          .thenAnswer((_) async => []);

      final container = _makeContainer(
        itemRepo: mockItemRepo,
        searchRepo: mockSearchRepo,
      );
      addTearDown(container.dispose);

      await container.read(wardrobeNotifierProvider.future);

      final states = <AsyncValue<List<ItemModel>>>[];
      container.listen(
        wardrobeNotifierProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      when(() => mockSearchRepo.search(category: 'wardrobe'))
          .thenAnswer((_) async => [_fakeWardrobeItem()]);

      await container.read(wardrobeNotifierProvider.notifier).refresh();

      expect(states.first, isA<AsyncLoading<List<ItemModel>>>());
    });
  });

  // -------------------------------------------------------------------------
  // updateCleaningStatus()
  // -------------------------------------------------------------------------
  group('WardrobeNotifier.updateCleaningStatus', () {
    test('optimistically updates cleaning status then confirms with server', () async {
      final item = _fakeWardrobeItem(
        id: 'w1',
        attributes: {'cleaningStatus': 'clean'},
      );
      final updatedItem = _fakeWardrobeItem(
        id: 'w1',
        attributes: {'cleaningStatus': 'needs_cleaning'},
      );

      // Initial load returns item with 'clean' status
      when(() => mockSearchRepo.search(category: 'wardrobe'))
          .thenAnswer((_) async => [item]);
      when(
        () => mockItemRepo.updateItem(
          'w1',
          attributes: {'cleaningStatus': 'needs_cleaning'},
        ),
      ).thenAnswer((_) async => updatedItem);

      final container = _makeContainer(
        itemRepo: mockItemRepo,
        searchRepo: mockSearchRepo,
      );
      addTearDown(container.dispose);

      await container.read(wardrobeNotifierProvider.future);

      // After update, _refreshSilently() will call searchRepo again
      when(() => mockSearchRepo.search(category: 'wardrobe'))
          .thenAnswer((_) async => [updatedItem]);

      await container
          .read(wardrobeNotifierProvider.notifier)
          .updateCleaningStatus(
            item: item,
            cleaningStatus: 'needs_cleaning',
          );

      final current = container.read(wardrobeNotifierProvider).value!;
      expect(
        current.first.attributes!['cleaningStatus'],
        'needs_cleaning',
      );
    });

    test('reverts optimistic update on server failure', () async {
      final item = _fakeWardrobeItem(
        id: 'w1',
        attributes: {'cleaningStatus': 'clean'},
      );

      when(() => mockSearchRepo.search(category: 'wardrobe'))
          .thenAnswer((_) async => [item]);
      when(
        () => mockItemRepo.updateItem(
          'w1',
          attributes: any(named: 'attributes'),
        ),
      ).thenThrow(Exception('server error'));

      final container = _makeContainer(
        itemRepo: mockItemRepo,
        searchRepo: mockSearchRepo,
      );
      addTearDown(container.dispose);

      await container.read(wardrobeNotifierProvider.future);

      await expectLater(
        container.read(wardrobeNotifierProvider.notifier).updateCleaningStatus(
              item: item,
              cleaningStatus: 'at_dry_cleaner',
            ),
        throwsA(isA<Exception>()),
      );

      // Should revert to original
      final current = container.read(wardrobeNotifierProvider).value!;
      expect(current.first.attributes!['cleaningStatus'], 'clean');
    });

    test('handles null initial state by reloading', () async {
      when(() => mockSearchRepo.search(category: 'wardrobe'))
          .thenAnswer((_) async => [_fakeWardrobeItem(id: 'w1')]);

      final container = _makeContainer(
        itemRepo: mockItemRepo,
        searchRepo: mockSearchRepo,
      );
      addTearDown(container.dispose);

      // Don't wait for build — state is null initially
      final notifier = container.read(wardrobeNotifierProvider.notifier);

      // Force state to null to simulate the null branch
      // The notifier handles null state by reloading
      await notifier.updateCleaningStatus(
        item: _fakeWardrobeItem(id: 'w1'),
        cleaningStatus: 'needs_cleaning',
      );

      // Should have loaded items from the search
      final current = container.read(wardrobeNotifierProvider).value;
      expect(current, isNotNull);
    });
  });
}
