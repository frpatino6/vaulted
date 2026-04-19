import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/movements/data/models/movement_model.dart';
import 'package:vaulted/features/movements/data/movement_repository.dart';
import 'package:vaulted/features/movements/data/movement_repository_provider.dart';
import 'package:vaulted/features/movements/domain/movement_list_notifier.dart';

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
  group('MovementListNotifier — initial state', () {
    test('starts as AsyncData with empty list after build', () async {
      await container.read(movementListNotifierProvider.future);
      final state = container.read(movementListNotifierProvider);
      expect(state, isA<AsyncData<List<MovementModel>>>());
      expect(state.value, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // load()
  // -------------------------------------------------------------------------
  group('MovementListNotifier.load', () {
    test('sets state to AsyncData with movements on success', () async {
      final movements = [_fakeMovement(id: 'm1'), _fakeMovement(id: 'm2')];
      when(() => mockRepo.getMovements(status: null))
          .thenAnswer((_) async => movements);

      await container.read(movementListNotifierProvider.future);
      await container.read(movementListNotifierProvider.notifier).load();

      expect(container.read(movementListNotifierProvider).value, movements);
    });

    test('passes status filter to repository', () async {
      when(() => mockRepo.getMovements(status: 'active'))
          .thenAnswer((_) async => []);

      await container.read(movementListNotifierProvider.future);
      await container
          .read(movementListNotifierProvider.notifier)
          .load(status: 'active');

      verify(() => mockRepo.getMovements(status: 'active')).called(1);
    });

    test('transitions through AsyncLoading', () async {
      when(() => mockRepo.getMovements(status: null)).thenAnswer((_) async => []);

      await container.read(movementListNotifierProvider.future);

      final states = <AsyncValue<List<MovementModel>>>[];
      container.listen(
        movementListNotifierProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container.read(movementListNotifierProvider.notifier).load();

      expect(states.first, isA<AsyncLoading<List<MovementModel>>>());
    });

    test('sets AsyncError when repository throws', () async {
      when(() => mockRepo.getMovements(status: any(named: 'status')))
          .thenThrow(Exception('server error'));

      await container.read(movementListNotifierProvider.future).catchError((_) => <MovementModel>[]);
      await container.read(movementListNotifierProvider.notifier).load();

      expect(
        container.read(movementListNotifierProvider),
        isA<AsyncError<List<MovementModel>>>(),
      );
    });
  });

  // -------------------------------------------------------------------------
  // loadActive()
  // -------------------------------------------------------------------------
  group('MovementListNotifier.loadActive', () {
    test('passes draft,active status to repository', () async {
      when(() => mockRepo.getMovements(status: 'draft,active'))
          .thenAnswer((_) async => [_fakeMovement(status: 'draft')]);

      await container.read(movementListNotifierProvider.notifier).loadActive();

      verify(() => mockRepo.getMovements(status: 'draft,active')).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // refresh()
  // -------------------------------------------------------------------------
  group('MovementListNotifier.refresh', () {
    test('calls load with no status filter', () async {
      when(() => mockRepo.getMovements(status: null))
          .thenAnswer((_) async => []);

      await container.read(movementListNotifierProvider.notifier).refresh();

      verify(() => mockRepo.getMovements(status: null)).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // message()
  // -------------------------------------------------------------------------
  group('MovementListNotifier.message', () {
    test('extracts message from DioException response body', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/movements'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/movements'),
          statusCode: 403,
          data: {
            'error': {'message': 'Access denied'},
          },
        ),
      );

      expect(MovementListNotifier.message(error), 'Access denied');
    });

    test('extracts error string from DioException.error', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/movements'),
        error: 'Connection refused',
      );

      expect(MovementListNotifier.message(error), 'Connection refused');
    });

    test('returns generic fallback for non-DioException', () {
      expect(
        MovementListNotifier.message(Exception('boom')),
        'Something went wrong. Please try again.',
      );
    });
  });
}
