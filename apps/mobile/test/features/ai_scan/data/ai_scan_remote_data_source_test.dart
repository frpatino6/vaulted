import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/ai_scan/data/ai_scan_remote_data_source.dart';

import '../../../support/dio_test_support.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late AiScanRemoteDataSource dataSource;
  late RequestOptions requestOptions;

  setUp(() {
    mockDio = MockDio();
    dataSource = AiScanRemoteDataSource(mockDio);
    requestOptions = RequestOptions(path: '/test');
  });

  test('posts body with optional invoice and propertyRooms', () async {
    when(
      () => mockDio.post<Map<String, dynamic>>(
        'ai/vision/analyze',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {
          'success': true,
          'data': {
            'name': 'Desk',
            'category': 'furniture',
            'confidence': 0.9,
            'tags': ['wood'],
          },
        },
      ),
    );

    final result = await dataSource.analyzeItem(
      productImageUrl: 'https://img/p.jpg',
      invoiceImageUrl: 'https://img/i.jpg',
      propertyRooms: const [
        {'id': 'r1', 'name': 'Office'},
      ],
    );

    expect(result.name, 'Desk');
    expect(result.category, 'furniture');
    expect(result.confidence, 0.9);
    expect(result.tags, ['wood']);

    final body = verify(
      () => mockDio.post<Map<String, dynamic>>(
        'ai/vision/analyze',
        data: captureAny(named: 'data'),
      ),
    ).captured.single as Map<String, dynamic>;

    expect(body['productImageUrl'], 'https://img/p.jpg');
    expect(body['invoiceImageUrl'], 'https://img/i.jpg');
    expect(body['propertyRooms'], isA<List>());
  });

  test('omits invoiceImageUrl and propertyRooms when not needed', () async {
    when(
      () => mockDio.post<Map<String, dynamic>>(
        'ai/vision/analyze',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {
          'success': true,
          'data': {'name': 'X', 'category': 'other'},
        },
      ),
    );

    await dataSource.analyzeItem(
      productImageUrl: 'u',
      propertyRooms: const [],
    );

    final body = verify(
      () => mockDio.post<Map<String, dynamic>>(
        'ai/vision/analyze',
        data: captureAny(named: 'data'),
      ),
    ).captured.single as Map<String, dynamic>;

    expect(body.keys.toSet(), {'productImageUrl'});
  });

  test('throws DioException on API error envelope', () async {
    when(
      () => mockDio.post<Map<String, dynamic>>(
        'ai/vision/analyze',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => makeMapResponse(
        requestOptions: requestOptions,
        data: {'success': false, 'error': {'message': 'vision down'}},
        statusCode: 500,
      ),
    );

    expect(
      () => dataSource.analyzeItem(
        productImageUrl: 'u',
        propertyRooms: const [],
      ),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.badResponse,
        ),
      ),
    );
  });

  test('throws DioException when data is null', () async {
    when(
      () => mockDio.post<Map<String, dynamic>>(
        'ai/vision/analyze',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: requestOptions,
        data: null,
        statusCode: 200,
      ),
    );

    expect(
      () => dataSource.analyzeItem(
        productImageUrl: 'u',
        propertyRooms: const [],
      ),
      throwsA(isA<DioException>()),
    );
  });
}
