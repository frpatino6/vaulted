import 'package:image_picker/image_picker.dart';

import '../../media/data/media_repository.dart';
import 'ai_scan_remote_data_source.dart';
import 'models/ai_scan_result_model.dart';

class AiScanRepository {
  AiScanRepository(this._remote, this._mediaRepository);

  final AiScanRemoteDataSource _remote;
  final MediaRepository _mediaRepository;

  /// Uploads images then calls the vision endpoint.
  /// Returns the full AiScanResult with capturedPhotoUrls populated.
  Future<AiScanResult> analyzeItem({
    required XFile productPhoto,
    XFile? invoicePhoto,
    required List<Map<String, String>> propertyRooms,
  }) async {
    // Upload product photo
    final productUrl = await _mediaRepository.uploadPhoto(productPhoto);

    // Upload invoice photo if provided
    String? invoiceUrl;
    if (invoicePhoto != null) {
      invoiceUrl = await _mediaRepository.uploadPhoto(invoicePhoto);
    }

    final result = await _remote.analyzeItem(
      productImageUrl: productUrl,
      invoiceImageUrl: invoiceUrl,
      propertyRooms: propertyRooms,
    );

    // Attach captured photo URLs to the result
    final photos = [productUrl, if (invoiceUrl != null) invoiceUrl];
    return result.copyWith(capturedPhotoUrls: photos);
  }
}
