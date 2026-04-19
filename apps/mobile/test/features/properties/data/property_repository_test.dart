import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/properties/data/models/address_model.dart';
import 'package:vaulted/features/properties/data/models/property_model.dart';
import 'package:vaulted/features/properties/data/property_remote_data_source.dart';
import 'package:vaulted/features/properties/data/property_repository.dart';

class MockPropertyRemoteDataSource extends Mock
    implements PropertyRemoteDataSource {}

void main() {
  late MockPropertyRemoteDataSource mockRemote;
  late PropertyRepository repository;

  setUp(() {
    mockRemote = MockPropertyRemoteDataSource();
    repository = PropertyRepository(mockRemote);
  });

  test('createProperty maps fields to remote body', () async {
    final property = PropertyModel(
      id: 'p1',
      tenantId: 't',
      name: 'Villa',
      type: 'residence',
      address: const AddressModel(
        street: '1 Ocean Dr',
        city: 'Miami',
        state: 'FL',
        zip: '33139',
        country: 'USA',
      ),
    );
    when(() => mockRemote.createProperty(any())).thenAnswer((_) async => property);

    final result = await repository.createProperty(
      name: 'Villa',
      type: 'residence',
      street: '1 Ocean Dr',
      city: 'Miami',
      state: 'FL',
      zip: '33139',
    );

    expect(result, property);

    final body = verify(() => mockRemote.createProperty(captureAny()))
        .captured
        .single as Map<String, dynamic>;

    expect(body['name'], 'Villa');
    expect(body['type'], 'residence');
    expect(body['address'], isA<Map<String, dynamic>>());
    expect(body['photos'], isEmpty);
  });

  test('updateProperty sends only provided keys', () async {
    when(() => mockRemote.updateProperty('p', any()))
        .thenAnswer((_) async => PropertyModel(
              id: 'p',
              tenantId: 't',
              name: 'Renamed',
              type: 'residence',
              address: const AddressModel(
                street: 's',
                city: 'c',
                state: 'st',
                zip: 'z',
                country: 'USA',
              ),
            ));

    await repository.updateProperty(id: 'p', name: 'Renamed');

    final body = verify(() => mockRemote.updateProperty('p', captureAny()))
        .captured
        .single as Map<String, dynamic>;
    expect(body, {'name': 'Renamed'});
  });

  test('addFloor and addRoom delegate', () async {
    final property = PropertyModel(
      id: 'p',
      tenantId: 't',
      name: 'n',
      type: 't',
      address: const AddressModel(
        street: 's',
        city: 'c',
        state: 'st',
        zip: 'z',
        country: 'USA',
      ),
    );
    when(() => mockRemote.addFloor('p', 'Ground')).thenAnswer((_) async => property);
    when(() => mockRemote.addRoom('p', 'f1', 'Kitchen', 'kitchen'))
        .thenAnswer((_) async => property);

    expect(await repository.addFloor('p', 'Ground'), property);
    expect(await repository.addRoom('p', 'f1', 'Kitchen', 'kitchen'), property);
  });
}
