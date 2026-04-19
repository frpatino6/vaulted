import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/users/data/models/user_model.dart';
import 'package:vaulted/features/users/data/users_remote_data_source.dart';
import 'package:vaulted/features/users/data/users_repository.dart';

class MockUsersRemoteDataSource extends Mock implements UsersRemoteDataSource {}

void main() {
  late MockUsersRemoteDataSource mockRemote;
  late UsersRepository repository;

  setUp(() {
    mockRemote = MockUsersRemoteDataSource();
    repository = UsersRepository(mockRemote);
  });

  test('inviteUser forwards fields including optional expiresAt', () async {
    final user = UserModel(
      id: 'u1',
      email: 'a@b.com',
      role: 'manager',
      isActive: true,
      status: 'invited',
      mfaEnabled: false,
    );
    when(
      () => mockRemote.inviteUser(
        email: any(named: 'email'),
        role: any(named: 'role'),
        propertyIds: any(named: 'propertyIds'),
        expiresAt: any(named: 'expiresAt'),
      ),
    ).thenAnswer((_) async => user);

    final result = await repository.inviteUser(
      email: 'a@b.com',
      role: 'manager',
      propertyIds: const ['p1'],
      expiresAt: '2026-12-31',
    );

    expect(result, user);
    verify(
      () => mockRemote.inviteUser(
        email: 'a@b.com',
        role: 'manager',
        propertyIds: const ['p1'],
        expiresAt: '2026-12-31',
      ),
    ).called(1);
  });

  test('updateUser delegates', () async {
    final user = UserModel(
      id: 'u',
      email: 'e',
      role: 'staff',
      isActive: true,
      status: 'active',
      mfaEnabled: true,
    );
    when(
      () => mockRemote.updateUser(
        'u',
        role: any(named: 'role'),
        isActive: any(named: 'isActive'),
        propertyIds: any(named: 'propertyIds'),
      ),
    ).thenAnswer((_) async => user);

    await repository.updateUser('u', role: 'staff');

    verify(
      () => mockRemote.updateUser(
        'u',
        role: 'staff',
        isActive: null,
        propertyIds: null,
      ),
    ).called(1);
  });

  test('deactivateUser delegates', () async {
    when(() => mockRemote.deactivateUser('u')).thenAnswer((_) async {});

    await repository.deactivateUser('u');

    verify(() => mockRemote.deactivateUser('u')).called(1);
  });
}
