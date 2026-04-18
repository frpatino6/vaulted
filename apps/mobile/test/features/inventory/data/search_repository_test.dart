import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/inventory/data/models/item_model.dart';
import 'package:vaulted/features/inventory/data/search_remote_data_source.dart';
import 'package:vaulted/features/inventory/data/search_repository.dart';

class MockSearchRemoteDataSource extends Mock implements SearchRemoteDataSource {}

void main() {
  late MockSearchRemoteDataSource mockRemote;
  late SearchRepository repository;

  setUp(() {
    mockRemote = MockSearchRemoteDataSource();
    repository = SearchRepository(mockRemote);
  });

  test('delegates search with filters', () async {
    final items = [
      const ItemModel(id: '1', name: 'A', category: 'art'),
    ];
    when(
      () => mockRemote.search(
        query: any(named: 'query'),
        category: any(named: 'category'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((_) async => items);

    final result = await repository.search(
      query: ' vase ',
      category: 'art',
      status: 'active',
    );

    expect(result, items);
    verify(
      () => mockRemote.search(
        query: ' vase ',
        category: 'art',
        status: 'active',
      ),
    ).called(1);
  });

  test('propagates errors', () async {
    when(
      () => mockRemote.search(
        query: any(named: 'query'),
        category: any(named: 'category'),
        status: any(named: 'status'),
      ),
    ).thenThrow(Exception('fail'));

    expect(
      () => repository.search(),
      throwsA(isA<Exception>()),
    );
  });
}
