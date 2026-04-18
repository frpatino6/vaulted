import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/movements/data/models/movement_model.dart';
import 'package:vaulted/features/movements/data/movement_remote_data_source.dart';
import 'package:vaulted/features/movements/data/movement_repository.dart';

class MockMovementRemoteDataSource extends Mock
    implements MovementRemoteDataSource {}

void main() {
  late MockMovementRemoteDataSource mockRemote;
  late MovementRepository repository;

  setUp(() {
    mockRemote = MockMovementRemoteDataSource();
    repository = MovementRepository(mockRemote);
  });

  test('createMovement forwards fields to remote', () async {
    final movement = MovementModel(
      id: 'm1',
      tenantId: 't',
      operationType: 'loan',
      status: 'draft',
      title: 'Loan art',
      createdBy: 'u1',
    );
    when(
      () => mockRemote.createMovement(
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
    ).thenAnswer((_) async => movement);

    final result = await repository.createMovement(
      operationType: 'loan',
      title: 'Loan art',
      propertyId: 'prop-1',
    );

    expect(result, movement);
    verify(
      () => mockRemote.createMovement(
        operationType: 'loan',
        title: 'Loan art',
        description: '',
        destination: '',
        destinationPropertyId: '',
        destinationRoomId: '',
        destinationPropertyName: '',
        destinationRoomName: '',
        dueDate: null,
        notes: '',
        propertyId: 'prop-1',
      ),
    ).called(1);
  });

  test('getMovements passes optional status', () async {
    when(() => mockRemote.getMovements(status: 'draft'))
        .thenAnswer((_) async => []);

    await repository.getMovements(status: 'draft');

    verify(() => mockRemote.getMovements(status: 'draft')).called(1);
  });

  test('mutations delegate to remote', () async {
    final movement = MovementModel(
      id: 'm',
      tenantId: 't',
      operationType: 'move',
      status: 'active',
      title: 't',
      createdBy: 'u',
    );
    when(() => mockRemote.activate('m')).thenAnswer((_) async => movement);
    when(() => mockRemote.complete('m')).thenAnswer((_) async => movement);

    expect(await repository.activate('m'), movement);
    expect(await repository.complete('m'), movement);
  });
}
