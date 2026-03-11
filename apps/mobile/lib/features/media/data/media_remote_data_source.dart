import 'dart:io';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class MediaRemoteDataSource {
  MediaRemoteDataSource(this._dio);

  final Dio _dio;

  /// POST /media/upload with multipart/form-data, field name "file".
  /// Returns the CDN URL from response data.url.
  Future<String> uploadPhoto(XFile file) async {
    final path = file.path;
    if (path.isEmpty) {
      throw DioException(
        requestOptions: RequestOptions(path: 'media/upload'),
        error: 'Invalid file path',
      );
    }
    final filename = file.name.isNotEmpty ? file.name : path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(path, filename: filename),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      'media/upload',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
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
