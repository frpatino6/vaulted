import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/inventory/data/item_remote_data_source.dart';
import 'package:vaulted/features/inventory/data/item_repository.dart';
import 'package:vaulted/features/inventory/data/models/item_model.dart';

class MockItemRemoteDataSource extends Mock implements ItemRemoteDataSource {}

void main() {
  late MockItemRemoteDataSource mockRemote;
  late ItemRepository repository;

  setUp(() {
    mockRemote = MockItemRemoteDataSource();
    repository = ItemRepository(mockRemote);
  });

  test('getItems forwards query params', () async {
    when(
      () => mockRemote.getItems(
        propertyId: any(named: 'propertyId'),
        roomId: any(named: 'roomId'),
        category: any(named: 'category'),
        status: any(named: 'status'),
        unlocated: any(named: 'unlocated'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => const []);

    await repository.getItems(
      propertyId: 'p',
      roomId: 'r',
      category: 'art',
      status: 'active',
      unlocated: true,
      limit: 20,
    );

    verify(
      () => mockRemote.getItems(
        propertyId: 'p',
        roomId: 'r',
        category: 'art',
        status: 'active',
        unlocated: true,
        limit: 20,
      ),
    ).called(1);
  });

  test('createItem builds expected body and omits empty optional strings', () async {
    const created = ItemModel(id: 'new', name: 'Vase', category: 'art');
    when(() => mockRemote.createItem(any())).thenAnswer((_) async => created);

    await repository.createItem(
      propertyId: 'p1',
      roomId: '',
      name: 'Vase',
      category: 'art',
      subcategory: '',
      serialNumber: '',
      locationDetail: '',
    );

    final body = verify(() => mockRemote.createItem(captureAny()))
        .captured
        .single as Map<String, dynamic>;

    expect(body['propertyId'], 'p1');
    expect(body.containsKey('roomId'), isFalse);
    expect(body.containsKey('serialNumber'), isFalse);
    expect(body.containsKey('locationDetail'), isFalse);
    expect(body['valuation'], isA<Map<String, dynamic>>());
  });

  test('createItem includes attributes when provided', () async {
    when(() => mockRemote.createItem(any())).thenAnswer(
      (_) async => const ItemModel(id: '1', name: 'W', category: 'wardrobe'),
    );

    await repository.createItem(
      propertyId: 'p',
      name: 'W',
      category: 'wardrobe',
      attributes: {'color': 'blue'},
    );

    final body = verify(() => mockRemote.createItem(captureAny()))
        .captured
        .single as Map<String, dynamic>;
    expect(body['attributes'], {'color': 'blue'});
  });

  test('updateItem only sends provided keys', () async {
    when(() => mockRemote.updateItem('id', any())).thenAnswer(
      (_) async => const ItemModel(id: 'id', name: 'N', category: 'art'),
    );

    await repository.updateItem('id', name: 'N');

    final body = verify(() => mockRemote.updateItem('id', captureAny()))
        .captured
        .single as Map<String, dynamic>;
    expect(body, {'name': 'N'});
  });

  test('assignLocation uses updateItem with roomId', () async {
    when(() => mockRemote.updateItem('id', any())).thenAnswer(
      (_) async => const ItemModel(id: 'id', name: 'N', category: 'art'),
    );

    await repository.assignLocation('id', roomId: 'room-9');

    verify(() => mockRemote.updateItem('id', {'roomId': 'room-9'})).called(1);
  });

  test('deleteItem and getItemHistory delegate', () async {
    when(() => mockRemote.deleteItem('1')).thenAnswer((_) async {});
    when(() => mockRemote.getItemHistory('1')).thenAnswer((_) async => []);

    await repository.deleteItem('1');
    await repository.getItemHistory('1');

    verify(() => mockRemote.deleteItem('1')).called(1);
    verify(() => mockRemote.getItemHistory('1')).called(1);
  });
}
