import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/inventory/data/item_repository.dart';
import 'package:vaulted/features/inventory/data/item_repository_provider.dart';
import 'package:vaulted/features/inventory/data/models/item_model.dart';
import 'package:vaulted/features/inventory/domain/item_detail_notifier.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockItemRepository extends Mock implements ItemRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ItemModel _fakeItem({String id = 'item-1', String name = 'Sofa'}) {
  return ItemModel(id: id, name: name, category: 'furniture');
}

ProviderContainer _makeContainer({required MockItemRepository repo}) {
  return ProviderContainer(
    overrides: [
      itemRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockItemRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockItemRepository();
    container = _makeContainer(repo: mockRepo);
  });

  tearDown(() {
    container.dispose();
  });

  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------
  group('ItemDetailNotifier — initial state', () {
    test('starts as AsyncData with null after build', () async {
      // Wait for the build() future to complete
      await container.read(itemDetailNotifierProvider.future);
      final state = container.read(itemDetailNotifierProvider);
      expect(state, isA<AsyncData<ItemModel?>>());
      expect(state.value, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // load()
  // -------------------------------------------------------------------------
  group('ItemDetailNotifier.load', () {
    test('sets state to AsyncData with item on success', () async {
      final item = _fakeItem();
      when(() => mockRepo.getItem('item-1')).thenAnswer((_) async => item);

      // Await the initial build first
      await container.read(itemDetailNotifierProvider.future);
      await container.read(itemDetailNotifierProvider.notifier).load('item-1');

      final state = container.read(itemDetailNotifierProvider);
      expect(state, isA<AsyncData<ItemModel?>>());
      expect(state.value, item);
    });

    test('returns the item on success', () async {
      final item = _fakeItem();
      when(() => mockRepo.getItem('item-1')).thenAnswer((_) async => item);

      await container.read(itemDetailNotifierProvider.future);
      final result = await container
          .read(itemDetailNotifierProvider.notifier)
          .load('item-1');

      expect(result, item);
    });

    test('sets state to AsyncError and rethrows on exception', () async {
      when(() => mockRepo.getItem(any())).thenThrow(Exception('not found'));

      await container.read(itemDetailNotifierProvider.future);

      await expectLater(
        container.read(itemDetailNotifierProvider.notifier).load('bad-id'),
        throwsA(isA<Exception>()),
      );

      final state = container.read(itemDetailNotifierProvider);
      expect(state, isA<AsyncError<ItemModel?>>());
    });

    test('transitions through AsyncLoading before settling', () async {
      final item = _fakeItem();
      when(() => mockRepo.getItem('item-1')).thenAnswer((_) async => item);

      // Wait for initial build
      await container.read(itemDetailNotifierProvider.future);

      final states = <AsyncValue<ItemModel?>>[];
      container.listen(
        itemDetailNotifierProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container.read(itemDetailNotifierProvider.notifier).load('item-1');

      expect(states.first, isA<AsyncLoading<ItemModel?>>());
      expect(states.last, isA<AsyncData<ItemModel?>>());
    });
  });

  // -------------------------------------------------------------------------
  // message()
  // -------------------------------------------------------------------------
  group('ItemDetailNotifier.message', () {
    test('extracts message from DioException body', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/items/x'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/items/x'),
          statusCode: 404,
          data: {
            'error': {'message': 'Item not found'},
          },
        ),
      );

      expect(ItemDetailNotifier.message(error), 'Item not found');
    });

    test('returns generic fallback for generic exception', () {
      expect(
        ItemDetailNotifier.message(Exception('fail')),
        'Something went wrong. Please try again.',
      );
    });

    test('returns generic fallback when DioException has empty response data', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/items/x'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/items/x'),
          statusCode: 500,
          data: <String, dynamic>{},
        ),
      );

      expect(
        ItemDetailNotifier.message(error),
        'Something went wrong. Please try again.',
      );
    });
  });
}
