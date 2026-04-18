import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/ai_chat/data/ai_chat_remote_data_source.dart';
import 'package:vaulted/features/ai_chat/data/models/chat_message_model.dart';

import '../../../support/dio_test_support.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late AiChatRemoteDataSource dataSource;
  late RequestOptions requestOptions;

  setUp(() {
    mockDio = MockDio();
    dataSource = AiChatRemoteDataSource(mockDio);
    requestOptions = RequestOptions(path: '/test');
  });

  group('AiChatRemoteDataSource.sendMessage', () {
    test('unwraps success payload and parses items with _id normalization', () async {
      final response = makeMapResponse(
        requestOptions: requestOptions,
        data: {
          'success': true,
          'data': {
            'answer': 'Found one item.',
            'sessionId': 'abc',
            'sources': ['doc1'],
            'items': [
              {
                '_id': 42,
                'name': 'Chair',
                'category': 'furniture',
                'status': 'active',
              },
            ],
          },
        },
      );

      when(
        () => mockDio.post<Map<String, dynamic>>(
          'ai/chat',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      final result = await dataSource.sendMessage(query: 'chair');

      expect(result.answer, 'Found one item.');
      expect(result.sessionId, 'abc');
      expect(result.sources, ['doc1']);
      expect(result.items, hasLength(1));
      expect(result.items.single.id, '42');
      expect(result.items.single.name, 'Chair');

      final captured = verify(
        () => mockDio.post<Map<String, dynamic>>(
          'ai/chat',
          data: captureAny(named: 'data'),
        ),
      ).captured;
      final body = captured.single as Map<String, dynamic>;
      expect(body['query'], 'chair');
      expect(body.containsKey('sessionId'), isFalse);
    });

    test('omits null sessionId and propertyId from body', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          'ai/chat',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => makeMapResponse(
          requestOptions: requestOptions,
          data: {
            'success': true,
            'data': {
              'answer': '',
              'sessionId': '',
              'sources': <String>[],
              'items': <dynamic>[],
            },
          },
        ),
      );

      await dataSource.sendMessage(
        query: 'q',
        sessionId: null,
        propertyId: null,
      );

      final body = verify(
        () => mockDio.post<Map<String, dynamic>>(
          'ai/chat',
          data: captureAny(named: 'data'),
        ),
      ).captured.single as Map<String, dynamic>;

      expect(body.keys.toSet(), {'query'});
    });

    test('throws DioException when success is false', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          'ai/chat',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => makeMapResponse(
          requestOptions: requestOptions,
          data: {
            'success': false,
            'error': {'message': 'bad request'},
          },
          statusCode: 400,
        ),
      );

      expect(
        () => dataSource.sendMessage(query: 'x'),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.badResponse,
          ),
        ),
      );
    });

    test('throws DioException when response data is null', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          'ai/chat',
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
        () => dataSource.sendMessage(query: 'x'),
        throwsA(isA<DioException>()),
      );
    });

    test('propagates DioException from transport layer', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          'ai/chat',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => dataSource.sendMessage(query: 'x'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('AiChatRemoteDataSource.chatItemToItemModel', () {
    test('maps chat item fields and valuation', () {
      const item = ChatItemResult(
        id: '1',
        name: 'Ring',
        category: 'jewelry',
        status: 'active',
        photos: ['a.jpg'],
        valuation: ChatItemValuation(currentValue: 5000, currency: 'USD'),
      );

      final model = AiChatRemoteDataSource.chatItemToItemModel(item);

      expect(model.id, '1');
      expect(model.name, 'Ring');
      expect(model.category, 'jewelry');
      expect(model.status, 'active');
      expect(model.photos, ['a.jpg']);
      expect(model.valuation?.currentValue, 5000);
      expect(model.valuation?.currency, 'USD');
    });

    test('uses null valuation when chat item has none', () {
      const item = ChatItemResult(
        id: '2',
        name: 'Box',
        category: 'furniture',
        status: 'active',
      );

      final model = AiChatRemoteDataSource.chatItemToItemModel(item);

      expect(model.valuation, isNull);
    });
  });

  group('AiChatRemoteDataSource.reindex', () {
    test('calls POST ai/chat/reindex', () async {
      when(
        () => mockDio.post<void>('ai/chat/reindex'),
      ).thenAnswer(
        (_) async => Response<void>(
          requestOptions: requestOptions,
          statusCode: 202,
        ),
      );

      await dataSource.reindex();

      verify(() => mockDio.post<void>('ai/chat/reindex')).called(1);
    });
  });
}
