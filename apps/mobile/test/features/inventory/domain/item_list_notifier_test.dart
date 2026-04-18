import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/inventory/data/item_repository.dart';
import 'package:vaulted/features/inventory/data/item_repository_provider.dart';
import 'package:vaulted/features/inventory/data/models/item_model.dart';
import 'package:vaulted/features/inventory/domain/item_list_notifier.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockItemRepository extends Mock implements ItemRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ItemModel _fakeItem({String id = 'item-1', String name = 'Test Item'}) {
  return ItemModel(
    id: id,
    name: name,
    category: 'furniture',
    propertyId: 'prop-1',
    roomId: 'room-1',
  );
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
  group('ItemListNotifier — initial state', () {
    test('starts as AsyncData with empty list after build', () async {
      await container.read(itemListNotifierProvider.future);
      final state = container.read(itemListNotifierProvider);
      expect(state, isA<AsyncData<List<ItemModel>>>());
      expect(state.value, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // load()
  // -------------------------------------------------------------------------
  group('ItemListNotifier.load', () {
    test('transitions to AsyncData with items on success', () async {
      final items = [_fakeItem(id: 'item-1'), _fakeItem(id: 'item-2')];
      when(
        () => mockRepo.getItems(
          propertyId: any(named: 'propertyId'),
          roomId: any(named: 'roomId'),
        ),
      ).thenAnswer((_) async => items);

      await container
          .read(itemListNotifierProvider.notifier)
          .load('prop-1', 'room-1');

      final state = container.read(itemListNotifierProvider);
      expect(state, isA<AsyncData<List<ItemModel>>>());
      expect(state.value, items);
    });

    test('transitions to AsyncError on exception', () async {
      when(
        () => mockRepo.getItems(
          propertyId: any(named: 'propertyId'),
          roomId: any(named: 'roomId'),
        ),
      ).thenThrow(Exception('network error'));

      await container
          .read(itemListNotifierProvider.notifier)
          .load('prop-1', 'room-1');

      final state = container.read(itemListNotifierProvider);
      expect(state, isA<AsyncError<List<ItemModel>>>());
    });

    test('passes propertyId and roomId to repository', () async {
      when(
        () => mockRepo.getItems(
          propertyId: 'prop-42',
          roomId: 'room-99',
        ),
      ).thenAnswer((_) async => []);

      await container
          .read(itemListNotifierProvider.notifier)
          .load('prop-42', 'room-99');

      verify(
        () => mockRepo.getItems(propertyId: 'prop-42', roomId: 'room-99'),
      ).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // refresh()
  // -------------------------------------------------------------------------
  group('ItemListNotifier.refresh', () {
    test('does nothing when load() has not been called yet', () async {
      await container.read(itemListNotifierProvider.notifier).refresh();

      verifyNever(
        () => mockRepo.getItems(
          propertyId: any(named: 'propertyId'),
          roomId: any(named: 'roomId'),
        ),
      );
    });

    test('re-fetches with the same propertyId and roomId after load()', () async {
      when(
        () => mockRepo.getItems(
          propertyId: 'prop-1',
          roomId: 'room-1',
        ),
      ).thenAnswer((_) async => [_fakeItem()]);

      final notifier = container.read(itemListNotifierProvider.notifier);
      await notifier.load('prop-1', 'room-1');
      await notifier.refresh();

      verify(
        () => mockRepo.getItems(propertyId: 'prop-1', roomId: 'room-1'),
      ).called(2);
    });

    test('updates state on refresh success', () async {
      final initial = [_fakeItem(id: 'item-1')];
      final updated = [_fakeItem(id: 'item-1'), _fakeItem(id: 'item-2')];

      when(
        () => mockRepo.getItems(
          propertyId: 'prop-1',
          roomId: 'room-1',
        ),
      ).thenAnswer((_) async => initial);

      final notifier = container.read(itemListNotifierProvider.notifier);
      await notifier.load('prop-1', 'room-1');

      when(
        () => mockRepo.getItems(
          propertyId: 'prop-1',
          roomId: 'room-1',
        ),
      ).thenAnswer((_) async => updated);

      await notifier.refresh();

      expect(container.read(itemListNotifierProvider).value, updated);
    });
  });

  // -------------------------------------------------------------------------
  // message()
  // -------------------------------------------------------------------------
  group('ItemListNotifier.message', () {
    test('returns error message from DioException response body', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/items'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/items'),
          statusCode: 422,
          data: {
            'error': {'message': 'Property not found'},
          },
        ),
      );

      expect(ItemListNotifier.message(error), 'Property not found');
    });

    test('returns generic fallback for non-DioException', () {
      expect(
        ItemListNotifier.message(Exception('boom')),
        'Something went wrong. Please try again.',
      );
    });

    test('returns generic fallback when response data has no message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/items'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/items'),
          statusCode: 500,
          data: <String, dynamic>{},
        ),
      );

      expect(
        ItemListNotifier.message(error),
        'Something went wrong. Please try again.',
      );
    });
  });
}
