import 'models/property_model.dart';
import 'models/room_section_model.dart';
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
    List<String> photos = const [],
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
    'photos': photos,
  });

  Future<PropertyModel> getProperty(String id) => _remote.getProperty(id);

  Future<PropertyModel> updateProperty({
    required String id,
    String? name,
    String? type,
    Map<String, dynamic>? address,
    List<String>? photos,
  }) {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (type != null) body['type'] = type;
    if (address != null) body['address'] = address;
    if (photos != null) body['photos'] = photos;
    return _remote.updateProperty(id, body);
  }

  Future<void> deleteProperty(String id) => _remote.deleteProperty(id);

  Future<PropertyModel> addFloor(String propertyId, String name) =>
      _remote.addFloor(propertyId, name);

  Future<PropertyModel> addRoom(
    String propertyId,
    String floorId,
    String name,
    String type,
  ) => _remote.addRoom(propertyId, floorId, name, type);

  Future<PropertyModel> updateRoom(
    String propertyId,
    String floorId,
    String roomId,
    String name,
    String type,
  ) => _remote.updateRoom(propertyId, floorId, roomId, name, type);

  Future<PropertyModel> deleteRoom(
    String propertyId,
    String floorId,
    String roomId,
  ) => _remote.deleteRoom(propertyId, floorId, roomId);

  // ── Sections ──────────────────────────────────────────────────────────────

  Future<List<RoomSectionModel>> getSections(
    String propertyId,
    String floorId,
    String roomId,
  ) => _remote.getSections(propertyId, floorId, roomId);

  Future<PropertyModel> addSection(
    String propertyId,
    String floorId,
    String roomId, {
    required String code,
    required String name,
    required String type,
    String? notes,
  }) => _remote.addSection(propertyId, floorId, roomId, {
    'code': code,
    'name': name,
    'type': type,
    if (notes != null) 'notes': notes,
  });

  Future<PropertyModel> addSectionsBulk(
    String propertyId,
    String floorId,
    String roomId,
    List<Map<String, dynamic>> sections,
  ) => _remote.addSectionsBulk(propertyId, floorId, roomId, sections);

  Future<PropertyModel> updateSection(
    String propertyId,
    String floorId,
    String roomId,
    String sectionId, {
    String? code,
    String? name,
    String? type,
    String? notes,
  }) => _remote.updateSection(propertyId, floorId, roomId, sectionId, {
    if (code != null) 'code': code,
    if (name != null) 'name': name,
    if (type != null) 'type': type,
    if (notes != null) 'notes': notes,
  });

  Future<PropertyModel> deleteSection(
    String propertyId,
    String floorId,
    String roomId,
    String sectionId,
  ) => _remote.deleteSection(propertyId, floorId, roomId, sectionId);

  Future<Map<String, dynamic>> analyzeSections(String imageUrl) =>
      _remote.analyzeSections(imageUrl);
}
