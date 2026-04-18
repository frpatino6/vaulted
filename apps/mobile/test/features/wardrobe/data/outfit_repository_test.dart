import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/wardrobe/data/outfit_repository.dart';

import '../../../support/dio_test_support.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late OutfitRepository repository;
  late RequestOptions requestOptions;

  setUp(() {
    mockDio = MockDio();
    repository = OutfitRepository(mockDio);
    requestOptions = RequestOptions(path: '/test');
  });

  test('getOutfits parses list', () async {
    when(() => mockDio.get<Map<String, dynamic>>('wardrobe/outfits')).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {
          'success': true,
          'data': [
            {
              'id': 'o1',
              'name': 'Gala',
              'itemIds': <String>[],
              'photos': <String>[],
              'items': <dynamic>[],
            },
          ],
        },
      ),
    );

    final outfits = await repository.getOutfits();

    expect(outfits, hasLength(1));
    expect(outfits.single.name, 'Gala');
  });

  test('createOutfit POSTs payload', () async {
    when(
      () => mockDio.post<Map<String, dynamic>>(
        'wardrobe/outfits',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {
          'success': true,
          'data': {
            'id': 'o2',
            'name': 'Brunch',
            'itemIds': <String>['i1'],
            'photos': <String>[],
            'items': <dynamic>[],
          },
        },
      ),
    );

    final created = await repository.createOutfit({
      'name': 'Brunch',
      'itemIds': ['i1'],
    });

    expect(created.id, 'o2');
    verify(
      () => mockDio.post<Map<String, dynamic>>(
        'wardrobe/outfits',
        data: {'name': 'Brunch', 'itemIds': ['i1']},
      ),
    ).called(1);
  });

  test('deleteOutfit issues DELETE', () async {
    when(() => mockDio.delete<Map<String, dynamic>>('wardrobe/outfits/o1'))
        .thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': true, 'data': null},
      ),
    );

    await repository.deleteOutfit('o1');

    verify(() => mockDio.delete<Map<String, dynamic>>('wardrobe/outfits/o1'))
        .called(1);
  });

  test('throws when envelope invalid', () async {
    when(() => mockDio.get<Map<String, dynamic>>('wardrobe/outfits/o1'))
        .thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': false, 'error': {'message': 'missing'}},
      ),
    );

    expect(
      () => repository.getOutfitById('o1'),
      throwsA(isA<DioException>()),
    );
  });
}
