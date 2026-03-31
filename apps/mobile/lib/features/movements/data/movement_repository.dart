import 'models/movement_model.dart';
import 'movement_remote_data_source.dart';

class MovementRepository {
  MovementRepository(this._remote);

  final MovementRemoteDataSource _remote;

  Future<MovementModel> createMovement({
    required String operationType,
    required String title,
    String description = '',
    String destination = '',
    String? dueDate,
    String notes = '',
    String? propertyId,
  }) =>
      _remote.createMovement(
        operationType: operationType,
        title: title,
        description: description,
        destination: destination,
        dueDate: dueDate,
        notes: notes,
        propertyId: propertyId,
      );

  Future<List<MovementModel>> getMovements({String? status}) =>
      _remote.getMovements(status: status);

  Future<MovementModel?> getActiveDraft() => _remote.getActiveDraft();

  Future<MovementModel> getMovement(String id) => _remote.getMovement(id);

  Future<MovementModel> addItem(String movementId, String itemId) =>
      _remote.addItem(movementId, itemId);

  Future<MovementModel> removeItem(String movementId, String itemId) =>
      _remote.removeItem(movementId, itemId);

  Future<MovementModel> activate(String movementId) =>
      _remote.activate(movementId);

  Future<MovementModel> checkinItem(String movementId, String itemId) =>
      _remote.checkinItem(movementId, itemId);

  Future<MovementModel> complete(String movementId) =>
      _remote.complete(movementId);

  Future<MovementModel> cancel(String movementId) =>
      _remote.cancel(movementId);
}
