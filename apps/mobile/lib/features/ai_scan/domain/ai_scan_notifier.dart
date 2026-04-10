import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/ai_scan_providers.dart';
import 'ai_scan_state.dart';

class AiScanNotifier extends StateNotifier<AiScanState> {
  AiScanNotifier(this._ref) : super(const AiScanCaptureProduct());

  final Ref _ref;

  void onProductPhotoCaptured(XFile photo) {
    state = AiScanCaptureInvoice(productPhoto: photo);
  }

  Future<void> onInvoicePhotoCaptured(
    XFile invoicePhoto, {
    required List<Map<String, String>> propertyRooms,
  }) async {
    final current = state;
    if (current is! AiScanCaptureInvoice) return;
    await _analyze(
      productPhoto: current.productPhoto,
      invoicePhoto: invoicePhoto,
      propertyRooms: propertyRooms,
    );
  }

  Future<void> skipInvoice({
    required List<Map<String, String>> propertyRooms,
  }) async {
    final current = state;
    if (current is! AiScanCaptureInvoice) return;
    await _analyze(
      productPhoto: current.productPhoto,
      invoicePhoto: null,
      propertyRooms: propertyRooms,
    );
  }

  Future<void> _analyze({
    required XFile productPhoto,
    required XFile? invoicePhoto,
    required List<Map<String, String>> propertyRooms,
  }) async {
    state = AiScanAnalyzing(
      productPhoto: productPhoto,
      invoicePhoto: invoicePhoto,
    );
    try {
      final repo = _ref.read(aiScanRepositoryProvider);
      final result = await repo.analyzeItem(
        productPhoto: productPhoto,
        invoicePhoto: invoicePhoto,
        propertyRooms: propertyRooms,
      );
      state = AiScanResultState(result: result);
    } catch (e) {
      state = AiScanError(message: e.toString());
    }
  }

  void reset() => state = const AiScanCaptureProduct();
}

final aiScanNotifierProvider =
    StateNotifierProvider.autoDispose<AiScanNotifier, AiScanState>(
  (ref) => AiScanNotifier(ref),
);
