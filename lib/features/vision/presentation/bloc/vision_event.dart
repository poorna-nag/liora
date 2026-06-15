part of 'vision_bloc.dart';

sealed class VisionEvent extends Equatable {
  const VisionEvent();

  @override
  List<Object?> get props => [];
}

class VisionStarted extends VisionEvent {
  const VisionStarted();
}

/// Submit a captured/picked image with an optional question.
class VisionImageSubmitted extends VisionEvent {
  final Uint8List imageBytes;
  final String prompt;
  const VisionImageSubmitted(this.imageBytes, this.prompt);

  @override
  List<Object?> get props => [imageBytes, prompt];
}
