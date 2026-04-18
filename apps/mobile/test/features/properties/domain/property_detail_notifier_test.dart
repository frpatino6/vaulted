import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/properties/data/models/address_model.dart';
import 'package:vaulted/features/properties/data/models/property_model.dart';
import 'package:vaulted/features/properties/data/property_repository.dart';
import 'package:vaulted/features/properties/data/property_repository_provider.dart';
import 'package:vaulted/features/properties/domain/property_detail_notifier.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockPropertyRepository extends Mock implements PropertyRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

PropertyModel _fakeProperty({String id = 'prop-1', String name = 'Aspen Chalet'}) {
  return PropertyModel(
    id: id,
    tenantId: 'tenant-1',
    name: name,
    type: 'chalet',
    address: const AddressModel(
      street: '1 Ski Run',
      city: 'Aspen',
      state: 'CO',
      zip: '81611',
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
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockPropertyRepository();
    container = _makeContainer(repo: mockRepo);
  });

  tearDown(() {
    container.dispose();
  });

  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------
  group('PropertyDetailNotifier — initial state', () {
    test('starts as AsyncData with null after build', () async {
      await container.read(propertyDetailNotifierProvider.future);
      final state = container.read(propertyDetailNotifierProvider);
      expect(state, isA<AsyncData<PropertyModel?>>());
      expect(state.value, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // load()
  // -------------------------------------------------------------------------
  group('PropertyDetailNotifier.load', () {
    test('sets state to AsyncData with property on success', () async {
      final property = _fakeProperty();
      when(() => mockRepo.getProperty('prop-1'))
          .thenAnswer((_) async => property);

      await container.read(propertyDetailNotifierProvider.future);
      await container.read(propertyDetailNotifierProvider.notifier).load('prop-1');

      expect(container.read(propertyDetailNotifierProvider).value, property);
    });

    test('returns the property on success', () async {
      final property = _fakeProperty();
      when(() => mockRepo.getProperty('prop-1'))
          .thenAnswer((_) async => property);

      await container.read(propertyDetailNotifierProvider.future);
      final result = await container
          .read(propertyDetailNotifierProvider.notifier)
          .load('prop-1');

      expect(result, property);
    });

    test('sets AsyncError and rethrows on exception', () async {
      when(() => mockRepo.getProperty(any())).thenThrow(Exception('not found'));

      await container.read(propertyDetailNotifierProvider.future);

      await expectLater(
        container.read(propertyDetailNotifierProvider.notifier).load('bad-id'),
        throwsA(isA<Exception>()),
      );

      expect(
        container.read(propertyDetailNotifierProvider),
        isA<AsyncError<PropertyModel?>>(),
      );
    });

    test('transitions through AsyncLoading', () async {
      when(() => mockRepo.getProperty('prop-1'))
          .thenAnswer((_) async => _fakeProperty());

      await container.read(propertyDetailNotifierProvider.future);

      final states = <AsyncValue<PropertyModel?>>[];
      container.listen(
        propertyDetailNotifierProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container.read(propertyDetailNotifierProvider.notifier).load('prop-1');

      expect(states.first, isA<AsyncLoading<PropertyModel?>>());
      expect(states.last, isA<AsyncData<PropertyModel?>>());
    });
  });

  // -------------------------------------------------------------------------
  // addFloor()
  // -------------------------------------------------------------------------
  group('PropertyDetailNotifier.addFloor', () {
    test('returns null when load() has not been called', () async {
      await container.read(propertyDetailNotifierProvider.future);
      final result = await container
          .read(propertyDetailNotifierProvider.notifier)
          .addFloor('Ground Floor');

      expect(result, isNull);
      verifyNever(() => mockRepo.addFloor(any(), any()));
    });

    test('updates state with updated property after adding floor', () async {
      final initial = _fakeProperty();
      final updated = _fakeProperty(name: 'With Floor');

      when(() => mockRepo.getProperty('prop-1'))
          .thenAnswer((_) async => initial);
      when(() => mockRepo.addFloor('prop-1', 'Ground Floor'))
          .thenAnswer((_) async => updated);

      final notifier = container.read(propertyDetailNotifierProvider.notifier);
      await notifier.load('prop-1');
      final result = await notifier.addFloor('Ground Floor');

      expect(result, updated);
      expect(container.read(propertyDetailNotifierProvider).value, updated);
    });

    test('propagates exception from repository', () async {
      when(() => mockRepo.getProperty('prop-1'))
          .thenAnswer((_) async => _fakeProperty());
      when(() => mockRepo.addFloor('prop-1', any()))
          .thenThrow(Exception('add floor failed'));

      final notifier = container.read(propertyDetailNotifierProvider.notifier);
      await notifier.load('prop-1');

      await expectLater(
        notifier.addFloor('Floor'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // addRoom()
  // -------------------------------------------------------------------------
  group('PropertyDetailNotifier.addRoom', () {
    test('returns null when load() has not been called', () async {
      await container.read(propertyDetailNotifierProvider.future);
      final result = await container
          .read(propertyDetailNotifierProvider.notifier)
          .addRoom('floor-1', 'Living Room', 'living_room');

      expect(result, isNull);
      verifyNever(() => mockRepo.addRoom(any(), any(), any(), any()));
    });

    test('updates state with updated property after adding room', () async {
      final initial = _fakeProperty();
      final updated = _fakeProperty(name: 'With Room');

      when(() => mockRepo.getProperty('prop-1'))
          .thenAnswer((_) async => initial);
      when(() => mockRepo.addRoom('prop-1', 'floor-1', 'Living Room', 'living'))
          .thenAnswer((_) async => updated);

      final notifier = container.read(propertyDetailNotifierProvider.notifier);
      await notifier.load('prop-1');
      final result = await notifier.addRoom('floor-1', 'Living Room', 'living');

      expect(result, updated);
      expect(container.read(propertyDetailNotifierProvider).value, updated);
    });
  });

  // -------------------------------------------------------------------------
  // message()
  // -------------------------------------------------------------------------
  group('PropertyDetailNotifier.message', () {
    test('extracts message from DioException response body', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/properties/p1'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/properties/p1'),
          statusCode: 404,
          data: {
            'error': {'message': 'Property not found'},
          },
        ),
      );

      expect(PropertyDetailNotifier.message(error), 'Property not found');
    });

    test('returns generic fallback for non-DioException', () {
      expect(
        PropertyDetailNotifier.message(Exception('fail')),
        'Something went wrong. Please try again.',
      );
    });
  });
}
