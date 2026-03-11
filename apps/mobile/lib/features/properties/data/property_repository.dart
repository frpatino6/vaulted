import 'models/property_model.dart';
import 'property_remote_data_source.dart';

class PropertyRepository {
  PropertyRepository(this._remote);

  final PropertyRemoteDataSource _remote;

  Future<List<PropertyModel>> getProperties() => _remote.getProperties();

  Future<PropertyModel> createProperty({
    required String name,
    required String type,
    required String street,
    required String city,
    required String state,
    required String zip,
    String country = 'USA',
  }) => _remote.createProperty({
    'name': name,
    'type': type,
    'address': {
      'street': street,
      'city': city,
      'state': state,
      'zip': zip,
      'country': country,
    },
  });

  Future<PropertyModel> getProperty(String id) => _remote.getProperty(id);

  Future<PropertyModel> updateProperty(
    String id, {
    String? name,
    String? type,
    Map<String, dynamic>? address,
  }) => _remote.updateProperty(id, {
    'name': ?name,
    'type': ?type,
    'address': ?address,
  });

  Future<void> deleteProperty(String id) => _remote.deleteProperty(id);

  Future<PropertyModel> addFloor(String propertyId, String name) =>
      _remote.addFloor(propertyId, name);

  Future<PropertyModel> addRoom(
    String propertyId,
    String floorId,
    String name,
    String type,
  ) => _remote.addRoom(propertyId, floorId, name, type);
}
