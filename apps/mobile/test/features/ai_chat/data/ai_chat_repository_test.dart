import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/ai_chat/data/ai_chat_remote_data_source.dart';
import 'package:vaulted/features/ai_chat/data/ai_chat_repository.dart';
import 'package:vaulted/features/ai_chat/data/models/chat_message_model.dart';

class MockAiChatRemoteDataSource extends Mock implements AiChatRemoteDataSource {}

void main() {
  late MockAiChatRemoteDataSource mockRemote;
  late AiChatRepository repository;

  setUp(() {
    mockRemote = MockAiChatRemoteDataSource();
    repository = AiChatRepository(mockRemote);
  });

  group('AiChatRepository.sendMessage', () {
    test('delegates to remote and returns record', () async {
      final items = <ChatItemResult>[
        const ChatItemResult(
          id: '1',
          name: 'Watch',
          category: 'jewelry',
          status: 'active',
        ),
      ];
      when(
        () => mockRemote.sendMessage(
          query: any(named: 'query'),
          sessionId: any(named: 'sessionId'),
          propertyId: any(named: 'propertyId'),
        ),
      ).thenAnswer(
        (_) async => (
          answer: 'hello',
          items: items,
          sessionId: 'sess-1',
          sources: <String>['s1'],
        ),
      );

      final result = await repository.sendMessage(
        query: 'find watch',
        sessionId: 'sess-0',
        propertyId: 'prop-1',
      );

      expect(result.answer, 'hello');
      expect(result.items, items);
      expect(result.sessionId, 'sess-1');
      expect(result.sources, ['s1']);
      verify(
        () => mockRemote.sendMessage(
          query: 'find watch',
          sessionId: 'sess-0',
          propertyId: 'prop-1',
        ),
      ).called(1);
    });

    test('propagates remote errors', () async {
      when(
        () => mockRemote.sendMessage(
          query: any(named: 'query'),
          sessionId: any(named: 'sessionId'),
          propertyId: any(named: 'propertyId'),
        ),
      ).thenThrow(Exception('network'));

      expect(
        () => repository.sendMessage(query: 'q'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('AiChatRepository.reindex', () {
    test('delegates to remote', () async {
      when(() => mockRemote.reindex()).thenAnswer((_) async {});

      await repository.reindex();

      verify(() => mockRemote.reindex()).called(1);
    });

    test('propagates remote errors', () async {
      when(() => mockRemote.reindex()).thenThrow(Exception('fail'));

      expect(() => repository.reindex(), throwsA(isA<Exception>()));
    });
  });
}
