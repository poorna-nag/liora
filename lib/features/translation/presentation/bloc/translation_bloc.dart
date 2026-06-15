import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/services/speech_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../../multilingual/data/models/language_option.dart';
import '../../data/models/translation_result.dart';
import '../../data/repositories/translation_repository.dart';

part 'translation_event.dart';
part 'translation_state.dart';

class TranslationBloc extends Bloc<TranslationEvent, TranslationState> {
  final TranslationRepository _repository;
  final SpeechService _speech;
  final TtsService _tts;
  final PermissionService _permissions;

  TranslationBloc(
    this._repository,
    this._speech,
    this._tts,
    this._permissions,
  ) : super(TranslationState()) {
    on<TranslationStarted>(_onStarted);
    on<TranslationSourceLanguageChanged>(_onSourceChanged);
    on<TranslationTargetLanguageChanged>(_onTargetChanged);
    on<TranslationLanguagesSwapped>(_onSwapped);
    on<TranslationListenRequested>(_onListenRequested);
    on<TranslationListenStopped>(_onListenStopped);
    on<TranslationTranscriptUpdated>(_onTranscriptUpdated);
    on<TranslationTextSubmitted>(_onTextSubmitted);
    on<TranslationSpeakRequested>(_onSpeakRequested);
  }

  Future<void> _onStarted(
      TranslationStarted event, Emitter<TranslationState> emit) async {
    final conversation = await _repository.start();
    emit(state.copyWith(
      status: TranslationStatus.idle,
      conversationId: conversation.id,
    ));
  }

  void _onSourceChanged(
      TranslationSourceLanguageChanged event, Emitter<TranslationState> emit) {
    emit(state.copyWith(sourceLanguage: event.language));
  }

  void _onTargetChanged(
      TranslationTargetLanguageChanged event, Emitter<TranslationState> emit) {
    emit(state.copyWith(targetLanguage: event.language));
  }

  void _onSwapped(
      TranslationLanguagesSwapped event, Emitter<TranslationState> emit) {
    emit(state.copyWith(
      sourceLanguage: state.targetLanguage,
      targetLanguage: state.sourceLanguage,
    ));
  }

  Future<void> _onListenRequested(
      TranslationListenRequested event, Emitter<TranslationState> emit) async {
    if (state.isListening || state.isBusy) return;
    final granted = await _permissions.requestSpeech();
    if (!granted) {
      emit(state.copyWith(
        status: TranslationStatus.error,
        errorMessage: 'Microphone/speech permission denied.',
      ));
      return;
    }
    emit(state.copyWith(
        status: TranslationStatus.listening, partialTranscript: ''));
    try {
      await _speech.listen(
        localeId: _localeId(state.sourceLanguage.code),
        onResult: (transcript, isFinal) =>
            add(TranslationTranscriptUpdated(transcript, isFinal)),
      );
    } catch (e) {
      emit(state.copyWith(
        status: TranslationStatus.error,
        errorMessage: 'Could not start listening: $e',
      ));
    }
  }

  Future<void> _onListenStopped(
      TranslationListenStopped event, Emitter<TranslationState> emit) async {
    await _speech.stop();
    if (state.status == TranslationStatus.listening) {
      emit(state.copyWith(status: TranslationStatus.idle));
    }
  }

  Future<void> _onTranscriptUpdated(TranslationTranscriptUpdated event,
      Emitter<TranslationState> emit) async {
    emit(state.copyWith(partialTranscript: event.transcript));
    if (!event.isFinal) return;
    await _speech.stop();
    final text = event.transcript.trim();
    emit(state.copyWith(partialTranscript: ''));
    if (text.isNotEmpty) {
      await _translate(text, emit, speakResult: true);
    } else {
      emit(state.copyWith(status: TranslationStatus.idle));
    }
  }

  Future<void> _onTextSubmitted(
      TranslationTextSubmitted event, Emitter<TranslationState> emit) async {
    final text = event.text.trim();
    if (text.isEmpty || state.isBusy) return;
    await _translate(text, emit, speakResult: false);
  }

  Future<void> _translate(String text, Emitter<TranslationState> emit,
      {required bool speakResult}) async {
    emit(state.copyWith(status: TranslationStatus.translating));
    try {
      final result = await _repository.translate(
        conversationId: state.conversationId!,
        sourceText: text,
        sourceLanguageName: state.sourceLanguage.name,
        targetLanguageName: state.targetLanguage.name,
      );
      emit(state.copyWith(
        status: TranslationStatus.idle,
        results: [result, ...state.results],
      ));
      if (speakResult) {
        add(TranslationSpeakRequested(result.translatedText));
      }
    } on Failure catch (f) {
      emit(state.copyWith(
        status: TranslationStatus.error,
        errorMessage: f.message,
      ));
    }
  }

  Future<void> _onSpeakRequested(
      TranslationSpeakRequested event, Emitter<TranslationState> emit) async {
    emit(state.copyWith(status: TranslationStatus.speaking));
    await _tts.speak(
      event.text,
      languageCode: _ttsLanguage(state.targetLanguage.code),
    );
    emit(state.copyWith(status: TranslationStatus.idle));
  }

  String _localeId(String code) => _localeMap[code] ?? 'en_US';
  String _ttsLanguage(String code) => _ttsMap[code] ?? 'en-US';

  static const _localeMap = {
    'en': 'en_US', 'es': 'es_ES', 'fr': 'fr_FR', 'de': 'de_DE',
    'hi': 'hi_IN', 'zh': 'zh_CN', 'ar': 'ar_SA', 'ja': 'ja_JP',
  };
  static const _ttsMap = {
    'en': 'en-US', 'es': 'es-ES', 'fr': 'fr-FR', 'de': 'de-DE',
    'hi': 'hi-IN', 'zh': 'zh-CN', 'ar': 'ar-SA', 'ja': 'ja-JP',
  };

  @override
  Future<void> close() {
    _speech.cancel();
    _tts.stop();
    return super.close();
  }
}
