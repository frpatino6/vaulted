import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/ai_chat/data/ai_chat_repository.dart';
import 'package:vaulted/features/ai_chat/data/ai_chat_repository_provider.dart';
import 'package:vaulted/features/ai_chat/data/models/chat_message_model.dart';
import 'package:vaulted/features/ai_chat/domain/ai_chat_notifier.dart';
import 'package:vaulted/features/ai_chat/domain/ai_chat_state.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockAiChatRepository extends Mock implements AiChatRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

typedef ChatResult = ({
  String answer,
  List<ChatItemResult> items,
  String sessionId,
  List<String> sources,
});

ChatResult _fakeChatResult({
  String answer = 'Here is your answer.',
  String sessionId = 'session-abc',
}) {
  return (
    answer: answer,
    items: const <ChatItemResult>[],
    sessionId: sessionId,
    sources: const <String>[],
  );
}

ProviderContainer _makeContainer({required MockAiChatRepository repo}) {
  return ProviderContainer(
    overrides: [
      aiChatRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockAiChatRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockAiChatRepository();
    container = _makeContainer(repo: mockRepo);
  });

  tearDown(() {
    container.dispose();
  });

  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------
  group('AiChatNotifier — initial state', () {
    test('starts with empty AiChatState', () {
      final state = container.read(aiChatNotifierProvider);
      expect(state.messages, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.sessionId, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // sendMessage()
  // -------------------------------------------------------------------------
  group('AiChatNotifier.sendMessage', () {
    test('adds user message during loading (observable via listener)', () async {
      // Observe state transitions during sendMessage
      when(
        () => mockRepo.sendMessage(
          query: any(named: 'query'),
          sessionId: any(named: 'sessionId'),
          propertyId: any(named: 'propertyId'),
        ),
      ).thenAnswer((_) async => _fakeChatResult());

      final states = <AiChatState>[];
      container.listen(
        aiChatNotifierProvider,
        (_, next) => states.add(next),
        fireImmediately: false,
      );

      await container
          .read(aiChatNotifierProvider.notifier)
          .sendMessage('Hello');

      // First transition: isLoading=true with 2 messages (user + loading assistant)
      final loadingState = states.firstWhere((s) => s.isLoading);
      expect(loadingState.messages.length, 2);
      expect(loadingState.messages[0].role, ChatRole.user);
      expect(loadingState.messages[0].content, 'Hello');
      expect(loadingState.messages[1].role, ChatRole.assistant);
      expect(loadingState.messages[1].isLoading, isTrue);
    });

    test('replaces loading message with assistant response on success', () async {
      final result = _fakeChatResult(
        answer: 'AI answer here',
        sessionId: 'sess-1',
      );
      when(
        () => mockRepo.sendMessage(
          query: any(named: 'query'),
          sessionId: any(named: 'sessionId'),
          propertyId: any(named: 'propertyId'),
        ),
      ).thenAnswer((_) async => result);

      await container
          .read(aiChatNotifierProvider.notifier)
          .sendMessage('Tell me about my items');

      final state = container.read(aiChatNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.sessionId, 'sess-1');

      // Should have: user message + assistant response
      expect(state.messages.length, 2);
      final assistantMsg = state.messages.last;
      expect(assistantMsg.content, 'AI answer here');
      expect(assistantMsg.isLoading, isFalse);
    });

    test('carries session ID across consecutive messages', () async {
      when(
        () => mockRepo.sendMessage(
          query: any(named: 'query'),
          sessionId: any(named: 'sessionId'),
          propertyId: any(named: 'propertyId'),
        ),
      ).thenAnswer((_) async => _fakeChatResult(sessionId: 'sess-42'));

      final notifier = container.read(aiChatNotifierProvider.notifier);
      await notifier.sendMessage('First message');

      // Verify the second call passes the accumulated sessionId
      await notifier.sendMessage('Second message');

      final calls = verify(
        () => mockRepo.sendMessage(
          query: any(named: 'query'),
          sessionId: captureAny(named: 'sessionId'),
          propertyId: any(named: 'propertyId'),
        ),
      ).captured;

      // First call: sessionId is null (no session yet)
      expect(calls[0], isNull);
      // Second call: sessionId is 'sess-42' from first response
      expect(calls[1], 'sess-42');
    });

    test('removes loading message and sets error on exception', () async {
      when(
        () => mockRepo.sendMessage(
          query: any(named: 'query'),
          sessionId: any(named: 'sessionId'),
          propertyId: any(named: 'propertyId'),
        ),
      ).thenThrow(Exception('AI service unavailable'));

      await container
          .read(aiChatNotifierProvider.notifier)
          .sendMessage('test');

      final state = container.read(aiChatNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
      // Loading message removed, only user message remains
      expect(state.messages.length, 1);
      expect(state.messages.first.role, ChatRole.user);
    });

    test('returns rate-limit error for 429 DioException', () async {
      when(
        () => mockRepo.sendMessage(
          query: any(named: 'query'),
          sessionId: any(named: 'sessionId'),
          propertyId: any(named: 'propertyId'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/ai/chat'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/ai/chat'),
            statusCode: 429,
          ),
        ),
      );

      await container.read(aiChatNotifierProvider.notifier).sendMessage('hi');

      final state = container.read(aiChatNotifierProvider);
      expect(state.error, contains('Rate limit reached'));
    });

    test('extracts error message from DioException response body', () async {
      when(
        () => mockRepo.sendMessage(
          query: any(named: 'query'),
          sessionId: any(named: 'sessionId'),
          propertyId: any(named: 'propertyId'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/ai/chat'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/ai/chat'),
            statusCode: 422,
            data: {
              'error': {'message': 'Query too long'},
            },
          ),
        ),
      );

      await container.read(aiChatNotifierProvider.notifier).sendMessage('hi');

      expect(container.read(aiChatNotifierProvider).error, 'Query too long');
    });

    test('clears previous error on next sendMessage', () async {
      when(
        () => mockRepo.sendMessage(
          query: any(named: 'query'),
          sessionId: any(named: 'sessionId'),
          propertyId: any(named: 'propertyId'),
        ),
      ).thenThrow(Exception('first error'));

      await container.read(aiChatNotifierProvider.notifier).sendMessage('msg1');

      expect(container.read(aiChatNotifierProvider).error, isNotNull);

      when(
        () => mockRepo.sendMessage(
          query: any(named: 'query'),
          sessionId: any(named: 'sessionId'),
          propertyId: any(named: 'propertyId'),
        ),
      ).thenAnswer((_) async => _fakeChatResult());

      await container.read(aiChatNotifierProvider.notifier).sendMessage('msg2');

      expect(container.read(aiChatNotifierProvider).error, isNull);
    });

    test('passes propertyId to repository when provided', () async {
      when(
        () => mockRepo.sendMessage(
          query: 'search my items',
          sessionId: null,
          propertyId: 'prop-1',
        ),
      ).thenAnswer((_) async => _fakeChatResult());

      await container
          .read(aiChatNotifierProvider.notifier)
          .sendMessage('search my items', propertyId: 'prop-1');

      verify(
        () => mockRepo.sendMessage(
          query: 'search my items',
          sessionId: null,
          propertyId: 'prop-1',
        ),
      ).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // clearSession()
  // -------------------------------------------------------------------------
  group('AiChatNotifier.clearSession', () {
    test('resets state to initial AiChatState', () async {
      when(
        () => mockRepo.sendMessage(
          query: any(named: 'query'),
          sessionId: any(named: 'sessionId'),
          propertyId: any(named: 'propertyId'),
        ),
      ).thenAnswer((_) async => _fakeChatResult(sessionId: 'sess-1'));

      await container
          .read(aiChatNotifierProvider.notifier)
          .sendMessage('hello');

      container.read(aiChatNotifierProvider.notifier).clearSession();

      final state = container.read(aiChatNotifierProvider);
      expect(state.messages, isEmpty);
      expect(state.sessionId, isNull);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });
  });
}

