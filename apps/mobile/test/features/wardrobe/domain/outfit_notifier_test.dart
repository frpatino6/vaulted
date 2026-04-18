import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/wardrobe/data/outfit_model.dart';
import 'package:vaulted/features/wardrobe/data/outfit_repository.dart';
import 'package:vaulted/features/wardrobe/data/outfit_repository_provider.dart';
import 'package:vaulted/features/wardrobe/domain/outfit_notifier.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockOutfitRepository extends Mock implements OutfitRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

OutfitModel _fakeOutfit({String id = 'outfit-1', String name = 'Summer Look'}) {
  return OutfitModel(id: id, name: name);
}

ProviderContainer _makeContainer({required MockOutfitRepository repo}) {
  return ProviderContainer(
    overrides: [
      outfitRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockOutfitRepository mockRepo;

  setUp(() {
    mockRepo = MockOutfitRepository();
  });

  // -------------------------------------------------------------------------
  // Build / initial state
  // -------------------------------------------------------------------------
  group('OutfitNotifier — build', () {
    test('loads outfits from repository during build', () async {
      final outfits = [_fakeOutfit(id: 'o1'), _fakeOutfit(id: 'o2')];
      when(() => mockRepo.getOutfits()).thenAnswer((_) async => outfits);

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      final state = await container.read(outfitNotifierProvider.future);
      expect(state, outfits);
    });

    test('sets AsyncError when build fails', () async {
      when(() => mockRepo.getOutfits()).thenThrow(Exception('server error'));

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(outfitNotifierProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // refresh()
  // -------------------------------------------------------------------------
  group('OutfitNotifier.refresh', () {
    test('re-fetches outfits and updates state', () async {
      when(() => mockRepo.getOutfits())
          .thenAnswer((_) async => [_fakeOutfit(id: 'o1')]);

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await container.read(outfitNotifierProvider.future);

      final updated = [_fakeOutfit(id: 'o1'), _fakeOutfit(id: 'o2')];
      when(() => mockRepo.getOutfits()).thenAnswer((_) async => updated);

      await container.read(outfitNotifierProvider.notifier).refresh();

      expect(container.read(outfitNotifierProvider).value, updated);
    });

    test('transitions through AsyncLoading on refresh', () async {
      when(() => mockRepo.getOutfits()).thenAnswer((_) async => []);

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await container.read(outfitNotifierProvider.future);

      final states = <AsyncValue<List<OutfitModel>>>[];
      container.listen(
        outfitNotifierProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      when(() => mockRepo.getOutfits()).thenAnswer((_) async => []);
      await container.read(outfitNotifierProvider.notifier).refresh();

      expect(states.first, isA<AsyncLoading<List<OutfitModel>>>());
    });
  });

  // -------------------------------------------------------------------------
  // createOutfit()
  // -------------------------------------------------------------------------
  group('OutfitNotifier.createOutfit', () {
    test('creates outfit and refreshes list', () async {
      final initial = [_fakeOutfit(id: 'o1')];
      final created = _fakeOutfit(id: 'o2', name: 'Winter Look');
      final afterCreate = [...initial, created];

      when(() => mockRepo.getOutfits()).thenAnswer((_) async => initial);
      when(
        () => mockRepo.createOutfit(any()),
      ).thenAnswer((_) async => created);

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await container.read(outfitNotifierProvider.future);

      when(() => mockRepo.getOutfits()).thenAnswer((_) async => afterCreate);

      await container.read(outfitNotifierProvider.notifier).createOutfit(
            name: 'Winter Look',
            itemIds: ['item-1', 'item-2'],
          );

      expect(container.read(outfitNotifierProvider).value!.length, 2);
    });

    test('includes optional fields in payload when provided', () async {
      when(() => mockRepo.getOutfits()).thenAnswer((_) async => []);
      when(() => mockRepo.createOutfit(any()))
          .thenAnswer((_) async => _fakeOutfit());

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await container.read(outfitNotifierProvider.future);

      when(() => mockRepo.getOutfits()).thenAnswer((_) async => [_fakeOutfit()]);

      await container.read(outfitNotifierProvider.notifier).createOutfit(
            name: 'Beach Look',
            description: 'For the beach',
            season: 'summer',
            occasion: 'casual',
            itemIds: ['item-1'],
          );

      final captured =
          verify(() => mockRepo.createOutfit(captureAny())).captured;
      final payload = captured.first as Map<String, dynamic>;

      expect(payload['name'], 'Beach Look');
      expect(payload['description'], 'For the beach');
      expect(payload['season'], 'summer');
      expect(payload['occasion'], 'casual');
      expect(payload['itemIds'], ['item-1']);
    });

    test('omits optional fields when null or empty', () async {
      when(() => mockRepo.getOutfits()).thenAnswer((_) async => []);
      when(() => mockRepo.createOutfit(any()))
          .thenAnswer((_) async => _fakeOutfit());

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await container.read(outfitNotifierProvider.future);

      when(() => mockRepo.getOutfits()).thenAnswer((_) async => [_fakeOutfit()]);

      await container.read(outfitNotifierProvider.notifier).createOutfit(
            name: 'Minimal',
            itemIds: [],
          );

      final captured =
          verify(() => mockRepo.createOutfit(captureAny())).captured;
      final payload = captured.first as Map<String, dynamic>;

      expect(payload.containsKey('description'), isFalse);
      expect(payload.containsKey('season'), isFalse);
      expect(payload.containsKey('occasion'), isFalse);
    });

    test('propagates exception from repository', () async {
      when(() => mockRepo.getOutfits()).thenAnswer((_) async => []);
      when(() => mockRepo.createOutfit(any())).thenThrow(Exception('create failed'));

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await container.read(outfitNotifierProvider.future);

      await expectLater(
        container.read(outfitNotifierProvider.notifier).createOutfit(
              name: 'X',
              itemIds: [],
            ),
        throwsA(isA<Exception>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // deleteOutfit()
  // -------------------------------------------------------------------------
  group('OutfitNotifier.deleteOutfit', () {
    test('deletes outfit and refreshes list', () async {
      final o1 = _fakeOutfit(id: 'o1');
      final o2 = _fakeOutfit(id: 'o2');

      when(() => mockRepo.getOutfits()).thenAnswer((_) async => [o1, o2]);
      when(() => mockRepo.deleteOutfit('o1')).thenAnswer((_) async {});

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await container.read(outfitNotifierProvider.future);

      when(() => mockRepo.getOutfits()).thenAnswer((_) async => [o2]);

      await container.read(outfitNotifierProvider.notifier).deleteOutfit('o1');

      expect(container.read(outfitNotifierProvider).value!.length, 1);
      expect(container.read(outfitNotifierProvider).value!.first.id, 'o2');
    });

    test('propagates exception from repository', () async {
      when(() => mockRepo.getOutfits()).thenAnswer((_) async => [_fakeOutfit()]);
      when(() => mockRepo.deleteOutfit(any())).thenThrow(Exception('delete failed'));

      final container = _makeContainer(repo: mockRepo);
      addTearDown(container.dispose);

      await container.read(outfitNotifierProvider.future);

      await expectLater(
        container.read(outfitNotifierProvider.notifier).deleteOutfit('outfit-1'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
