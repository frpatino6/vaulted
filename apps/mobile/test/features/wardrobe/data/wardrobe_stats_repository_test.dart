import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/wardrobe/data/wardrobe_stats_repository.dart';

import '../../../support/dio_test_support.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late WardrobeStatsRepository repository;
  late RequestOptions requestOptions;

  setUp(() {
    mockDio = MockDio();
    repository = WardrobeStatsRepository(mockDio);
    requestOptions = RequestOptions(path: '/test');
  });

  test('parses stats payload', () async {
    when(() => mockDio.get<Map<String, dynamic>>('wardrobe/stats')).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {
          'success': true,
          'data': {
            'totalItems': 12,
            'byCleaning': {'needs_cleaning': 2, 'at_dry_cleaner': 1},
            'outfitsCount': 3,
          },
        },
      ),
    );

    final stats = await repository.getStats();

    expect(stats.totalItems, 12);
    expect(stats.needsCleaning, 2);
    expect(stats.atDryCleaner, 1);
    expect(stats.outfitsCount, 3);
  });

  test('throws when success false', () async {
    when(() => mockDio.get<Map<String, dynamic>>('wardrobe/stats')).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': false},
      ),
    );

    expect(() => repository.getStats(), throwsA(isA<DioException>()));
  });

  test('throws when data missing', () async {
    when(() => mockDio.get<Map<String, dynamic>>('wardrobe/stats')).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': true},
      ),
    );

    expect(() => repository.getStats(), throwsA(isA<DioException>()));
  });
}
