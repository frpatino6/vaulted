import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/properties/data/property_remote_data_source.dart';

import '../../../support/dio_test_support.dart';

class MockDio extends Mock implements Dio {}

Map<String, dynamic> _propertyJson({String id = 'prop-1'}) => {
      'id': id,
      'tenantId': 'ten',
      'name': 'Estate',
      'type': 'residence',
      'address': {
        'street': '1',
        'city': 'Aspen',
        'state': 'CO',
        'zip': '81611',
        'country': 'USA',
      },
      'floors': <dynamic>[],
      'photos': <dynamic>[],
    };

void main() {
  late MockDio mockDio;
  late PropertyRemoteDataSource dataSource;
  late RequestOptions requestOptions;

  setUp(() {
    mockDio = MockDio();
    dataSource = PropertyRemoteDataSource(mockDio);
    requestOptions = RequestOptions(path: '/test');
  });

  test('getProperties parses list', () async {
    when(() => mockDio.get<Map<String, dynamic>>('properties')).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': true, 'data': [_propertyJson(id: 'a')]},
      ),
    );

    final list = await dataSource.getProperties();

    expect(list, hasLength(1));
    expect(list.single.name, 'Estate');
  });

  test('addRoom posts name and type', () async {
    when(
      () => mockDio.post<Map<String, dynamic>>(
        'properties/p1/floors/f1/rooms',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': true, 'data': _propertyJson()},
      ),
    );

    await dataSource.addRoom('p1', 'f1', 'Library', 'library');

    verify(
      () => mockDio.post<Map<String, dynamic>>(
        'properties/p1/floors/f1/rooms',
        data: {'name': 'Library', 'type': 'library'},
      ),
    ).called(1);
  });

  test('throws DioException on failure', () async {
    when(() => mockDio.get<Map<String, dynamic>>('properties/p')).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': false, 'error': {'message': 'gone'}},
      ),
    );

    expect(
      () => dataSource.getProperty('p'),
      throwsA(isA<DioException>().having((e) => e.error, 'error', 'gone')),
    );
  });

  test('deleteProperty issues DELETE', () async {
    when(() => mockDio.delete<Map<String, dynamic>>('properties/p1'))
        .thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': true, 'data': null},
      ),
    );

    await dataSource.deleteProperty('p1');

    verify(() => mockDio.delete<Map<String, dynamic>>('properties/p1')).called(1);
  });
}
