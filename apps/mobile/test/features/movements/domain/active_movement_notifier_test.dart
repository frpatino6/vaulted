import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/movements/data/models/movement_model.dart';
import 'package:vaulted/features/movements/data/movement_repository.dart';
import 'package:vaulted/features/movements/data/movement_repository_provider.dart';
import 'package:vaulted/features/movements/domain/active_movement_notifier.dart';

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
  String title = 'Test Movement',
}) {
  return MovementModel(
    id: id,
    tenantId: 'tenant-1',
    operationType: 'move',
    status: status,
    title: title,
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
    // Default stub for build() call
    when(() => mockRepo.getActiveDrafts()).thenAnswer((_) async => []);
    container = _makeContainer(repo: mockRepo);
  });

  tearDown(() {
    container.dispose();
  });

  // -------------------------------------------------------------------------
  // Build / initial state
  // -------------------------------------------------------------------------
  group('ActiveMovementNotifier — build', () {
    test('initializes by loading active drafts from repository', () async {
      final drafts = [_fakeMovement(id: 'd1'), _fakeMovement(id: 'd2')];
      when(() => mockRepo.getActiveDrafts()).thenAnswer((_) async => drafts);

      final freshContainer = _makeContainer(repo: mockRepo);
      addTearDown(freshContainer.dispose);

      // Await the build future
      final state = await freshContainer
          .read(activeMovementNotifierProvider.future);

      expect(state, drafts);
    });

    test('returns empty list when getActiveDrafts throws', () async {
      when(() => mockRepo.getActiveDrafts()).thenThrow(Exception('offline'));

      final freshContainer = _makeContainer(repo: mockRepo);
      addTearDown(freshContainer.dispose);

      final state =
          await freshContainer.read(activeMovementNotifierProvider.future);

      expect(state, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // startMovement()
  // -------------------------------------------------------------------------
  group('ActiveMovementNotifier.startMovement', () {
    test('creates movement and prepends it to the list', () async {
      final created = _fakeMovement(id: 'new-mov');
      when(
        () => mockRepo.createMovement(
          operationType: 'move',
          title: 'New Movement',
          description: '',
          destination: '',
          destinationPropertyId: '',
          destinationRoomId: '',
          destinationPropertyName: '',
          destinationRoomName: '',
          dueDate: null,
          notes: '',
          propertyId: null,
        ),
      ).thenAnswer((_) async => created);

      final notifier =
          container.read(activeMovementNotifierProvider.notifier);

      await notifier.startMovement(
        operationType: 'move',
        title: 'New Movement',
      );

      final items = container.read(activeMovementNotifierProvider).value!;
      expect(items.first.id, 'new-mov');
    });

    test('returns the created movement', () async {
      final created = _fakeMovement(id: 'ret-mov');
      when(
        () => mockRepo.createMovement(
          operationType: any(named: 'operationType'),
          title: any(named: 'title'),
          description: any(named: 'description'),
          destination: any(named: 'destination'),
          destinationPropertyId: any(named: 'destinationPropertyId'),
          destinationRoomId: any(named: 'destinationRoomId'),
          destinationPropertyName: any(named: 'destinationPropertyName'),
          destinationRoomName: any(named: 'destinationRoomName'),
          dueDate: any(named: 'dueDate'),
          notes: any(named: 'notes'),
          propertyId: any(named: 'propertyId'),
        ),
      ).thenAnswer((_) async => created);

      final result = await container
          .read(activeMovementNotifierProvider.notifier)
          .startMovement(operationType: 'move', title: 'X');

      expect(result.id, 'ret-mov');
    });
  });

  // -------------------------------------------------------------------------
  // addItem()
  // -------------------------------------------------------------------------
  group('ActiveMovementNotifier.addItem', () {
    test('replaces movement in list with updated version', () async {
      final initial = _fakeMovement(id: 'mov-1');
      final updated = _fakeMovement(id: 'mov-1', title: 'Updated');

      when(() => mockRepo.getActiveDrafts()).thenAnswer((_) async => [initial]);
      when(() => mockRepo.addItem('mov-1', 'item-1'))
          .thenAnswer((_) async => updated);

      final freshContainer = _makeContainer(repo: mockRepo);
      addTearDown(freshContainer.dispose);

      await freshContainer.read(activeMovementNotifierProvider.future);
      await freshContainer
          .read(activeMovementNotifierProvider.notifier)
          .addItem('mov-1', 'item-1');

      final items =
          freshContainer.read(activeMovementNotifierProvider).value!;
      expect(items.first.title, 'Updated');
    });
  });

  // -------------------------------------------------------------------------
  // removeItem()
  // -------------------------------------------------------------------------
  group('ActiveMovementNotifier.removeItem', () {
    test('replaces movement in list after removing item', () async {
      final initial = _fakeMovement(id: 'mov-1', title: 'Before Remove');
      final afterRemove = _fakeMovement(id: 'mov-1', title: 'After Remove');

      when(() => mockRepo.getActiveDrafts()).thenAnswer((_) async => [initial]);
      when(() => mockRepo.removeItem('mov-1', 'item-1'))
          .thenAnswer((_) async => afterRemove);

      final freshContainer = _makeContainer(repo: mockRepo);
      addTearDown(freshContainer.dispose);

      await freshContainer.read(activeMovementNotifierProvider.future);
      await freshContainer
          .read(activeMovementNotifierProvider.notifier)
          .removeItem('mov-1', 'item-1');

      final items =
          freshContainer.read(activeMovementNotifierProvider).value!;
      expect(items.first.title, 'After Remove');
    });
  });

  // -------------------------------------------------------------------------
  // activate()
  // -------------------------------------------------------------------------
  group('ActiveMovementNotifier.activate', () {
    test('removes the movement from the drafts list', () async {
      final draft1 = _fakeMovement(id: 'mov-1');
      final draft2 = _fakeMovement(id: 'mov-2');

      when(() => mockRepo.getActiveDrafts())
          .thenAnswer((_) async => [draft1, draft2]);
      when(() => mockRepo.activate('mov-1'))
          .thenAnswer((_) async => _fakeMovement(id: 'mov-1', status: 'active'));

      final freshContainer = _makeContainer(repo: mockRepo);
      addTearDown(freshContainer.dispose);

      await freshContainer.read(activeMovementNotifierProvider.future);
      await freshContainer
          .read(activeMovementNotifierProvider.notifier)
          .activate('mov-1');

      final items =
          freshContainer.read(activeMovementNotifierProvider).value!;
      expect(items.length, 1);
      expect(items.first.id, 'mov-2');
    });

    test('returns the activated movement', () async {
      final activated = _fakeMovement(id: 'mov-1', status: 'active');

      when(() => mockRepo.getActiveDrafts())
          .thenAnswer((_) async => [_fakeMovement(id: 'mov-1')]);
      when(() => mockRepo.activate('mov-1')).thenAnswer((_) async => activated);

      final freshContainer = _makeContainer(repo: mockRepo);
      addTearDown(freshContainer.dispose);

      await freshContainer.read(activeMovementNotifierProvider.future);
      final result = await freshContainer
          .read(activeMovementNotifierProvider.notifier)
          .activate('mov-1');

      expect(result.status, 'active');
    });
  });

  // -------------------------------------------------------------------------
  // cancel()
  // -------------------------------------------------------------------------
  group('ActiveMovementNotifier.cancel', () {
    test('removes cancelled movement from the list', () async {
      final draft = _fakeMovement(id: 'mov-1');

      when(() => mockRepo.getActiveDrafts()).thenAnswer((_) async => [draft]);
      when(() => mockRepo.cancel('mov-1')).thenAnswer((_) async => _fakeMovement(id: 'mov-1', status: 'cancelled'));

      final freshContainer = _makeContainer(repo: mockRepo);
      addTearDown(freshContainer.dispose);

      await freshContainer.read(activeMovementNotifierProvider.future);
      await freshContainer
          .read(activeMovementNotifierProvider.notifier)
          .cancel('mov-1');

      final items =
          freshContainer.read(activeMovementNotifierProvider).value!;
      expect(items, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // refresh()
  // -------------------------------------------------------------------------
  group('ActiveMovementNotifier.refresh', () {
    test('updates list from server', () async {
      when(() => mockRepo.getActiveDrafts()).thenAnswer((_) async => []);

      final notifier =
          container.read(activeMovementNotifierProvider.notifier);

      final refreshed = [_fakeMovement(id: 'new-1'), _fakeMovement(id: 'new-2')];
      when(() => mockRepo.getActiveDrafts()).thenAnswer((_) async => refreshed);

      await notifier.refresh();

      expect(
        container.read(activeMovementNotifierProvider).value,
        refreshed,
      );
    });

    test('keeps existing state when server throws', () async {
      final existing = [_fakeMovement(id: 'existing')];
      when(() => mockRepo.getActiveDrafts()).thenAnswer((_) async => existing);

      final freshContainer = _makeContainer(repo: mockRepo);
      addTearDown(freshContainer.dispose);

      await freshContainer.read(activeMovementNotifierProvider.future);

      when(() => mockRepo.getActiveDrafts()).thenThrow(Exception('server down'));
      await freshContainer
          .read(activeMovementNotifierProvider.notifier)
          .refresh();

      // State should remain unchanged (refresh catches and ignores errors)
      expect(
        freshContainer.read(activeMovementNotifierProvider).value,
        existing,
      );
    });
  });

  // -------------------------------------------------------------------------
  // message()
  // -------------------------------------------------------------------------
  group('ActiveMovementNotifier.message', () {
    test('extracts message from DioException response body', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/movements'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/movements'),
          statusCode: 422,
          data: {
            'error': {'message': 'Cannot activate empty movement'},
          },
        ),
      );

      expect(
        ActiveMovementNotifier.message(error),
        'Cannot activate empty movement',
      );
    });

    test('returns generic fallback for non-DioException', () {
      expect(
        ActiveMovementNotifier.message(Exception('boom')),
        'Something went wrong. Please try again.',
      );
    });
  });
}
