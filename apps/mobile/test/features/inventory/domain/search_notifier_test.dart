import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/inventory/data/models/item_model.dart';
import 'package:vaulted/features/inventory/data/search_repository.dart';
import 'package:vaulted/features/inventory/data/search_repository_provider.dart';
import 'package:vaulted/features/inventory/domain/search_notifier.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSearchRepository extends Mock implements SearchRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ItemModel _fakeItem({String id = 'item-1', String name = 'Sofa'}) {
  return ItemModel(id: id, name: name, category: 'furniture');
}

ProviderContainer _makeContainer({required MockSearchRepository repo}) {
  return ProviderContainer(
    overrides: [
      searchRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockSearchRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockSearchRepository();
    container = _makeContainer(repo: mockRepo);
  });

  tearDown(() {
    container.dispose();
  });

  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------
  group('SearchNotifier — initial state', () {
    test('starts as AsyncData with empty list after build', () async {
      await container.read(searchNotifierProvider.future);
      final state = container.read(searchNotifierProvider);
      expect(state, isA<AsyncData<List<ItemModel>>>());
      expect(state.value, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // search()
  // -------------------------------------------------------------------------
  group('SearchNotifier.search', () {
    test('sets state to AsyncData([]) immediately when query is blank', () async {
      final notifier = container.read(searchNotifierProvider.notifier);
      await notifier.search('');

      final state = container.read(searchNotifierProvider);
      expect(state.value, isEmpty);
      verifyNever(() => mockRepo.search(query: any(named: 'query')));
    });

    test('sets state to AsyncData([]) for whitespace-only query', () async {
      await container.read(searchNotifierProvider.notifier).search('   ');

      final state = container.read(searchNotifierProvider);
      expect(state.value, isEmpty);
    });

    test('returns results after debounce on non-empty query', () async {
      final results = [_fakeItem(id: 'item-1')];
      when(
        () => mockRepo.search(query: 'sofa'),
      ).thenAnswer((_) async => results);

      await container.read(searchNotifierProvider.notifier).search('sofa');

      final state = container.read(searchNotifierProvider);
      expect(state, isA<AsyncData<List<ItemModel>>>());
      expect(state.value, results);
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('passes category and status filters to repository', () async {
      when(
        () => mockRepo.search(
          query: 'chair',
          category: 'furniture',
          status: 'active',
        ),
      ).thenAnswer((_) async => []);

      await container
          .read(searchNotifierProvider.notifier)
          .search('chair', category: 'furniture', status: 'active');

      verify(
        () => mockRepo.search(
          query: 'chair',
          category: 'furniture',
          status: 'active',
        ),
      ).called(1);
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('transitions to AsyncError when repository throws', () async {
      when(() => mockRepo.search(query: any(named: 'query')))
          .thenThrow(Exception('search failed'));

      await container.read(searchNotifierProvider.notifier).search('table');

      final state = container.read(searchNotifierProvider);
      expect(state, isA<AsyncError<List<ItemModel>>>());
    }, timeout: const Timeout(Duration(seconds: 5)));
  });

  // -------------------------------------------------------------------------
  // clear()
  // -------------------------------------------------------------------------
  group('SearchNotifier.clear', () {
    test('resets state to empty AsyncData immediately', () async {
      final results = [_fakeItem()];
      when(() => mockRepo.search(query: any(named: 'query')))
          .thenAnswer((_) async => results);

      final notifier = container.read(searchNotifierProvider.notifier);
      await notifier.search('sofa');

      notifier.clear();

      final state = container.read(searchNotifierProvider);
      expect(state.value, isEmpty);
    }, timeout: const Timeout(Duration(seconds: 5)));
  });

  // -------------------------------------------------------------------------
  // message()
  // -------------------------------------------------------------------------
  group('SearchNotifier.message', () {
    test('extracts error string from DioException.error', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/search'),
        error: 'Custom error string',
      );

      expect(SearchNotifier.message(error), 'Custom error string');
    });

    test('extracts message from response body', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/search'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/search'),
          statusCode: 422,
          data: {
            'error': {'message': 'Invalid query'},
          },
        ),
      );

      expect(SearchNotifier.message(error), 'Invalid query');
    });

    test('returns generic fallback for non-DioException', () {
      expect(
        SearchNotifier.message(Exception('unknown')),
        'Something went wrong. Please try again.',
      );
    });
  });
}
