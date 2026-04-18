import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/ai_scan/data/ai_scan_repository.dart';
import 'package:vaulted/features/ai_scan/data/ai_scan_remote_data_source.dart';
import 'package:vaulted/features/ai_scan/data/models/ai_scan_result_model.dart';
import 'package:vaulted/features/media/data/media_repository.dart';

class MockAiScanRemoteDataSource extends Mock implements AiScanRemoteDataSource {}

class MockMediaRepository extends Mock implements MediaRepository {}

void main() {
  late MockAiScanRemoteDataSource mockRemote;
  late MockMediaRepository mockMedia;
  late AiScanRepository repository;

  setUp(() {
    mockRemote = MockAiScanRemoteDataSource();
    mockMedia = MockMediaRepository();
    repository = AiScanRepository(mockRemote, mockMedia);
  });

  test('uploads product photo only and merges capturedPhotoUrls', () async {
    final product = XFile('/tmp/product.jpg');
    when(() => mockMedia.uploadPhoto(product)).thenAnswer((_) async => 'https://cdn/p1.jpg');
    when(
      () => mockRemote.analyzeItem(
        productImageUrl: any(named: 'productImageUrl'),
        invoiceImageUrl: any(named: 'invoiceImageUrl'),
        propertyRooms: any(named: 'propertyRooms'),
      ),
    ).thenAnswer(
      (_) async => const AiScanResult(name: 'Lamp', category: 'furniture'),
    );

    final result = await repository.analyzeItem(
      productPhoto: product,
      invoicePhoto: null,
      propertyRooms: const [
        {'floorId': 'f1', 'roomId': 'r1', 'label': 'Living'},
      ],
    );

    expect(result.name, 'Lamp');
    expect(result.capturedPhotoUrls, ['https://cdn/p1.jpg']);
    verify(() => mockMedia.uploadPhoto(product)).called(1);
    verify(
      () => mockRemote.analyzeItem(
        productImageUrl: 'https://cdn/p1.jpg',
        invoiceImageUrl: null,
        propertyRooms: const [
          {'floorId': 'f1', 'roomId': 'r1', 'label': 'Living'},
        ],
      ),
    ).called(1);
  });

  test('uploads invoice when provided and preserves remote fields', () async {
    final product = XFile('/tmp/p.jpg');
    final invoice = XFile('/tmp/i.jpg');
    when(() => mockMedia.uploadPhoto(product)).thenAnswer((_) async => 'u1');
    when(() => mockMedia.uploadPhoto(invoice)).thenAnswer((_) async => 'u2');
    when(
      () => mockRemote.analyzeItem(
        productImageUrl: any(named: 'productImageUrl'),
        invoiceImageUrl: any(named: 'invoiceImageUrl'),
        propertyRooms: any(named: 'propertyRooms'),
      ),
    ).thenAnswer(
      (_) async => const AiScanResult(
        name: 'Vase',
        category: 'art',
        tags: ['fragile'],
      ),
    );

    final result = await repository.analyzeItem(
      productPhoto: product,
      invoicePhoto: invoice,
      propertyRooms: const [],
    );

    expect(result.tags, ['fragile']);
    expect(result.capturedPhotoUrls, ['u1', 'u2']);
    verifyInOrder([
      () => mockMedia.uploadPhoto(product),
      () => mockMedia.uploadPhoto(invoice),
    ]);
  });

  test('propagates upload failures', () async {
    final product = XFile('/tmp/p.jpg');
    when(() => mockMedia.uploadPhoto(product)).thenThrow(Exception('upload failed'));

    expect(
      () => repository.analyzeItem(
        productPhoto: product,
        propertyRooms: const [],
      ),
      throwsA(isA<Exception>()),
    );

    verifyNever(() => mockRemote.analyzeItem(
          productImageUrl: any(named: 'productImageUrl'),
          invoiceImageUrl: any(named: 'invoiceImageUrl'),
          propertyRooms: any(named: 'propertyRooms'),
        ));
  });
}
