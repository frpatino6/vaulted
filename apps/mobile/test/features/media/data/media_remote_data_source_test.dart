import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/media/data/media_remote_data_source.dart';

import '../../../support/dio_test_support.dart';

class MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() {
    registerFallbackValue(Options());
  });

  late MockDio mockDio;
  late MediaRemoteDataSource dataSource;
  late RequestOptions requestOptions;
  late File tempFile;

  setUp(() async {
    mockDio = MockDio();
    dataSource = MediaRemoteDataSource(mockDio);
    requestOptions = RequestOptions(path: '/test');
    tempFile = File('${Directory.systemTemp.path}/vaulted_media_test.jpg');
    await tempFile.writeAsBytes([1, 2, 3]);
  });

  tearDown(() async {
    if (tempFile.existsSync()) {
      await tempFile.delete();
    }
  });

  test('uploads multipart file and returns url', () async {
    final xfile = XFile(tempFile.path);
    when(
      () => mockDio.post<Map<String, dynamic>>(
        'media/upload',
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {
          'success': true,
          'data': {'url': 'https://cdn/file.jpg'},
        },
      ),
    );

    final url = await dataSource.uploadPhoto(xfile);

    expect(url, 'https://cdn/file.jpg');
    verify(
      () => mockDio.post<Map<String, dynamic>>(
        'media/upload',
        data: captureAny(named: 'data'),
        options: captureAny(named: 'options'),
      ),
    ).called(1);
  });

  test('throws when success flag is false', () async {
    final xfile = XFile(tempFile.path);
    when(
      () => mockDio.post<Map<String, dynamic>>(
        'media/upload',
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': false, 'error': 'quota'},
      ),
    );

    expect(
      () => dataSource.uploadPhoto(xfile),
      throwsA(isA<DioException>()),
    );
  });

  test('throws when inner url missing', () async {
    final xfile = XFile(tempFile.path);
    when(
      () => mockDio.post<Map<String, dynamic>>(
        'media/upload',
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': true, 'data': <String, dynamic>{}},
      ),
    );

    expect(
      () => dataSource.uploadPhoto(xfile),
      throwsA(isA<DioException>()),
    );
  });
}
