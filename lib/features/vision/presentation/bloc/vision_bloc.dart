import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../chat/data/models/chat_message.dart';
import '../../data/repositories/vision_repository.dart';

part 'vision_event.dart';
part 'vision_state.dart';

class VisionBloc extends Bloc<VisionEvent, VisionState> {
  final VisionRepository _repository;

  VisionBloc(this._repository) : super(const VisionState()) {
    on<VisionStarted>(_onStarted);
    on<VisionImageSubmitted>(_onImageSubmitted);
  }

  Future<void> _onStarted(VisionStarted event, Emitter<VisionState> emit) async {
    final conversation = await _repository.start();
    emit(state.copyWith(
      status: VisionStatus.ready,
      conversationId: conversation.id,
      messages: _repository.loadMessages(conversation.id),
    ));
  }

  Future<void> _onImageSubmitted(
      VisionImageSubmitted event, Emitter<VisionState> emit) async {
    final conversationId = state.conversationId;
    if (conversationId == null || state.isAnalyzing) return;

    emit(state.copyWith(status: VisionStatus.analyzing));
    try {
      await _repository.analyze(
        conversationId: conversationId,
        imageBytes: event.imageBytes,
        prompt: event.prompt,
      );
      emit(state.copyWith(
        status: VisionStatus.ready,
        messages: _repository.loadMessages(conversationId),
      ));
    } on Failure catch (f) {
      emit(state.copyWith(
        status: VisionStatus.error,
        messages: _repository.loadMessages(conversationId),
        errorMessage: f.message,
      ));
    }
  }
}
