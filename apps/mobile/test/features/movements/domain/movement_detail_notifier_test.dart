import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/movements/data/models/movement_model.dart';
import 'package:vaulted/features/movements/data/movement_repository.dart';
import 'package:vaulted/features/movements/data/movement_repository_provider.dart';
import 'package:vaulted/features/movements/domain/movement_detail_notifier.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockMovementRepository extends Mock implements MovementRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

MovementModel _fakeMovement({
  String id = 'mov-1',
  String status = 'draft',
}) {
  return MovementModel(
    id: id,
    tenantId: 'tenant-1',
    operationType: 'move',
    status: status,
    title: 'Test Movement',
    createdBy: 'user-1',
  );
}

ProviderContainer _makeContainer({required MockMovementRepository repo}) {
  return ProviderContainer(
    overrides: [
      movementRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockMovementRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockMovementRepository();
    container = _makeContainer(repo: mockRepo);
  });

  tearDown(() {
    container.dispose();
  });

  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------
  group('MovementDetailNotifier — initial state', () {
    test('starts as AsyncData with null after build', () async {
      await container.read(movementDetailNotifierProvider.future);
      final state = container.read(movementDetailNotifierProvider);
      expect(state, isA<AsyncData<MovementModel?>>());
      expect(state.value, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // load()
  // -------------------------------------------------------------------------
  group('MovementDetailNotifier.load', () {
    test('sets state to AsyncData with movement on success', () async {
      final movement = _fakeMovement();
      when(() => mockRepo.getMovement('mov-1')).thenAnswer((_) async => movement);

      await container.read(movementDetailNotifierProvider.future);
      await container.read(movementDetailNotifierProvider.notifier).load('mov-1');

      expect(container.read(movementDetailNotifierProvider).value, movement);
    });

    test('sets AsyncError on exception', () async {
      when(() => mockRepo.getMovement(any())).thenThrow(Exception('not found'));

      await container.read(movementDetailNotifierProvider.future);
      await container.read(movementDetailNotifierProvider.notifier).load('bad');

      expect(
        container.read(movementDetailNotifierProvider),
        isA<AsyncError<MovementModel?>>(),
      );
    });

    test('transitions through AsyncLoading', () async {
      when(() => mockRepo.getMovement('mov-1'))
          .thenAnswer((_) async => _fakeMovement());

      await container.read(movementDetailNotifierProvider.future);

      final states = <AsyncValue<MovementModel?>>[];
      container.listen(
        movementDetailNotifierProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container.read(movementDetailNotifierProvider.notifier).load('mov-1');

      expect(states.first, isA<AsyncLoading<MovementModel?>>());
    });
  });

  // -------------------------------------------------------------------------
  // checkin()
  // -------------------------------------------------------------------------
  group('MovementDetailNotifier.checkin', () {
    test('does nothing when _id is null (load not called)', () async {
      await container.read(movementDetailNotifierProvider.future);
      await container.read(movementDetailNotifierProvider.notifier).checkin('item-1');

      verifyNever(() => mockRepo.checkinItem(any(), any()));
    });

    test('updates state with returned movement', () async {
      final initial = _fakeMovement(status: 'active');
      final updated = _fakeMovement(status: 'active');

      when(() => mockRepo.getMovement('mov-1')).thenAnswer((_) async => initial);
      when(() => mockRepo.checkinItem('mov-1', 'item-1'))
          .thenAnswer((_) async => updated);

      final notifier = container.read(movementDetailNotifierProvider.notifier);
      await notifier.load('mov-1');
      await notifier.checkin('item-1');

      expect(container.read(movementDetailNotifierProvider).value, updated);
    });
  });

  // -------------------------------------------------------------------------
  // complete()
  // -------------------------------------------------------------------------
  group('MovementDetailNotifier.complete', () {
    test('does nothing when _id is null', () async {
      await container.read(movementDetailNotifierProvider.future);
      await container.read(movementDetailNotifierProvider.notifier).complete();

      verifyNever(() => mockRepo.complete(any()));
    });

    test('updates state with completed movement', () async {
      final initial = _fakeMovement(status: 'active');
      final completed = _fakeMovement(status: 'completed');

      when(() => mockRepo.getMovement('mov-1')).thenAnswer((_) async => initial);
      when(() => mockRepo.complete('mov-1')).thenAnswer((_) async => completed);

      final notifier = container.read(movementDetailNotifierProvider.notifier);
      await notifier.load('mov-1');
      await notifier.complete();

      expect(
        container.read(movementDetailNotifierProvider).value!.status,
        'completed',
      );
    });
  });

  // -------------------------------------------------------------------------
  // cancel()
  // -------------------------------------------------------------------------
  group('MovementDetailNotifier.cancel', () {
    test('does nothing when _id is null', () async {
      await container.read(movementDetailNotifierProvider.future);
      await container.read(movementDetailNotifierProvider.notifier).cancel();

      verifyNever(() => mockRepo.cancel(any()));
    });

    test('sets state to AsyncData(null) after cancellation', () async {
      when(() => mockRepo.getMovement('mov-1'))
          .thenAnswer((_) async => _fakeMovement());
      when(() => mockRepo.cancel('mov-1')).thenAnswer((_) async => _fakeMovement(status: 'cancelled'));

      final notifier = container.read(movementDetailNotifierProvider.notifier);
      await notifier.load('mov-1');
      await notifier.cancel();

      expect(container.read(movementDetailNotifierProvider).value, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // message()
  // -------------------------------------------------------------------------
  group('MovementDetailNotifier.message', () {
    test('extracts message from DioException response body', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/movements/x'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/movements/x'),
          statusCode: 409,
          data: {
            'error': {'message': 'Movement already completed'},
          },
        ),
      );

      expect(MovementDetailNotifier.message(error), 'Movement already completed');
    });

    test('returns generic fallback for non-DioException', () {
      expect(
        MovementDetailNotifier.message(Exception('fail')),
        'Something went wrong. Please try again.',
      );
    });
  });
}
