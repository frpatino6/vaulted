import 'package:image_picker/image_picker.dart';

import '../data/models/ai_scan_result_model.dart';

sealed class AiScanState {
  const AiScanState();
}

class AiScanCaptureProduct extends AiScanState {
  const AiScanCaptureProduct();
}

class AiScanCaptureInvoice extends AiScanState {
  const AiScanCaptureInvoice({required this.productPhoto});
  final XFile productPhoto;
}

class AiScanAnalyzing extends AiScanState {
  const AiScanAnalyzing({required this.productPhoto, this.invoicePhoto});
  final XFile productPhoto;
  final XFile? invoicePhoto;
}

class AiScanResultState extends AiScanState {
  const AiScanResultState({required this.result});
  final AiScanResult result;
}

class AiScanError extends AiScanState {
  const AiScanError({required this.message});
  final String message;
}
