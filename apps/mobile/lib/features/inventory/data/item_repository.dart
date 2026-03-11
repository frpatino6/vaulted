import 'models/item_model.dart';
import 'item_remote_data_source.dart';

class ItemRepository {
  ItemRepository(this._remote);

  final ItemRemoteDataSource _remote;

  Future<List<ItemModel>> getItems({
    required String propertyId,
    required String roomId,
    String? category,
    String? status,
  }) =>
      _remote.getItems(
        propertyId: propertyId,
        roomId: roomId,
        category: category,
        status: status,
      );

  Future<ItemModel> getItem(String id) => _remote.getItem(id);

  Future<ItemModel> createItem({
    required String propertyId,
    required String roomId,
    required String name,
    required String category,
    String subcategory = '',
    String status = 'active',
    String? serialNumber,
    int purchasePrice = 0,
    int currentValue = 0,
    String currency = 'USD',
    List<String> tags = const [],
    List<String> photos = const [],
    List<String> documents = const [],
  }) =>
      _remote.createItem({
        'propertyId': propertyId,
        'roomId': roomId,
        'name': name,
        'category': category,
        if (subcategory.isNotEmpty) 'subcategory': subcategory,
        'status': status,
        if (serialNumber != null && serialNumber.isNotEmpty) 'serialNumber': serialNumber,
        'valuation': {
          'purchasePrice': purchasePrice,
          'currentValue': currentValue,
          'currency': currency,
        },
        'tags': tags,
        'photos': photos,
        'documents': documents,
      });

  Future<ItemModel> updateItem(
    String id, {
    String? name,
    String? category,
    String? subcategory,
    String? status,
    String? serialNumber,
    Map<String, dynamic>? valuation,
    List<String>? tags,
    List<String>? photos,
    List<String>? documents,
  }) {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (category != null) body['category'] = category;
    if (subcategory != null) body['subcategory'] = subcategory;
    if (status != null) body['status'] = status;
    if (serialNumber != null) body['serialNumber'] = serialNumber;
    if (valuation != null) body['valuation'] = valuation;
    if (tags != null) body['tags'] = tags;
    if (photos != null) body['photos'] = photos;
    if (documents != null) body['documents'] = documents;
    return _remote.updateItem(id, body);
  }

  Future<void> deleteItem(String id) => _remote.deleteItem(id);
}
