import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/wardrobe/data/at_laundry_repository.dart';

import '../../../support/dio_test_support.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late AtLaundryRepository repository;
  late RequestOptions requestOptions;

  setUp(() {
    mockDio = MockDio();
    repository = AtLaundryRepository(mockDio);
    requestOptions = RequestOptions(path: '/test');
  });

  group('AtLaundryRepository.getAtLaundry', () {
    test('should_return_at_laundry_data_when_response_is_successful', () async {
      when(() => mockDio.get<Map<String, dynamic>>('wardrobe/at-laundry'))
          .thenAnswer(
        (_) async => makeMapResponse(
          requestOptions: requestOptions,
          data: {
            'success': true,
            'data': {
              'totalItems': 2,
              'overdueItems': 1,
              'overdueThresholdDays': 7,
              'byProperty': [
                {
                  'propertyId': 'prop-1',
                  'propertyName': 'Miami House',
                  'items': [
                    {
                      'recordId': 'rec-1',
                      'itemId': 'item-1',
                      'itemName': 'Blue Shirt',
                      'sentDate': '2026-01-10T00:00:00.000Z',
                      'daysAtCleaner': 10,
                      'isOverdue': true,
                    },
                    {
                      'recordId': 'rec-2',
                      'itemId': 'item-2',
                      'itemName': 'Black Suit',
                      'sentDate': '2026-01-15T00:00:00.000Z',
                      'daysAtCleaner': 5,
                      'isOverdue': false,
                    },
                  ],
                },
              ],
            },
          },
        ),
      );

      final result = await repository.getAtLaundry();

      expect(result.totalItems, 2);
      expect(result.overdueItems, 1);
      expect(result.overdueThresholdDays, 7);
      expect(result.byProperty, hasLength(1));
      expect(result.byProperty.first.propertyId, 'prop-1');
      expect(result.byProperty.first.items, hasLength(2));
      expect(result.byProperty.first.items.first.isOverdue, isTrue);
      verify(
        () => mockDio.get<Map<String, dynamic>>('wardrobe/at-laundry'),
      ).called(1);
    });

    test('should_throw_when_response_envelope_has_success_false', () async {
      when(() => mockDio.get<Map<String, dynamic>>('wardrobe/at-laundry'))
          .thenAnswer(
        (_) async => makeMapResponse(
          requestOptions: requestOptions,
          data: {
            'success': false,
            'error': {'message': 'Unauthorized'},
          },
        ),
      );

      expect(
        () => repository.getAtLaundry(),
        throwsA(isA<DioException>()),
      );
    });

    test('should_throw_when_dio_raises_a_network_error', () async {
      when(() => mockDio.get<Map<String, dynamic>>('wardrobe/at-laundry'))
          .thenThrow(
        DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repository.getAtLaundry(),
        throwsA(isA<DioException>()),
      );
    });
  });
}
