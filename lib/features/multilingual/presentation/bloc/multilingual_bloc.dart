import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../chat/data/models/chat_message.dart';
import '../../../chat/data/models/chat_role.dart';
import '../../data/models/language_option.dart';
import '../../data/repositories/multilingual_repository.dart';

part 'multilingual_event.dart';
part 'multilingual_state.dart';

class MultilingualBloc extends Bloc<MultilingualEvent, MultilingualState> {
  final MultilingualRepository _repository;

  MultilingualBloc(this._repository) : super(MultilingualState()) {
    on<MultilingualStarted>(_onStarted);
    on<MultilingualLanguageChanged>(_onLanguageChanged);
    on<MultilingualMessageSent>(_onMessageSent);
  }

  Future<void> _onStarted(
      MultilingualStarted event, Emitter<MultilingualState> emit) async {
    final conversation = await _repository.start();
    emit(state.copyWith(
      status: MultilingualStatus.ready,
      conversationId: conversation.id,
      messages: _repository.loadMessages(conversation.id),
    ));
  }

  void _onLanguageChanged(
      MultilingualLanguageChanged event, Emitter<MultilingualState> emit) {
    emit(state.copyWith(language: event.language));
  }

  Future<void> _onMessageSent(
      MultilingualMessageSent event, Emitter<MultilingualState> emit) async {
    final conversationId = state.conversationId;
    final text = event.text.trim();
    if (conversationId == null || text.isEmpty || state.isSending) return;

    final optimistic = ChatMessage(
      id: 'pending_${DateTime.now().microsecondsSinceEpoch}',
      conversationId: conversationId,
      role: ChatRole.user,
      content: text,
      createdAt: DateTime.now(),
    );
    emit(state.copyWith(
      status: MultilingualStatus.sending,
      messages: [...state.messages, optimistic],
    ));

    try {
      await _repository.send(
        conversationId: conversationId,
        text: text,
        languageName: state.language.name,
      );
      emit(state.copyWith(
        status: MultilingualStatus.ready,
        messages: _repository.loadMessages(conversationId),
      ));
    } on Failure catch (f) {
      emit(state.copyWith(
        status: MultilingualStatus.error,
        messages: _repository.loadMessages(conversationId),
        errorMessage: f.message,
      ));
    }
  }
}
