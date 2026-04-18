import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/maintenance/data/maintenance_remote_data_source.dart';

import '../../../support/dio_test_support.dart';

class MockDio extends Mock implements Dio {}

Map<String, dynamic> _maintJson({String id = 'm1'}) => {
      'id': id,
      'itemId': 'item-1',
      'tenantId': 'ten',
      'title': 'Service',
      'scheduledDate': '2026-03-01T00:00:00.000Z',
      'status': 'pending',
    };

void main() {
  late MockDio mockDio;
  late MaintenanceRemoteDataSource dataSource;
  late RequestOptions requestOptions;

  setUp(() {
    mockDio = MockDio();
    dataSource = MaintenanceRemoteDataSource(mockDio);
    requestOptions = RequestOptions(path: '/test');
  });

  test('getAll passes query parameters', () async {
    when(
      () => mockDio.get<Map<String, dynamic>>(
        'maintenance',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': true, 'data': [_maintJson()]},
      ),
    );

    final list = await dataSource.getAll(
      status: 'pending',
      upcoming: true,
      daysAhead: 7,
    );

    expect(list, hasLength(1));
    final qp = verify(
      () => mockDio.get<Map<String, dynamic>>(
        'maintenance',
        queryParameters: captureAny(named: 'queryParameters'),
      ),
    ).captured.single as Map<String, dynamic>;
    expect(qp['status'], 'pending');
    expect(qp['upcoming'], 'true');
    expect(qp['daysAhead'], '7');
  });

  test('create POSTs to items/:id/maintenance', () async {
    when(
      () => mockDio.post<Map<String, dynamic>>(
        'items/it1/maintenance',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': true, 'data': _maintJson()},
      ),
    );

    final created = await dataSource.create('it1', {'title': 'A'});

    expect(created.id, 'm1');
    verify(
      () => mockDio.post<Map<String, dynamic>>(
        'items/it1/maintenance',
        data: {'title': 'A'},
      ),
    ).called(1);
  });

  test('delete uses void response type', () async {
    when(() => mockDio.delete<void>('maintenance/m1')).thenAnswer(
      (_) async => Response<void>(
        requestOptions: requestOptions,
        statusCode: 204,
      ),
    );

    await dataSource.delete('m1');

    verify(() => mockDio.delete<void>('maintenance/m1')).called(1);
  });

  test('analyzeWithAi returns map data', () async {
    when(
      () => mockDio.post<Map<String, dynamic>>('ai/maintenance/analyze/it1'),
    ).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': true, 'data': {'score': 0.5}},
      ),
    );

    final map = await dataSource.analyzeWithAi('it1');

    expect(map['score'], 0.5);
  });

  test('throws on failure envelope', () async {
    when(
      () => mockDio.get<Map<String, dynamic>>(
        'maintenance',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': false, 'error': {'message': 'no'}},
      ),
    );

    expect(() => dataSource.getAll(), throwsA(isA<DioException>()));
  });
}
