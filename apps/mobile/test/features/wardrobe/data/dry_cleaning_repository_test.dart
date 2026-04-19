import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/wardrobe/data/dry_cleaning_repository.dart';

import '../../../support/dio_test_support.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late DryCleaningRepository repository;
  late RequestOptions requestOptions;

  setUp(() {
    mockDio = MockDio();
    repository = DryCleaningRepository(mockDio);
    requestOptions = RequestOptions(path: '/test');
  });

  test('getHistory parses list and supports _id', () async {
    when(() => mockDio.get<Map<String, dynamic>>('wardrobe/dry-cleaning/it1'))
        .thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {
          'success': true,
          'data': [
            {
              '_id': 'dc1',
              'itemId': 'it1',
              'sentDate': '2026-01-01T00:00:00.000Z',
            },
          ],
        },
      ),
    );

    final rows = await repository.getHistory('it1');

    expect(rows, hasLength(1));
    expect(rows.single.id, 'dc1');
    verify(() => mockDio.get<Map<String, dynamic>>('wardrobe/dry-cleaning/it1'))
        .called(1);
  });

  test('getHistory returns empty when payload is not a list', () async {
    when(() => mockDio.get<Map<String, dynamic>>('wardrobe/dry-cleaning/it1'))
        .thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': true, 'data': <String, dynamic>{}},
      ),
    );

    expect(await repository.getHistory('it1'), isEmpty);
  });

  test('markReturned issues PUT', () async {
    when(
      () => mockDio.put<Map<String, dynamic>>(
        'wardrobe/dry-cleaning/dc9/return',
      ),
    ).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': true, 'data': null},
      ),
    );

    await repository.markReturned('dc9');

    verify(
      () => mockDio.put<Map<String, dynamic>>(
        'wardrobe/dry-cleaning/dc9/return',
      ),
    ).called(1);
  });

  test('throws on error envelope', () async {
    when(() => mockDio.get<Map<String, dynamic>>('wardrobe/dry-cleaning/it1'))
        .thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': false, 'error': {'message': 'nope'}},
      ),
    );

    expect(
      () => repository.getHistory('it1'),
      throwsA(isA<DioException>()),
    );
  });
}
