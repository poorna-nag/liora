part of 'history_bloc.dart';

sealed class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class HistoryStarted extends HistoryEvent {
  const HistoryStarted();
}

class HistoryItemDeleted extends HistoryEvent {
  final String id;
  const HistoryItemDeleted(this.id);

  @override
  List<Object?> get props => [id];
}
