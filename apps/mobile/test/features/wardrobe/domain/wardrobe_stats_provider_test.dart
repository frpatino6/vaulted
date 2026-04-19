import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/wardrobe/data/wardrobe_stats_repository.dart';
import 'package:vaulted/features/wardrobe/data/wardrobe_stats_repository_provider.dart';
import 'package:vaulted/features/wardrobe/domain/wardrobe_stats_provider.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockWardrobeStatsRepository extends Mock
    implements WardrobeStatsRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

WardrobeStatsModel _fakeStats({
  int totalItems = 42,
  int needsCleaning = 5,
  int atDryCleaner = 2,
  int outfitsCount = 10,
}) {
  return WardrobeStatsModel(
    totalItems: totalItems,
    needsCleaning: needsCleaning,
    atDryCleaner: atDryCleaner,
    outfitsCount: outfitsCount,
  );
}

ProviderContainer _makeContainer({
  required MockWardrobeStatsRepository repo,
}) {
  return ProviderContainer(
    overrides: [
      wardrobeStatsRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockWardrobeStatsRepository mockRepo;

  setUp(() {
    mockRepo = MockWardrobeStatsRepository();
  });

  // -------------------------------------------------------------------------
  // wardrobeStatsProvider
  // -------------------------------------------------------------------------
  group('wardrobeStatsProvider', () {
    test('returns WardrobeStatsModel on success', () async {
      final stats = _fakeStats();
      when(() => mockRepo.getStats()).thenAnswer((_) async => stats);

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      final result = await container.read(wardrobeStatsProvider.future);

      expect(result.totalItems, 42);
      expect(result.needsCleaning, 5);
      expect(result.atDryCleaner, 2);
      expect(result.outfitsCount, 10);
    });

    test('sets AsyncError when repository throws', () async {
      when(() => mockRepo.getStats()).thenThrow(Exception('server error'));

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(wardrobeStatsProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('passes through zero values correctly', () async {
      final stats = _fakeStats(
        totalItems: 0,
        needsCleaning: 0,
        atDryCleaner: 0,
        outfitsCount: 0,
      );
      when(() => mockRepo.getStats()).thenAnswer((_) async => stats);

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      final result = await container.read(wardrobeStatsProvider.future);

      expect(result.totalItems, 0);
      expect(result.needsCleaning, 0);
      expect(result.atDryCleaner, 0);
      expect(result.outfitsCount, 0);
    });

    test('starts as AsyncLoading before resolving', () {
      when(() => mockRepo.getStats())
          .thenAnswer((_) async => _fakeStats());

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      // Read synchronously before awaiting
      final state = container.read(wardrobeStatsProvider);
      expect(state, isA<AsyncLoading<WardrobeStatsModel>>());
    });
  });

  // -------------------------------------------------------------------------
  // WardrobeStatsModel
  // -------------------------------------------------------------------------
  group('WardrobeStatsModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'totalItems': 15,
        'byCleaning': {
          'needs_cleaning': 3,
          'at_dry_cleaner': 1,
        },
        'outfitsCount': 7,
      };

      final model = WardrobeStatsModel.fromJson(json);

      expect(model.totalItems, 15);
      expect(model.needsCleaning, 3);
      expect(model.atDryCleaner, 1);
      expect(model.outfitsCount, 7);
    });

    test('fromJson defaults to 0 when fields are missing', () {
      final model = WardrobeStatsModel.fromJson({});

      expect(model.totalItems, 0);
      expect(model.needsCleaning, 0);
      expect(model.atDryCleaner, 0);
      expect(model.outfitsCount, 0);
    });

    test('fromJson handles numeric values as int', () {
      final json = {
        'totalItems': 100,
        'byCleaning': {
          'needs_cleaning': 10,
          'at_dry_cleaner': 5,
        },
        'outfitsCount': 20,
      };

      final model = WardrobeStatsModel.fromJson(json);
      expect(model.totalItems, 100);
    });
  });
}
