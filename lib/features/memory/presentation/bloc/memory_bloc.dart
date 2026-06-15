import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/memory_entry.dart';
import '../../data/repositories/memory_repository.dart';

part 'memory_event.dart';
part 'memory_state.dart';

class MemoryBloc extends Bloc<MemoryEvent, MemoryState> {
  final MemoryRepository _repository;

  MemoryBloc(this._repository) : super(const MemoryState()) {
    on<MemoryStarted>(_onStarted);
    on<MemoryAdded>(_onAdded);
    on<MemoryUpdated>(_onUpdated);
    on<MemoryDeleted>(_onDeleted);
    on<MemoryCleared>(_onCleared);
  }

  void _emitList(Emitter<MemoryState> emit) {
    emit(state.copyWith(
      status: MemoryStatus.ready,
      entries: _repository.getAll(),
    ));
  }

  void _onStarted(MemoryStarted event, Emitter<MemoryState> emit) =>
      _emitList(emit);

  Future<void> _onAdded(MemoryAdded event, Emitter<MemoryState> emit) async {
    if (event.content.trim().isEmpty) return;
    await _repository.add(event.content, pinned: event.pinned);
    _emitList(emit);
  }

  Future<void> _onUpdated(
      MemoryUpdated event, Emitter<MemoryState> emit) async {
    await _repository.update(event.entry);
    _emitList(emit);
  }

  Future<void> _onDeleted(
      MemoryDeleted event, Emitter<MemoryState> emit) async {
    await _repository.delete(event.id);
    _emitList(emit);
  }

  Future<void> _onCleared(
      MemoryCleared event, Emitter<MemoryState> emit) async {
    await _repository.clear();
    _emitList(emit);
  }
}
