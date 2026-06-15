part of 'personality_bloc.dart';

enum PersonalityStatus { initial, ready }

class PersonalityState extends Equatable {
  final PersonalityStatus status;
  final List<AIPersonality> personalities;

  const PersonalityState({
    this.status = PersonalityStatus.initial,
    this.personalities = const [],
  });

  PersonalityState copyWith({
    PersonalityStatus? status,
    List<AIPersonality>? personalities,
  }) =>
      PersonalityState(
        status: status ?? this.status,
        personalities: personalities ?? this.personalities,
      );

  @override
  List<Object?> get props => [status, personalities];
}
