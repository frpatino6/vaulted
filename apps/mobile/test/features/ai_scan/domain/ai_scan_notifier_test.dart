import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/ai_scan/data/ai_scan_providers.dart';
import 'package:vaulted/features/ai_scan/data/ai_scan_repository.dart';
import 'package:vaulted/features/ai_scan/data/models/ai_scan_result_model.dart';
import 'package:vaulted/features/ai_scan/domain/ai_scan_notifier.dart';
import 'package:vaulted/features/ai_scan/domain/ai_scan_state.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockAiScanRepository extends Mock implements AiScanRepository {}


// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

AiScanResult _fakeResult() {
  return const AiScanResult(
    name: 'Vintage Armchair',
    category: 'furniture',
    subcategory: 'seating',
    confidence: 0.92,
  );
}

ProviderContainer _makeContainer({required MockAiScanRepository repo}) {
  return ProviderContainer(
    overrides: [
      aiScanRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockAiScanRepository mockRepo;
  late XFile mockProductPhoto;
  late XFile mockInvoicePhoto;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(XFile('fallback.jpg'));
    registerFallbackValue(<Map<String, String>>[]);
  });

  setUp(() {
    mockRepo = MockAiScanRepository();
    mockProductPhoto = XFile('test_product_photo.jpg');
    mockInvoicePhoto = XFile('test_invoice_photo.jpg');
    container = _makeContainer(repo: mockRepo);
  });

  tearDown(() {
    container.dispose();
  });

  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------
  group('AiScanNotifier — initial state', () {
    test('starts in AiScanCaptureProduct state', () {
      final state = container.read(aiScanNotifierProvider);
      expect(state, isA<AiScanCaptureProduct>());
    });
  });

  // -------------------------------------------------------------------------
  // onProductPhotoCaptured()
  // -------------------------------------------------------------------------
  group('AiScanNotifier.onProductPhotoCaptured', () {
    test('transitions to AiScanCaptureInvoice with product photo', () {
      container
          .read(aiScanNotifierProvider.notifier)
          .onProductPhotoCaptured(mockProductPhoto);

      final state = container.read(aiScanNotifierProvider);
      expect(state, isA<AiScanCaptureInvoice>());
      expect((state as AiScanCaptureInvoice).productPhoto, mockProductPhoto);
    });
  });

  // -------------------------------------------------------------------------
  // onInvoicePhotoCaptured()
  // -------------------------------------------------------------------------
  group('AiScanNotifier.onInvoicePhotoCaptured', () {
    test('transitions to AiScanAnalyzing then AiScanResultState on success',
        () async {
      final result = _fakeResult();
      when(
        () => mockRepo.analyzeItem(
          productPhoto: any(named: 'productPhoto'),
          invoicePhoto: any(named: 'invoicePhoto'),
          propertyRooms: any(named: 'propertyRooms'),
        ),
      ).thenAnswer((_) async => result);

      final notifier = container.read(aiScanNotifierProvider.notifier);
      notifier.onProductPhotoCaptured(mockProductPhoto);

      await notifier.onInvoicePhotoCaptured(
        mockInvoicePhoto,
        propertyRooms: const [],
      );

      final state = container.read(aiScanNotifierProvider);
      expect(state, isA<AiScanResultState>());
      expect((state as AiScanResultState).result.name, 'Vintage Armchair');
    });

    test('transitions to AiScanError on exception', () async {
      when(
        () => mockRepo.analyzeItem(
          productPhoto: any(named: 'productPhoto'),
          invoicePhoto: any(named: 'invoicePhoto'),
          propertyRooms: any(named: 'propertyRooms'),
        ),
      ).thenThrow(Exception('AI analysis failed'));

      final notifier = container.read(aiScanNotifierProvider.notifier);
      notifier.onProductPhotoCaptured(mockProductPhoto);

      await notifier.onInvoicePhotoCaptured(
        mockInvoicePhoto,
        propertyRooms: const [],
      );

      final state = container.read(aiScanNotifierProvider);
      expect(state, isA<AiScanError>());
      expect((state as AiScanError).message, contains('AI analysis failed'));
    });

    test('does nothing when current state is not AiScanCaptureInvoice', () async {
      // State starts as AiScanCaptureProduct — should be a no-op
      await container
          .read(aiScanNotifierProvider.notifier)
          .onInvoicePhotoCaptured(
            mockInvoicePhoto,
            propertyRooms: const [],
          );

      // Still in initial state
      expect(container.read(aiScanNotifierProvider), isA<AiScanCaptureProduct>());
      verifyNever(
        () => mockRepo.analyzeItem(
          productPhoto: any(named: 'productPhoto'),
          invoicePhoto: any(named: 'invoicePhoto'),
          propertyRooms: any(named: 'propertyRooms'),
        ),
      );
    });
  });

  // -------------------------------------------------------------------------
  // skipInvoice()
  // -------------------------------------------------------------------------
  group('AiScanNotifier.skipInvoice', () {
    test('transitions to AiScanResultState with null invoicePhoto on success',
        () async {
      final result = _fakeResult();
      when(
        () => mockRepo.analyzeItem(
          productPhoto: any(named: 'productPhoto'),
          invoicePhoto: null,
          propertyRooms: any(named: 'propertyRooms'),
        ),
      ).thenAnswer((_) async => result);

      final notifier = container.read(aiScanNotifierProvider.notifier);
      notifier.onProductPhotoCaptured(mockProductPhoto);

      await notifier.skipInvoice(propertyRooms: const []);

      final state = container.read(aiScanNotifierProvider);
      expect(state, isA<AiScanResultState>());

      verify(
        () => mockRepo.analyzeItem(
          productPhoto: mockProductPhoto,
          invoicePhoto: null,
          propertyRooms: const [],
        ),
      ).called(1);
    });

    test('transitions to AiScanError on exception', () async {
      when(
        () => mockRepo.analyzeItem(
          productPhoto: any(named: 'productPhoto'),
          invoicePhoto: null,
          propertyRooms: any(named: 'propertyRooms'),
        ),
      ).thenThrow(Exception('skip failed'));

      final notifier = container.read(aiScanNotifierProvider.notifier);
      notifier.onProductPhotoCaptured(mockProductPhoto);

      await notifier.skipInvoice(propertyRooms: const []);

      expect(container.read(aiScanNotifierProvider), isA<AiScanError>());
    });

    test('does nothing when current state is not AiScanCaptureInvoice', () async {
      // Start from initial state — should be a no-op
      await container.read(aiScanNotifierProvider.notifier).skipInvoice(
            propertyRooms: const [],
          );

      expect(container.read(aiScanNotifierProvider), isA<AiScanCaptureProduct>());
    });
  });

  // -------------------------------------------------------------------------
  // reset()
  // -------------------------------------------------------------------------
  group('AiScanNotifier.reset', () {
    test('returns state to AiScanCaptureProduct from any state', () async {
      final result = _fakeResult();
      when(
        () => mockRepo.analyzeItem(
          productPhoto: any(named: 'productPhoto'),
          invoicePhoto: null,
          propertyRooms: any(named: 'propertyRooms'),
        ),
      ).thenAnswer((_) async => result);

      final notifier = container.read(aiScanNotifierProvider.notifier);
      notifier.onProductPhotoCaptured(mockProductPhoto);
      await notifier.skipInvoice(propertyRooms: const []);

      expect(container.read(aiScanNotifierProvider), isA<AiScanResultState>());

      notifier.reset();

      expect(container.read(aiScanNotifierProvider), isA<AiScanCaptureProduct>());
    });

    test('reset from initial state stays in AiScanCaptureProduct', () {
      container.read(aiScanNotifierProvider.notifier).reset();
      expect(container.read(aiScanNotifierProvider), isA<AiScanCaptureProduct>());
    });

    test('reset from error state returns to AiScanCaptureProduct', () async {
      when(
        () => mockRepo.analyzeItem(
          productPhoto: any(named: 'productPhoto'),
          invoicePhoto: null,
          propertyRooms: any(named: 'propertyRooms'),
        ),
      ).thenThrow(Exception('fail'));

      final notifier = container.read(aiScanNotifierProvider.notifier);
      notifier.onProductPhotoCaptured(mockProductPhoto);
      await notifier.skipInvoice(propertyRooms: const []);

      expect(container.read(aiScanNotifierProvider), isA<AiScanError>());

      notifier.reset();

      expect(container.read(aiScanNotifierProvider), isA<AiScanCaptureProduct>());
    });
  });

  // -------------------------------------------------------------------------
  // State transition sequence
  // -------------------------------------------------------------------------
  group('AiScanNotifier — full flow (product → invoice → result)', () {
    test('complete happy path transitions correctly', () async {
      final result = _fakeResult();
      when(
        () => mockRepo.analyzeItem(
          productPhoto: any(named: 'productPhoto'),
          invoicePhoto: any(named: 'invoicePhoto'),
          propertyRooms: any(named: 'propertyRooms'),
        ),
      ).thenAnswer((_) async => result);

      final notifier = container.read(aiScanNotifierProvider.notifier);

      // 1. Start
      expect(container.read(aiScanNotifierProvider), isA<AiScanCaptureProduct>());

      // 2. Capture product photo
      notifier.onProductPhotoCaptured(mockProductPhoto);
      expect(container.read(aiScanNotifierProvider), isA<AiScanCaptureInvoice>());

      // 3. Capture invoice photo → analyze
      await notifier.onInvoicePhotoCaptured(
        mockInvoicePhoto,
        propertyRooms: const [
          {'propertyId': 'prop-1', 'roomId': 'room-1', 'name': 'Living Room'},
        ],
      );
      expect(container.read(aiScanNotifierProvider), isA<AiScanResultState>());

      // 4. Reset
      notifier.reset();
      expect(container.read(aiScanNotifierProvider), isA<AiScanCaptureProduct>());
    });
  });
}
