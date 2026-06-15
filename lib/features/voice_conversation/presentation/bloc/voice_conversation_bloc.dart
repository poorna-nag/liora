import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/services/speech_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../../chat/data/models/chat_message.dart';
import '../../../settings/data/repositories/settings_repository.dart';
import '../../data/repositories/voice_conversation_repository.dart';

part 'voice_conversation_event.dart';
part 'voice_conversation_state.dart';

/// Orchestrates speech-to-text, the AI reply (via the repository) and
/// text-to-speech for a spoken conversation.
class VoiceConversationBloc
    extends Bloc<VoiceConversationEvent, VoiceConversationState> {
  final VoiceConversationRepository _repository;
  final SpeechService _speech;
  final TtsService _tts;
  final PermissionService _permissions;
  final SettingsRepository _settings;

  VoiceConversationBloc(
    this._repository,
    this._speech,
    this._tts,
    this._permissions,
    this._settings,
  ) : super(const VoiceConversationState()) {
    on<VoiceStarted>(_onStarted);
    on<VoiceListenRequested>(_onListenRequested);
    on<VoiceListenStopped>(_onListenStopped);
    on<VoiceTranscriptUpdated>(_onTranscriptUpdated);
    on<VoiceSpeakingStopped>(_onSpeakingStopped);
  }

  Future<void> _onStarted(
      VoiceStarted event, Emitter<VoiceConversationState> emit) async {
    final conversation = await _repository.start();
    emit(state.copyWith(
      status: VoiceStatus.idle,
      conversationId: conversation.id,
      messages: _repository.loadMessages(conversation.id),
    ));
  }

  Future<void> _onListenRequested(
      VoiceListenRequested event, Emitter<VoiceConversationState> emit) async {
    if (state.isListening || state.isBusy) return;

    final granted = await _permissions.requestSpeech();
    if (!granted) {
      emit(state.copyWith(
        status: VoiceStatus.error,
        errorMessage: 'Microphone/speech permission denied.',
      ));
      return;
    }

    final locale = _localeId();
    emit(state.copyWith(status: VoiceStatus.listening, partialTranscript: ''));
    try {
      await _speech.listen(
        localeId: locale,
        onResult: (transcript, isFinal) =>
            add(VoiceTranscriptUpdated(transcript, isFinal)),
      );
    } catch (e) {
      emit(state.copyWith(
        status: VoiceStatus.error,
        errorMessage: 'Could not start listening: $e',
      ));
    }
  }

  Future<void> _onListenStopped(
      VoiceListenStopped event, Emitter<VoiceConversationState> emit) async {
    await _speech.stop();
    if (state.status == VoiceStatus.listening) {
      emit(state.copyWith(status: VoiceStatus.idle));
    }
  }

  Future<void> _onTranscriptUpdated(VoiceTranscriptUpdated event,
      Emitter<VoiceConversationState> emit) async {
    emit(state.copyWith(partialTranscript: event.transcript));
    if (!event.isFinal) return;

    final text = event.transcript.trim();
    await _speech.stop();
    if (text.isEmpty) {
      emit(state.copyWith(status: VoiceStatus.idle, partialTranscript: ''));
      return;
    }

    final conversationId = state.conversationId!;
    emit(state.copyWith(
      status: VoiceStatus.processing,
      partialTranscript: '',
      messages: _repository.loadMessages(conversationId),
    ));

    try {
      final reply = await _repository.send(
        conversationId: conversationId,
        text: text,
      );
      emit(state.copyWith(
        status: VoiceStatus.speaking,
        messages: _repository.loadMessages(conversationId),
      ));
      final settings = _settings.load();
      await _tts.speak(
        reply.content,
        languageCode: _ttsLanguage(settings.languageCode),
        rate: settings.speechRate,
      );
      emit(state.copyWith(status: VoiceStatus.idle));
    } on Failure catch (f) {
      emit(state.copyWith(
        status: VoiceStatus.error,
        messages: _repository.loadMessages(conversationId),
        errorMessage: f.message,
      ));
    }
  }

  Future<void> _onSpeakingStopped(
      VoiceSpeakingStopped event, Emitter<VoiceConversationState> emit) async {
    await _tts.stop();
    emit(state.copyWith(status: VoiceStatus.idle));
  }

  String _localeId() {
    final code = _settings.load().languageCode;
    // speech_to_text expects locale ids like en_US; map common codes.
    return _localeMap[code] ?? 'en_US';
  }

  String _ttsLanguage(String code) => _ttsMap[code] ?? 'en-US';

  static const _localeMap = {
    'en': 'en_US',
    'es': 'es_ES',
    'fr': 'fr_FR',
    'de': 'de_DE',
    'hi': 'hi_IN',
    'zh': 'zh_CN',
    'ar': 'ar_SA',
    'ja': 'ja_JP',
  };

  static const _ttsMap = {
    'en': 'en-US',
    'es': 'es-ES',
    'fr': 'fr-FR',
    'de': 'de-DE',
    'hi': 'hi-IN',
    'zh': 'zh-CN',
    'ar': 'ar-SA',
    'ja': 'ja-JP',
  };

  @override
  Future<void> close() {
    _speech.cancel();
    _tts.stop();
    return super.close();
  }
}
