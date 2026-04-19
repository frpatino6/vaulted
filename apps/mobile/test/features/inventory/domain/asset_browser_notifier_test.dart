import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/inventory/data/item_repository.dart';
import 'package:vaulted/features/inventory/data/item_repository_provider.dart';
import 'package:vaulted/features/inventory/data/models/item_model.dart';
import 'package:vaulted/features/inventory/data/search_repository.dart';
import 'package:vaulted/features/inventory/data/search_repository_provider.dart';
import 'package:vaulted/features/inventory/domain/asset_browser_notifier.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockItemRepository extends Mock implements ItemRepository {}

class MockSearchRepository extends Mock implements SearchRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ItemModel _fakeItem({
  String id = 'item-1',
  String name = 'Test Item',
  String? propertyId,
  String? roomId,
  int value = 100,
}) {
  return ItemModel(
    id: id,
    name: name,
    category: 'furniture',
    propertyId: propertyId,
    roomId: roomId,
    valuation: ItemValuationModel(currentValue: value),
  );
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
  late ProviderContainer container;

  setUp(() {
    mockItemRepo = MockItemRepository();
    mockSearchRepo = MockSearchRepository();
    container = _makeContainer(
      itemRepo: mockItemRepo,
      searchRepo: mockSearchRepo,
    );
  });

  tearDown(() {
    container.dispose();
  });

  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------
  group('AssetBrowserNotifier — initial state', () {
    test('starts as AsyncData with empty AssetBrowserState after build', () async {
      await container.read(assetBrowserNotifierProvider.future);
      final state = container.read(assetBrowserNotifierProvider);
      expect(state, isA<AsyncData<AssetBrowserState>>());
      expect(state.value!.items, isEmpty);
      expect(state.value!.query, '');
      expect(state.value!.isFiltered, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // loadInitial()
  // -------------------------------------------------------------------------
  group('AssetBrowserNotifier.loadInitial', () {
    test('loads recent items and stores them in state', () async {
      final items = [_fakeItem(id: 'item-1'), _fakeItem(id: 'item-2')];
      when(
        () => mockItemRepo.getItems(limit: 5),
      ).thenAnswer((_) async => items);

      await container.read(assetBrowserNotifierProvider.notifier).loadInitial();

      final state = container.read(assetBrowserNotifierProvider);
      expect(state.value!.items, items);
      expect(state.value!.isFiltered, isFalse);
    });

    test('sets AsyncError state when repository throws', () async {
      when(
        () => mockItemRepo.getItems(limit: any(named: 'limit')),
      ).thenThrow(Exception('network error'));

      await container.read(assetBrowserNotifierProvider.notifier).loadInitial();

      final state = container.read(assetBrowserNotifierProvider);
      expect(state, isA<AsyncError<AssetBrowserState>>());
    });
  });

  // -------------------------------------------------------------------------
  // applyFilters() — no query (browse mode)
  // -------------------------------------------------------------------------
  group('AssetBrowserNotifier.applyFilters — browse mode (no query)', () {
    test('fetches recent items when all filters are empty', () async {
      final items = [_fakeItem()];
      when(() => mockItemRepo.getItems(limit: 5)).thenAnswer((_) async => items);

      await container.read(assetBrowserNotifierProvider.notifier).applyFilters(
            query: '',
          );

      final state = container.read(assetBrowserNotifierProvider);
      expect(state.value!.items, items);
      expect(state.value!.isFiltered, isFalse);
    });

    test('fetches by filters without query using itemRepository', () async {
      final items = [_fakeItem(id: 'i1'), _fakeItem(id: 'i2')];
      when(
        () => mockItemRepo.getItems(
          propertyId: 'prop-1',
          category: 'furniture',
          status: 'active',
          unlocated: false,
        ),
      ).thenAnswer((_) async => items);

      await container.read(assetBrowserNotifierProvider.notifier).applyFilters(
            query: '',
            propertyId: 'prop-1',
            category: 'furniture',
            status: 'active',
          );

      final state = container.read(assetBrowserNotifierProvider);
      expect(state.value!.items, items);
      expect(state.value!.isFiltered, isTrue);
      expect(state.value!.propertyId, 'prop-1');
    });
  });

  // -------------------------------------------------------------------------
  // applyFilters() — with query (search mode)
  // -------------------------------------------------------------------------
  group('AssetBrowserNotifier.applyFilters — search mode (with query)', () {
    test('uses searchRepository when query is non-empty', () async {
      final results = [_fakeItem(id: 's1')];
      when(
        () => mockSearchRepo.search(
          query: 'sofa',
          category: null,
          status: null,
        ),
      ).thenAnswer((_) async => results);

      await container.read(assetBrowserNotifierProvider.notifier).applyFilters(
            query: 'sofa',
          );

      final state = container.read(assetBrowserNotifierProvider);
      expect(state.value!.items, results);
      expect(state.value!.query, 'sofa');
      expect(state.value!.isFiltered, isTrue);
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('filters search results client-side by propertyId', () async {
      final matching = _fakeItem(id: 'match', propertyId: 'prop-1');
      final nonMatching = _fakeItem(id: 'other', propertyId: 'prop-2');
      when(
        () => mockSearchRepo.search(query: 'chair', category: null, status: null),
      ).thenAnswer((_) async => [matching, nonMatching]);

      await container.read(assetBrowserNotifierProvider.notifier).applyFilters(
            query: 'chair',
            propertyId: 'prop-1',
          );

      final state = container.read(assetBrowserNotifierProvider);
      expect(state.value!.items, [matching]);
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('filters search results client-side by unlocated', () async {
      final locatedItem = _fakeItem(id: 'loc', roomId: 'room-1');
      final unlocatedItem = _fakeItem(id: 'unloc', roomId: null);
      when(
        () => mockSearchRepo.search(query: 'table', category: null, status: null),
      ).thenAnswer((_) async => [locatedItem, unlocatedItem]);

      await container.read(assetBrowserNotifierProvider.notifier).applyFilters(
            query: 'table',
            unlocated: true,
          );

      final state = container.read(assetBrowserNotifierProvider);
      expect(state.value!.items, [unlocatedItem]);
    }, timeout: const Timeout(Duration(seconds: 5)));
  });

  // -------------------------------------------------------------------------
  // Sort behaviour
  // -------------------------------------------------------------------------
  group('AssetBrowserNotifier — sort', () {
    test('sorts by value descending when sortBy = valueDesc', () async {
      final lowValue = _fakeItem(id: 'low', name: 'A', value: 100);
      final highValue = _fakeItem(id: 'high', name: 'B', value: 9999);
      when(() => mockItemRepo.getItems(limit: 5))
          .thenAnswer((_) async => [lowValue, highValue]);

      await container.read(assetBrowserNotifierProvider.notifier).applyFilters(
            query: '',
            sortBy: AssetSortBy.valueDesc,
          );

      final items = container.read(assetBrowserNotifierProvider).value!.items;
      expect(items.first.id, 'high');
      expect(items.last.id, 'low');
    });

    test('sorts by name ascending when sortBy = nameAsc', () async {
      final itemZ = _fakeItem(id: 'z', name: 'Zebra');
      final itemA = _fakeItem(id: 'a', name: 'Apple');
      when(() => mockItemRepo.getItems(limit: 5))
          .thenAnswer((_) async => [itemZ, itemA]);

      await container.read(assetBrowserNotifierProvider.notifier).applyFilters(
            query: '',
            sortBy: AssetSortBy.nameAsc,
          );

      final items = container.read(assetBrowserNotifierProvider).value!.items;
      expect(items.first.id, 'a');
      expect(items.last.id, 'z');
    });
  });

  // -------------------------------------------------------------------------
  // AssetBrowserState.isFiltered
  // -------------------------------------------------------------------------
  group('AssetBrowserState.isFiltered', () {
    test('is false for default state', () {
      expect(const AssetBrowserState().isFiltered, isFalse);
    });

    test('is true when query is non-empty', () {
      expect(const AssetBrowserState(query: 'test').isFiltered, isTrue);
    });

    test('is true when category is set', () {
      expect(const AssetBrowserState(category: 'furniture').isFiltered, isTrue);
    });

    test('is true when status is set', () {
      expect(const AssetBrowserState(status: 'active').isFiltered, isTrue);
    });

    test('is true when propertyId is set', () {
      expect(const AssetBrowserState(propertyId: 'p1').isFiltered, isTrue);
    });

    test('is true when unlocated is true', () {
      expect(const AssetBrowserState(unlocated: true).isFiltered, isTrue);
    });
  });
}
