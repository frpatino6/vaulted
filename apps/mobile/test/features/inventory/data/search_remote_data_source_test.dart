import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/inventory/data/search_remote_data_source.dart';

import '../../../support/dio_test_support.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late SearchRemoteDataSource dataSource;
  late RequestOptions requestOptions;

  setUp(() {
    mockDio = MockDio();
    dataSource = SearchRemoteDataSource(mockDio);
    requestOptions = RequestOptions(path: '/test');
  });

  test('sends trimmed query and optional filters', () async {
    when(
      () => mockDio.get<Map<String, dynamic>>(
        'items/search',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {
          'success': true,
          'data': {
            'items': [
              {
                'id': '1',
                'name': 'Chair',
                'category': 'furniture',
                'status': 'active',
              },
            ],
          },
        },
      ),
    );

    final items = await dataSource.search(
      query: '  chair ',
      category: 'furniture',
      status: 'active',
    );

    expect(items, hasLength(1));
    expect(items.single.name, 'Chair');

    final qp = verify(
      () => mockDio.get<Map<String, dynamic>>(
        'items/search',
        queryParameters: captureAny(named: 'queryParameters'),
      ),
    ).captured.single as Map<String, dynamic>;

    expect(qp['q'], 'chair');
    expect(qp['category'], 'furniture');
    expect(qp['status'], 'active');
  });

  test('omits blank query entirely', () async {
    when(
      () => mockDio.get<Map<String, dynamic>>(
        'items/search',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': true, 'data': <String, dynamic>{}},
      ),
    );

    await dataSource.search(query: '   ');

    final qp = verify(
      () => mockDio.get<Map<String, dynamic>>(
        'items/search',
        queryParameters: captureAny(named: 'queryParameters'),
      ),
    ).captured.single as Map<String, dynamic>;

    expect(qp.containsKey('q'), isFalse);
  });

  test('returns empty list when data map missing items key', () async {
    when(
      () => mockDio.get<Map<String, dynamic>>(
        'items/search',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': true, 'data': <String, dynamic>{}},
      ),
    );

    expect(await dataSource.search(), isEmpty);
  });

  test('returns empty list when data is not a map', () async {
    when(
      () => mockDio.get<Map<String, dynamic>>(
        'items/search',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': true, 'data': 'bad'},
      ),
    );

    expect(await dataSource.search(), isEmpty);
  });

  test('throws DioException on failure', () async {
    when(
      () => mockDio.get<Map<String, dynamic>>(
        'items/search',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': false, 'error': {'message': 'no'}},
      ),
    );

    expect(() => dataSource.search(), throwsA(isA<DioException>()));
  });

  test('joins validation error messages when error message is a list', () async {
    when(
      () => mockDio.get<Map<String, dynamic>>(
        'items/search',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {
          'success': false,
          'error': {
            'message': <String>['q is too short', 'category invalid'],
          },
        },
      ),
    );

    expect(
      () => dataSource.search(query: 'x'),
      throwsA(
        isA<DioException>().having(
          (e) => e.error,
          'error',
          'q is too short; category invalid',
        ),
      ),
    );
  });

  test('throws when response body is null', () async {
    when(
      () => mockDio.get<Map<String, dynamic>>(
        'items/search',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: requestOptions,
        data: null,
        statusCode: 200,
      ),
    );

    expect(() => dataSource.search(), throwsA(isA<DioException>()));
  });
}
