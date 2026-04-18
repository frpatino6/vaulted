import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/dashboard/data/dashboard_remote_data_source.dart';

import '../../../support/dio_test_support.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late DashboardRemoteDataSource dataSource;
  late RequestOptions requestOptions;

  setUp(() {
    mockDio = MockDio();
    dataSource = DashboardRemoteDataSource(mockDio);
    requestOptions = RequestOptions(path: '/test');
  });

  test('unwraps data and parses DashboardModel', () async {
    when(() => mockDio.get<Map<String, dynamic>>('dashboard')).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {
          'success': true,
          'data': {
            'totalProperties': 1,
            'totalItems': 5,
            'itemsByStatus': {'active': 5},
            'itemsByCategory': {'art': 2},
            'totalValuation': 250000,
            'currency': 'USD',
          },
        },
      ),
    );

    final model = await dataSource.getDashboard();

    expect(model.totalProperties, 1);
    expect(model.totalItems, 5);
    expect(model.itemsByStatus['active'], 5);
    expect(model.totalValuation, 250000);
    verify(() => mockDio.get<Map<String, dynamic>>('dashboard')).called(1);
  });

  test('throws DioException when envelope reports failure', () async {
    when(() => mockDio.get<Map<String, dynamic>>('dashboard')).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {
          'success': false,
          'error': {'message': 'nope'},
        },
        statusCode: 403,
      ),
    );

    expect(
      () => dataSource.getDashboard(),
      throwsA(
        isA<DioException>().having(
          (e) => e.error,
          'error',
          'nope',
        ),
      ),
    );
  });

  test('throws DioException when response data is null', () async {
    when(() => mockDio.get<Map<String, dynamic>>('dashboard')).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: requestOptions,
        data: null,
        statusCode: 200,
      ),
    );

    expect(
      () => dataSource.getDashboard(),
      throwsA(isA<DioException>()),
    );
  });

  test('uses empty maps when inner data is not a Map', () async {
    when(() => mockDio.get<Map<String, dynamic>>('dashboard')).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': true, 'data': 'unexpected'},
      ),
    );

    final model = await dataSource.getDashboard();

    expect(model.itemsByStatus, isEmpty);
    expect(model.itemsByCategory, isEmpty);
  });
}
