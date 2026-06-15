part of 'history_bloc.dart';

enum HistoryStatus { initial, ready }

class HistoryState extends Equatable {
  final HistoryStatus status;
  final List<Conversation> conversations;

  const HistoryState({
    this.status = HistoryStatus.initial,
    this.conversations = const [],
  });

  HistoryState copyWith({
    HistoryStatus? status,
    List<Conversation>? conversations,
  }) =>
      HistoryState(
        status: status ?? this.status,
        conversations: conversations ?? this.conversations,
      );

  @override
  List<Object?> get props => [status, conversations];
}
