part of 'splash_bloc.dart';

enum SplashStatus { initial, inProgress, success, failure }

class SplashState extends Equatable {
  final SplashStatus status;
  final InitProgress? progress;
  final String? errorMessage;

  const SplashState({
    this.status = SplashStatus.initial,
    this.progress,
    this.errorMessage,
  });

  String get stepLabel => progress?.step.label ?? 'Starting…';
  double get fraction => progress?.fraction ?? 0;

  SplashState copyWith({
    SplashStatus? status,
    InitProgress? progress,
    String? errorMessage,
  }) =>
      SplashState(
        status: status ?? this.status,
        progress: progress ?? this.progress,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props =>
      [status, progress?.index, progress?.step, errorMessage];
}
