import 'models/item_history_model.dart';
import 'models/item_model.dart';
import 'item_remote_data_source.dart';

class ItemRepository {
  ItemRepository(this._remote);

  final ItemRemoteDataSource _remote;

  Future<List<ItemModel>> getItems({
    String? propertyId,
    String? roomId,
    String? category,
    String? status,
    bool unlocated = false,
    int? limit,
  }) => _remote.getItems(
    propertyId: propertyId,
    roomId: roomId,
    category: category,
    status: status,
    unlocated: unlocated,
    limit: limit,
  );

  Future<ItemModel> getItem(String id) => _remote.getItem(id);

  Future<ItemModel> createItem({
    required String propertyId,
    String? roomId,
    required String name,
    required String category,
    String subcategory = '',
    String status = 'active',
    String? serialNumber,
    String? locationDetail,
    int purchasePrice = 0,
    int currentValue = 0,
    String currency = 'USD',
    List<String> tags = const [],
    List<String> photos = const [],
    List<String> documents = const [],
    Map<String, dynamic>? attributes,
  }) {
    final body = <String, dynamic>{
      'propertyId': propertyId,
      if (roomId != null && roomId.isNotEmpty) 'roomId': roomId,
      'name': name,
      'category': category,
      if (subcategory.isNotEmpty) 'subcategory': subcategory,
      'status': status,
      if (serialNumber != null && serialNumber.isNotEmpty)
        'serialNumber': serialNumber,
      if (locationDetail != null && locationDetail.isNotEmpty)
        'locationDetail': locationDetail,
      'valuation': {
        'purchasePrice': purchasePrice,
        'currentValue': currentValue,
        'currency': currency,
      },
      'tags': tags,
      'photos': photos,
      'documents': documents,
    };
    if (attributes != null) body['attributes'] = attributes;
    return _remote.createItem(body);
  }

  Future<ItemModel> updateItem(
    String id, {
    String? name,
    String? category,
    String? subcategory,
    String? status,
    String? roomId,
    String? serialNumber,
    String? locationDetail,
    Map<String, dynamic>? valuation,
    List<String>? tags,
    List<String>? photos,
    List<String>? documents,
    Map<String, dynamic>? attributes,
  }) {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (category != null) body['category'] = category;
    if (subcategory != null) body['subcategory'] = subcategory;
    if (status != null) body['status'] = status;
    if (roomId != null) body['roomId'] = roomId;
    if (serialNumber != null) body['serialNumber'] = serialNumber;
    if (locationDetail != null) body['locationDetail'] = locationDetail;
    if (valuation != null) body['valuation'] = valuation;
    if (tags != null) body['tags'] = tags;
    if (photos != null) body['photos'] = photos;
    if (documents != null) body['documents'] = documents;
    if (attributes != null) body['attributes'] = attributes;
    return _remote.updateItem(id, body);
  }

  Future<ItemModel> assignLocation(
    String id, {
    required String roomId,
  }) => _remote.updateItem(id, {'roomId': roomId});

  Future<void> deleteItem(String id) => _remote.deleteItem(id);

  Future<List<ItemHistoryModel>> getItemHistory(String itemId) =>
      _remote.getItemHistory(itemId);
}
