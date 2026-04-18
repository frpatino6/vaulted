import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/maintenance/data/maintenance_remote_data_source.dart';
import 'package:vaulted/features/maintenance/data/maintenance_repository.dart';
import 'package:vaulted/features/maintenance/data/models/maintenance_model.dart';

class MockMaintenanceRemoteDataSource extends Mock
    implements MaintenanceRemoteDataSource {}

void main() {
  late MockMaintenanceRemoteDataSource mockRemote;
  late MaintenanceRepository repository;

  setUp(() {
    mockRemote = MockMaintenanceRemoteDataSource();
    repository = MaintenanceRepository(mockRemote);
  });

  test('getAll forwards flags and daysAhead only when upcoming', () async {
    when(
      () => mockRemote.getAll(
        status: any(named: 'status'),
        itemId: any(named: 'itemId'),
        upcoming: any(named: 'upcoming'),
        daysAhead: any(named: 'daysAhead'),
      ),
    ).thenAnswer((_) async => []);

    await repository.getAll(upcoming: true, daysAhead: 14);

    verify(
      () => mockRemote.getAll(
        status: null,
        itemId: null,
        upcoming: true,
        daysAhead: 14,
      ),
    ).called(1);
  });

  test('getAll passes null daysAhead when not upcoming', () async {
    when(
      () => mockRemote.getAll(
        status: any(named: 'status'),
        itemId: any(named: 'itemId'),
        upcoming: any(named: 'upcoming'),
        daysAhead: any(named: 'daysAhead'),
      ),
    ).thenAnswer((_) async => []);

    await repository.getAll(upcoming: false, daysAhead: 99);

    verify(
      () => mockRemote.getAll(
        status: null,
        itemId: null,
        upcoming: false,
        daysAhead: null,
      ),
    ).called(1);
  });

  test('schedule builds ISO body and omits empty strings', () async {
    final model = MaintenanceModel(
      id: '1',
      itemId: 'it',
      tenantId: 't',
      title: 'Tune piano',
      scheduledDate: DateTime.utc(2026, 6, 1).toIso8601String(),
    );
    when(() => mockRemote.create(any(), any())).thenAnswer((_) async => model);

    await repository.schedule(
      itemId: 'it',
      title: 'Tune piano',
      scheduledDate: DateTime.utc(2026, 6, 1),
      description: '',
      isRecurring: false,
    );

    final captured = verify(() => mockRemote.create('it', captureAny()))
        .captured
        .single as Map<String, dynamic>;

    expect(captured['title'], 'Tune piano');
    expect(captured.containsKey('description'), isFalse);
    expect(captured['isRecurring'], false);
    expect(captured.containsKey('recurrenceIntervalDays'), isFalse);
  });

  test('complete builds status and completedDate', () async {
    final model = MaintenanceModel(
      id: 'm',
      itemId: 'i',
      tenantId: 't',
      title: 't',
      scheduledDate: '2026-01-01T00:00:00.000Z',
      status: 'completed',
    );
    when(() => mockRemote.update('m', any())).thenAnswer((_) async => model);

    final done = DateTime.utc(2026, 2, 1);
    await repository.complete('m', completedDate: done, cost: 50);

    final body = verify(() => mockRemote.update('m', captureAny()))
        .captured
        .single as Map<String, dynamic>;

    expect(body['status'], 'completed');
    expect(body['cost'], 50);
    expect(body['completedDate'], done.toIso8601String());
  });

  test('cancel and delete delegate', () async {
    when(() => mockRemote.update('1', any())).thenAnswer(
      (_) async => MaintenanceModel(
        id: '1',
        itemId: 'i',
        tenantId: 't',
        title: 't',
        scheduledDate: '2026-01-01T00:00:00.000Z',
        status: 'cancelled',
      ),
    );
    when(() => mockRemote.delete('1')).thenAnswer((_) async {});

    await repository.cancel('1');
    await repository.delete('1');

    verify(() => mockRemote.update('1', {'status': 'cancelled'})).called(1);
    verify(() => mockRemote.delete('1')).called(1);
  });

  test('analyzeWithAi delegates', () async {
    when(() => mockRemote.analyzeWithAi('it')).thenAnswer(
      (_) async => {'risk': 0.2},
    );

    expect(await repository.analyzeWithAi('it'), {'risk': 0.2});
  });
}
