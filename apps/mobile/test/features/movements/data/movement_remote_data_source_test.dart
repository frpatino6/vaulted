import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/movements/data/movement_remote_data_source.dart';

import '../../../support/dio_test_support.dart';

class MockDio extends Mock implements Dio {}

Map<String, dynamic> _movementJson({String id = 'mv1'}) => {
      'id': id,
      'tenantId': 'ten',
      'operationType': 'loan',
      'status': 'draft',
      'title': 'Move art',
      'createdBy': 'user-1',
      'items': <dynamic>[],
    };

void main() {
  late MockDio mockDio;
  late MovementRemoteDataSource dataSource;
  late RequestOptions requestOptions;

  setUp(() {
    mockDio = MockDio();
    dataSource = MovementRemoteDataSource(mockDio);
    requestOptions = RequestOptions(path: '/test');
  });

  test('createMovement posts minimal populated map', () async {
    when(
      () => mockDio.post<Map<String, dynamic>>(
        'movements',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': true, 'data': _movementJson()},
      ),
    );

    final movement = await dataSource.createMovement(
      operationType: 'loan',
      title: 'Move art',
    );

    expect(movement.id, 'mv1');

    final body = verify(
      () => mockDio.post<Map<String, dynamic>>(
        'movements',
        data: captureAny(named: 'data'),
      ),
    ).captured.single as Map<String, dynamic>;

    expect(body['operationType'], 'loan');
    expect(body['title'], 'Move art');
  });

  test('getMovements lists models', () async {
    when(
      () => mockDio.get<Map<String, dynamic>>(
        'movements',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': true, 'data': [_movementJson(id: 'a')]},
      ),
    );

    final list = await dataSource.getMovements(status: 'draft');

    expect(list, hasLength(1));
    final qp = verify(
      () => mockDio.get<Map<String, dynamic>>(
        'movements',
        queryParameters: captureAny(named: 'queryParameters'),
      ),
    ).captured.single as Map<String, dynamic>;
    expect(qp['status'], 'draft');
  });

  test('getActiveDrafts returns empty when data is null', () async {
    when(() => mockDio.get<Map<String, dynamic>>('movements/draft')).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': true, 'data': null},
      ),
    );

    expect(await dataSource.getActiveDrafts(), isEmpty);
  });

  test('throws DioException on error envelope', () async {
    when(() => mockDio.get<Map<String, dynamic>>('movements/m1')).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': false, 'error': {'message': 'missing'}},
      ),
    );

    expect(
      () => dataSource.getMovement('m1'),
      throwsA(isA<DioException>().having((e) => e.error, 'error', 'missing')),
    );
  });

  test('checkinItem posts itemId', () async {
    when(
      () => mockDio.post<Map<String, dynamic>>(
        'movements/m1/checkin',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': true, 'data': _movementJson()},
      ),
    );

    await dataSource.checkinItem('m1', 'item-9');

    verify(
      () => mockDio.post<Map<String, dynamic>>(
        'movements/m1/checkin',
        data: {'itemId': 'item-9'},
      ),
    ).called(1);
  });
}
