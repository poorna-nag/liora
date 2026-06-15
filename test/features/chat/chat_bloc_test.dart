import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liora/core/error/failures.dart';
import 'package:liora/features/chat/data/models/chat_message.dart';
import 'package:liora/features/chat/data/models/chat_role.dart';
import 'package:liora/features/chat/data/repositories/chat_repository.dart';
import 'package:liora/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:liora/features/history/data/models/conversation.dart';
import 'package:mocktail/mocktail.dart';

class MockChatRepository extends Mock implements ChatRepository {}

ChatMessage _msg(String id, ChatRole role, String content) => ChatMessage(
      id: id,
      conversationId: 'c1',
      role: role,
      content: content,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  late MockChatRepository repository;

  final conversation = Conversation(
    id: 'c1',
    title: 'New chat',
    kind: ConversationKind.chat,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(ConversationKind.chat);
  });

  setUp(() {
    repository = MockChatRepository();
    when(() => repository.startConversation(
          kind: any(named: 'kind'),
          title: any(named: 'title'),
        )).thenAnswer((_) async => conversation);
  });

  group('ChatBloc', () {
    blocTest<ChatBloc, ChatState>(
      'starts a new conversation when none provided',
      build: () {
        when(() => repository.loadMessages('c1')).thenReturn([]);
        return ChatBloc(repository);
      },
      act: (bloc) => bloc.add(const ChatStarted()),
      expect: () => [
        isA<ChatState>()
            .having((s) => s.status, 'status', ChatStatus.ready)
            .having((s) => s.conversationId, 'conversationId', 'c1'),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'sends a message and emits sending then ready',
      build: () {
        when(() => repository.sendMessage(
              conversationId: any(named: 'conversationId'),
              text: any(named: 'text'),
              languageInstruction: any(named: 'languageInstruction'),
            )).thenAnswer((_) async => _msg('a1', ChatRole.assistant, 'Hi!'));
        when(() => repository.loadMessages('c1')).thenReturn([
          _msg('u1', ChatRole.user, 'Hello'),
          _msg('a1', ChatRole.assistant, 'Hi!'),
        ]);
        return ChatBloc(repository);
      },
      seed: () => const ChatState(
        status: ChatStatus.ready,
        conversationId: 'c1',
      ),
      act: (bloc) => bloc.add(const ChatMessageSent('Hello')),
      expect: () => [
        isA<ChatState>()
            .having((s) => s.status, 'status', ChatStatus.sending),
        isA<ChatState>()
            .having((s) => s.status, 'status', ChatStatus.ready)
            .having((s) => s.messages.length, 'messages', 2),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'emits error when the repository fails',
      build: () {
        when(() => repository.sendMessage(
              conversationId: any(named: 'conversationId'),
              text: any(named: 'text'),
              languageInstruction: any(named: 'languageInstruction'),
            )).thenThrow(const ServerFailure('boom'));
        when(() => repository.loadMessages('c1')).thenReturn([]);
        return ChatBloc(repository);
      },
      seed: () => const ChatState(
        status: ChatStatus.ready,
        conversationId: 'c1',
      ),
      act: (bloc) => bloc.add(const ChatMessageSent('Hello')),
      expect: () => [
        isA<ChatState>()
            .having((s) => s.status, 'status', ChatStatus.sending),
        isA<ChatState>()
            .having((s) => s.status, 'status', ChatStatus.error)
            .having((s) => s.errorMessage, 'errorMessage', 'boom'),
      ],
    );
  });
}
