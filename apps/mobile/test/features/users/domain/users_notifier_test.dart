import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/users/data/models/user_model.dart';
import 'package:vaulted/features/users/data/users_repository.dart';
import 'package:vaulted/features/users/data/users_repository_provider.dart';
import 'package:vaulted/features/users/domain/users_notifier.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockUsersRepository extends Mock implements UsersRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

UserModel _fakeUser({
  String id = 'user-1',
  String email = 'owner@test.com',
  String role = 'owner',
}) {
  return UserModel(
    id: id,
    email: email,
    role: role,
    isActive: true,
    status: 'active',
    mfaEnabled: false,
  );
}

ProviderContainer _makeContainer({required MockUsersRepository repo}) {
  return ProviderContainer(
    overrides: [
      usersRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockUsersRepository mockRepo;

  setUp(() {
    mockRepo = MockUsersRepository();
  });

  // -------------------------------------------------------------------------
  // Build / initial state
  // -------------------------------------------------------------------------
  group('UsersNotifier — build', () {
    test('loads users from repository during build', () async {
      final users = [_fakeUser(id: 'u1'), _fakeUser(id: 'u2')];
      when(() => mockRepo.getUsers()).thenAnswer((_) async => users);

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      final state = await container.read(usersNotifierProvider.future);
      expect(state, users);
    });

    test('sets AsyncError when build throws', () async {
      when(() => mockRepo.getUsers()).thenThrow(Exception('server error'));

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(usersNotifierProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // refresh()
  // -------------------------------------------------------------------------
  group('UsersNotifier.refresh', () {
    test('reloads users and updates state', () async {
      final initial = [_fakeUser(id: 'u1')];
      when(() => mockRepo.getUsers()).thenAnswer((_) async => initial);

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await container.read(usersNotifierProvider.future);

      final updated = [_fakeUser(id: 'u1'), _fakeUser(id: 'u2')];
      when(() => mockRepo.getUsers()).thenAnswer((_) async => updated);

      await container.read(usersNotifierProvider.notifier).refresh();

      expect(container.read(usersNotifierProvider).value, updated);
    });

    test('transitions through AsyncLoading', () async {
      when(() => mockRepo.getUsers()).thenAnswer((_) async => []);

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await container.read(usersNotifierProvider.future);

      final states = <AsyncValue<List<UserModel>>>[];
      container.listen(
        usersNotifierProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      when(() => mockRepo.getUsers()).thenAnswer((_) async => []);
      await container.read(usersNotifierProvider.notifier).refresh();

      expect(states.any((s) => s is AsyncLoading), isTrue);
    });

    test('sets AsyncError when repository throws on refresh', () async {
      when(() => mockRepo.getUsers()).thenAnswer((_) async => []);

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await container.read(usersNotifierProvider.future);

      when(() => mockRepo.getUsers()).thenThrow(Exception('network error'));
      await container.read(usersNotifierProvider.notifier).refresh();

      expect(
        container.read(usersNotifierProvider),
        isA<AsyncError<List<UserModel>>>(),
      );
    });
  });

  // -------------------------------------------------------------------------
  // invite()
  // -------------------------------------------------------------------------
  group('UsersNotifier.invite', () {
    test('invites user and refreshes list', () async {
      final initialUsers = [_fakeUser(id: 'u1')];
      final invited = _fakeUser(id: 'u2', email: 'new@test.com', role: 'staff');
      final updatedUsers = [...initialUsers, invited];

      when(() => mockRepo.getUsers()).thenAnswer((_) async => initialUsers);
      when(
        () => mockRepo.inviteUser(
          email: 'new@test.com',
          role: 'staff',
          propertyIds: ['prop-1'],
          expiresAt: null,
        ),
      ).thenAnswer((_) async => invited);

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await container.read(usersNotifierProvider.future);

      when(() => mockRepo.getUsers()).thenAnswer((_) async => updatedUsers);

      await container.read(usersNotifierProvider.notifier).invite(
            email: 'new@test.com',
            role: 'staff',
            propertyIds: ['prop-1'],
          );

      expect(container.read(usersNotifierProvider).value!.length, 2);
    });

    test('propagates exception from repository', () async {
      when(() => mockRepo.getUsers()).thenAnswer((_) async => []);
      when(
        () => mockRepo.inviteUser(
          email: any(named: 'email'),
          role: any(named: 'role'),
          propertyIds: any(named: 'propertyIds'),
          expiresAt: any(named: 'expiresAt'),
        ),
      ).thenThrow(Exception('invite failed'));

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await container.read(usersNotifierProvider.future);

      await expectLater(
        container.read(usersNotifierProvider.notifier).invite(
              email: 'x@x.com',
              role: 'staff',
              propertyIds: [],
            ),
        throwsA(isA<Exception>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // updateUser()
  // -------------------------------------------------------------------------
  group('UsersNotifier.updateUser', () {
    test('updates user and refreshes list', () async {
      final user = _fakeUser(id: 'u1', role: 'staff');
      final updated = _fakeUser(id: 'u1', role: 'manager');

      when(() => mockRepo.getUsers()).thenAnswer((_) async => [user]);
      when(
        () => mockRepo.updateUser(
          'u1',
          role: 'manager',
          isActive: null,
          propertyIds: null,
        ),
      ).thenAnswer((_) async => updated);

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await container.read(usersNotifierProvider.future);

      when(() => mockRepo.getUsers()).thenAnswer((_) async => [updated]);

      await container
          .read(usersNotifierProvider.notifier)
          .updateUser('u1', role: 'manager');

      expect(container.read(usersNotifierProvider).value!.first.role, 'manager');
    });
  });

  // -------------------------------------------------------------------------
  // deactivateUser()
  // -------------------------------------------------------------------------
  group('UsersNotifier.deactivateUser', () {
    test('deactivates user and refreshes list', () async {
      final active = _fakeUser(id: 'u1');
      final deactivated = UserModel(
        id: 'u1',
        email: 'owner@test.com',
        role: 'owner',
        isActive: false,
        status: 'inactive',
        mfaEnabled: false,
      );

      when(() => mockRepo.getUsers()).thenAnswer((_) async => [active]);
      when(() => mockRepo.deactivateUser('u1')).thenAnswer((_) async {});

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await container.read(usersNotifierProvider.future);

      when(() => mockRepo.getUsers()).thenAnswer((_) async => [deactivated]);

      await container.read(usersNotifierProvider.notifier).deactivateUser('u1');

      expect(
        container.read(usersNotifierProvider).value!.first.isActive,
        isFalse,
      );
    });
  });

  // -------------------------------------------------------------------------
  // message()
  // -------------------------------------------------------------------------
  group('UsersNotifier.message', () {
    test('extracts message from DioException', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/users'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/users'),
          statusCode: 403,
          data: {
            'error': {'message': 'Access denied'},
          },
        ),
      );

      expect(UsersNotifier.message(error), 'Access denied');
    });

    test('returns toString for non-DioException', () {
      final error = Exception('something broke');
      expect(UsersNotifier.message(error), error.toString());
    });
  });
}
