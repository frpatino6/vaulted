import 'models/maintenance_model.dart';
import 'maintenance_remote_data_source.dart';

class MaintenanceRepository {
  MaintenanceRepository(this._remote);

  final MaintenanceRemoteDataSource _remote;

  Future<List<MaintenanceModel>> getAll({
    String? status,
    String? itemId,
    bool upcoming = false,
    int daysAhead = 30,
  }) =>
      _remote.getAll(
        status: status,
        itemId: itemId,
        upcoming: upcoming,
        daysAhead: upcoming ? daysAhead : null,
      );

  Future<List<MaintenanceModel>> getByItem(String itemId) =>
      _remote.getByItem(itemId);

  Future<MaintenanceModel> schedule({
    required String itemId,
    required String title,
    required DateTime scheduledDate,
    String? description,
    bool isRecurring = false,
    int? recurrenceIntervalDays,
    String? providerName,
    String? providerContact,
    double? cost,
    String currency = 'USD',
    String? notes,
    List<String> documents = const [],
  }) {
    final body = <String, dynamic>{
      'title': title,
      'scheduledDate': scheduledDate.toIso8601String(),
      if (description != null && description.isNotEmpty) 'description': description,
      'isRecurring': isRecurring,
      if (isRecurring && recurrenceIntervalDays != null)
        'recurrenceIntervalDays': recurrenceIntervalDays,
      if (providerName != null && providerName.isNotEmpty) 'providerName': providerName,
      if (providerContact != null && providerContact.isNotEmpty)
        'providerContact': providerContact,
      if (cost != null) 'cost': cost,
      'currency': currency,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'documents': documents,
    };
    return _remote.create(itemId, body);
  }

  Future<MaintenanceModel> complete(
    String id, {
    DateTime? completedDate,
    double? cost,
    String? notes,
  }) {
    final body = <String, dynamic>{
      'status': 'completed',
      'completedDate': (completedDate ?? DateTime.now()).toIso8601String(),
      if (cost != null) 'cost': cost,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
    return _remote.update(id, body);
  }

  Future<MaintenanceModel> cancel(String id) =>
      _remote.update(id, {'status': 'cancelled'});

  Future<MaintenanceModel> update(
    String id,
    Map<String, dynamic> fields,
  ) =>
      _remote.update(id, fields);

  Future<void> delete(String id) => _remote.delete(id);

  Future<Map<String, dynamic>> analyzeWithAi(String itemId) =>
      _remote.analyzeWithAi(itemId);
}
