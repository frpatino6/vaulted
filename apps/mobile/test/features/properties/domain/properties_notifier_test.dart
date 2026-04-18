import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/properties/data/models/address_model.dart';
import 'package:vaulted/features/properties/data/models/property_model.dart';
import 'package:vaulted/features/properties/data/property_repository.dart';
import 'package:vaulted/features/properties/data/property_repository_provider.dart';
import 'package:vaulted/features/properties/domain/properties_notifier.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockPropertyRepository extends Mock implements PropertyRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

PropertyModel _fakeProperty({String id = 'prop-1', String name = 'Miami Mansion'}) {
  return PropertyModel(
    id: id,
    tenantId: 'tenant-1',
    name: name,
    type: 'mansion',
    address: const AddressModel(
      street: '123 Ocean Dr',
      city: 'Miami',
      state: 'FL',
      zip: '33139',
      country: 'USA',
    ),
  );
}

ProviderContainer _makeContainer({required MockPropertyRepository repo}) {
  return ProviderContainer(
    overrides: [
      propertyRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockPropertyRepository mockRepo;

  setUp(() {
    mockRepo = MockPropertyRepository();
  });

  // -------------------------------------------------------------------------
  // Build / initial state
  // -------------------------------------------------------------------------
  group('PropertiesNotifier — build', () {
    test('initializes by loading properties from repository', () async {
      final properties = [_fakeProperty(id: 'p1'), _fakeProperty(id: 'p2')];
      when(() => mockRepo.getProperties()).thenAnswer((_) async => properties);

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      final state = await container.read(propertiesNotifierProvider.future);
      expect(state, properties);
    });

    test('sets AsyncError when build throws', () async {
      when(() => mockRepo.getProperties()).thenThrow(Exception('server error'));

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(propertiesNotifierProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // load()
  // -------------------------------------------------------------------------
  group('PropertiesNotifier.load', () {
    test('refreshes properties and updates state', () async {
      final initial = [_fakeProperty(id: 'p1')];
      when(() => mockRepo.getProperties()).thenAnswer((_) async => initial);

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await container.read(propertiesNotifierProvider.future);

      final updated = [_fakeProperty(id: 'p1'), _fakeProperty(id: 'p2')];
      when(() => mockRepo.getProperties()).thenAnswer((_) async => updated);

      await container.read(propertiesNotifierProvider.notifier).load();

      expect(container.read(propertiesNotifierProvider).value, updated);
    });

    test('returns the list of properties', () async {
      final properties = [_fakeProperty()];
      when(() => mockRepo.getProperties()).thenAnswer((_) async => properties);

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      final result =
          await container.read(propertiesNotifierProvider.notifier).load();

      expect(result, properties);
    });

    test('sets AsyncError and rethrows when repository throws', () async {
      when(() => mockRepo.getProperties())
          .thenAnswer((_) async => [_fakeProperty()]);

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await container.read(propertiesNotifierProvider.future);

      when(() => mockRepo.getProperties()).thenThrow(Exception('network error'));

      await expectLater(
        container.read(propertiesNotifierProvider.notifier).load(),
        throwsA(isA<Exception>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // create()
  // -------------------------------------------------------------------------
  group('PropertiesNotifier.create', () {
    test('creates property and reloads the list', () async {
      final existing = [_fakeProperty(id: 'p1')];
      final created = _fakeProperty(id: 'p2', name: 'New Property');
      final afterCreate = [...existing, created];

      when(() => mockRepo.getProperties()).thenAnswer((_) async => existing);
      when(
        () => mockRepo.createProperty(
          name: 'New Property',
          type: 'house',
          street: '1 Main St',
          city: 'Austin',
          state: 'TX',
          zip: '78701',
          country: 'USA',
          photos: [],
        ),
      ).thenAnswer((_) async => created);

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await container.read(propertiesNotifierProvider.future);

      when(() => mockRepo.getProperties()).thenAnswer((_) async => afterCreate);

      final result = await container
          .read(propertiesNotifierProvider.notifier)
          .create(
            name: 'New Property',
            type: 'house',
            street: '1 Main St',
            city: 'Austin',
            state: 'TX',
            zip: '78701',
          );

      expect(result!.id, 'p2');
      expect(container.read(propertiesNotifierProvider).value!.length, 2);
    });

    test('propagates exception from repository', () async {
      when(() => mockRepo.getProperties()).thenAnswer((_) async => []);
      when(
        () => mockRepo.createProperty(
          name: any(named: 'name'),
          type: any(named: 'type'),
          street: any(named: 'street'),
          city: any(named: 'city'),
          state: any(named: 'state'),
          zip: any(named: 'zip'),
          country: any(named: 'country'),
          photos: any(named: 'photos'),
        ),
      ).thenThrow(Exception('create failed'));

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await container.read(propertiesNotifierProvider.future);

      await expectLater(
        container.read(propertiesNotifierProvider.notifier).create(
              name: 'X',
              type: 'house',
              street: 'A',
              city: 'B',
              state: 'C',
              zip: '0',
            ),
        throwsA(isA<Exception>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // updatePhotos()
  // -------------------------------------------------------------------------
  group('PropertiesNotifier.updatePhotos', () {
    test('calls updateProperty and reloads list', () async {
      final property = _fakeProperty();
      when(() => mockRepo.getProperties()).thenAnswer((_) async => [property]);
      when(
        () => mockRepo.updateProperty(
          id: 'prop-1',
          photos: ['url1', 'url2'],
        ),
      ).thenAnswer((_) async => property);

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await container.read(propertiesNotifierProvider.future);

      await container
          .read(propertiesNotifierProvider.notifier)
          .updatePhotos('prop-1', ['url1', 'url2']);

      verify(() => mockRepo.updateProperty(id: 'prop-1', photos: ['url1', 'url2']))
          .called(1);
    });
  });

  // -------------------------------------------------------------------------
  // delete()
  // -------------------------------------------------------------------------
  group('PropertiesNotifier.delete', () {
    test('deletes property and reloads list', () async {
      final p1 = _fakeProperty(id: 'p1');
      final p2 = _fakeProperty(id: 'p2');

      when(() => mockRepo.getProperties()).thenAnswer((_) async => [p1, p2]);
      when(() => mockRepo.deleteProperty('p1')).thenAnswer((_) async {});

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await container.read(propertiesNotifierProvider.future);

      when(() => mockRepo.getProperties()).thenAnswer((_) async => [p2]);

      await container.read(propertiesNotifierProvider.notifier).delete('p1');

      expect(
        container.read(propertiesNotifierProvider).value!.length,
        1,
      );
    });
  });

  // -------------------------------------------------------------------------
  // message()
  // -------------------------------------------------------------------------
  group('PropertiesNotifier.message', () {
    test('extracts message from DioException response body', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/properties'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/properties'),
          statusCode: 409,
          data: {
            'error': {'message': 'Property already exists'},
          },
        ),
      );

      expect(PropertiesNotifier.message(error), 'Property already exists');
    });

    test('returns generic fallback for non-DioException', () {
      expect(
        PropertiesNotifier.message(Exception('boom')),
        'Something went wrong. Please try again.',
      );
    });
  });
}
