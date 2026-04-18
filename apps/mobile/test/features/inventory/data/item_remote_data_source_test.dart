import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/core/config/app_config.dart';
import 'package:vaulted/features/inventory/data/item_remote_data_source.dart';

import '../../../support/dio_test_support.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ItemRemoteDataSource dataSource;
  late RequestOptions requestOptions;

  setUp(() {
    mockDio = MockDio();
    dataSource = ItemRemoteDataSource(mockDio);
    requestOptions = RequestOptions(path: '/test');
  });

  test('getItems builds query parameters and normalizes _id', () async {
    when(
      () => mockDio.get<Map<String, dynamic>>(
        'items',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {
          'success': true,
          'data': [
            {
              '_id': 7,
              'name': 'Lamp',
              'category': 'furniture',
              'photos': <String>[],
            },
          ],
        },
      ),
    );

    final items = await dataSource.getItems(
      propertyId: 'p',
      unlocated: true,
      limit: 5,
    );

    expect(items.single.id, '7');

    final qp = verify(
      () => mockDio.get<Map<String, dynamic>>(
        'items',
        queryParameters: captureAny(named: 'queryParameters'),
      ),
    ).captured.single as Map<String, dynamic>;

    expect(qp['propertyId'], 'p');
    expect(qp['unlocated'], 'true');
    expect(qp['limit'], '5');
  });

  test('filters photos to same host as AppConfig or relative paths', () async {
    final apiHost = Uri.parse(AppConfig.apiBaseUrl).host;
    final sameHostUrl = '${Uri.parse(AppConfig.apiBaseUrl).scheme}://$apiHost/files/a.jpg';

    when(
      () => mockDio.get<Map<String, dynamic>>(
        'items/x',
      ),
    ).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {
          'success': true,
          'data': {
            'id': 'x',
            'name': 'Thing',
            'category': 'other',
            'photos': [
              '/relative-only.jpg',
              sameHostUrl,
              'https://evil.example.com/steal.jpg',
            ],
          },
        },
      ),
    );

    final item = await dataSource.getItem('x');

    expect(item.photos, ['/relative-only.jpg', sameHostUrl]);
  });

  test('createItem unwraps and normalizes', () async {
    when(
      () => mockDio.post<Map<String, dynamic>>(
        'items',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {
          'success': true,
          'data': {
            'id': 'n',
            'name': 'New',
            'category': 'books',
          },
        },
      ),
    );

    final item = await dataSource.createItem({
      'propertyId': 'p',
      'name': 'New',
      'category': 'books',
    });

    expect(item.id, 'n');
  });

  test('getItemHistory returns empty list when data is not a list', () async {
    when(
      () => mockDio.get<Map<String, dynamic>>('items/it/history'),
    ).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': true, 'data': <String, dynamic>{}},
      ),
    );

    expect(await dataSource.getItemHistory('it'), isEmpty);
  });

  test('throws DioException on error envelope', () async {
    when(() => mockDio.get<Map<String, dynamic>>('items')).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': false, 'error': {'message': 'bad'}},
      ),
    );

    expect(
      () => dataSource.getItems(),
      throwsA(isA<DioException>().having((e) => e.error, 'error', 'bad')),
    );
  });

  test('deleteItem calls DELETE', () async {
    when(() => mockDio.delete<Map<String, dynamic>>('items/1')).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': true, 'data': null},
      ),
    );

    await dataSource.deleteItem('1');

    verify(() => mockDio.delete<Map<String, dynamic>>('items/1')).called(1);
  });
}
