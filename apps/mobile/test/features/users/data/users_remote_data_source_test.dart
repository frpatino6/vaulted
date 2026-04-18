import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/users/data/users_remote_data_source.dart';

import '../../../support/dio_test_support.dart';

class MockDio extends Mock implements Dio {}

Map<String, dynamic> _userJson({String id = 'u1'}) => {
      'id': id,
      'email': 'owner@test.com',
      'role': 'owner',
      'isActive': true,
      'status': 'active',
      'mfaEnabled': true,
      'propertyIds': <String>[],
    };

void main() {
  late MockDio mockDio;
  late UsersRemoteDataSource dataSource;
  late RequestOptions requestOptions;

  setUp(() {
    mockDio = MockDio();
    dataSource = UsersRemoteDataSource(mockDio);
    requestOptions = RequestOptions(path: '/test');
  });

  test('getUsers parses list', () async {
    when(() => mockDio.get<Map<String, dynamic>>('users')).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': true, 'data': [_userJson()]},
      ),
    );

    final users = await dataSource.getUsers();

    expect(users, hasLength(1));
    expect(users.single.email, 'owner@test.com');
  });

  test('inviteUser POSTs body without expiresAt when null', () async {
    when(
      () => mockDio.post<Map<String, dynamic>>(
        'users/invite',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': true, 'data': _userJson()},
      ),
    );

    await dataSource.inviteUser(
      email: 'x@test.com',
      role: 'manager',
      propertyIds: const ['p1'],
    );

    final body = verify(
      () => mockDio.post<Map<String, dynamic>>(
        'users/invite',
        data: captureAny(named: 'data'),
      ),
    ).captured.single as Map<String, dynamic>;

    expect(body.containsKey('expiresAt'), isFalse);
  });

  test('updateUser builds partial body', () async {
    when(
      () => mockDio.put<Map<String, dynamic>>(
        'users/u1',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': true, 'data': _userJson()},
      ),
    );

    await dataSource.updateUser('u1', isActive: false);

    verify(
      () => mockDio.put<Map<String, dynamic>>(
        'users/u1',
        data: {'isActive': false},
      ),
    ).called(1);
  });

  test('deactivateUser DELETEs', () async {
    when(() => mockDio.delete<Map<String, dynamic>>('users/u1')).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': true, 'data': null},
      ),
    );

    await dataSource.deactivateUser('u1');

    verify(() => mockDio.delete<Map<String, dynamic>>('users/u1')).called(1);
  });

  test('throws when success without data', () async {
    when(() => mockDio.get<Map<String, dynamic>>('users')).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': true},
      ),
    );

    expect(
      () => dataSource.getUsers(),
      throwsA(isA<DioException>().having((e) => e.error, 'error', 'Unknown error')),
    );
  });
}
