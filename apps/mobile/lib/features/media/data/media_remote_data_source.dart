import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class MediaRemoteDataSource {
  MediaRemoteDataSource(this._dio);

  final Dio _dio;

  /// POST /media/upload with multipart/form-data, field name "file".
  /// Returns the CDN URL from response data.url.
  Future<String> uploadPhoto(XFile file) async {
    final filename = file.name.isNotEmpty ? file.name : 'photo.jpg';
    final MultipartFile multipart;

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      multipart = MultipartFile.fromBytes(bytes, filename: filename);
    } else {
      multipart = await MultipartFile.fromFile(file.path, filename: filename);
    }

    final formData = FormData.fromMap({'file': multipart});
    final response = await _dio.post<Map<String, dynamic>>(
      'media/upload',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final data = response.data;
    if (data == null || data['success'] != true) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: data?['error'] ?? 'Upload failed',
      );
    }
    final inner = data['data'];
    if (inner is! Map<String, dynamic> || inner['url'] == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Invalid upload response',
      );
    }
    return inner['url'] as String;
  }
}
