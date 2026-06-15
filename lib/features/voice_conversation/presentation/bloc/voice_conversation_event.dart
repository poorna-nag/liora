part of 'voice_conversation_bloc.dart';

sealed class VoiceConversationEvent extends Equatable {
  const VoiceConversationEvent();

  @override
  List<Object?> get props => [];
}

class VoiceStarted extends VoiceConversationEvent {
  const VoiceStarted();
}

/// User tapped the mic: begin listening.
class VoiceListenRequested extends VoiceConversationEvent {
  const VoiceListenRequested();
}

/// User tapped stop, or recognition ended.
class VoiceListenStopped extends VoiceConversationEvent {
  const VoiceListenStopped();
}

/// Internal: a (partial or final) transcript arrived from the recognizer.
class VoiceTranscriptUpdated extends VoiceConversationEvent {
  final String transcript;
  final bool isFinal;
  const VoiceTranscriptUpdated(this.transcript, this.isFinal);

  @override
  List<Object?> get props => [transcript, isFinal];
}

/// Stop any in-progress spoken playback.
class VoiceSpeakingStopped extends VoiceConversationEvent {
  const VoiceSpeakingStopped();
}
