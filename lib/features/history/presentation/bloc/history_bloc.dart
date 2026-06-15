import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/conversation.dart';
import '../../data/repositories/history_repository.dart';

part 'history_event.dart';
part 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final HistoryRepository _repository;

  HistoryBloc(this._repository) : super(const HistoryState()) {
    on<HistoryStarted>(_onStarted);
    on<HistoryItemDeleted>(_onDeleted);
  }

  void _onStarted(HistoryStarted event, Emitter<HistoryState> emit) {
    emit(state.copyWith(
      status: HistoryStatus.ready,
      conversations: _repository.getAll(),
    ));
  }

  Future<void> _onDeleted(
      HistoryItemDeleted event, Emitter<HistoryState> emit) async {
    await _repository.delete(event.id);
    emit(state.copyWith(conversations: _repository.getAll()));
  }
}
