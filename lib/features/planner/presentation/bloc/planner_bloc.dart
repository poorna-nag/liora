import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/plan_item.dart';
import '../../data/repositories/planner_repository.dart';

part 'planner_event.dart';
part 'planner_state.dart';

/// Phase 6 — drives the planner screen. Thin: all persistence is in the
/// repository; the bloc just reloads the list after each mutation.
class PlannerBloc extends Bloc<PlannerEvent, PlannerState> {
  final PlannerRepository _repository;

  PlannerBloc(this._repository) : super(const PlannerState()) {
    on<PlannerStarted>(_onStarted);
    on<PlannerItemAdded>(_onAdded);
    on<PlannerItemToggled>(_onToggled);
    on<PlannerItemDeleted>(_onDeleted);
  }

  void _onStarted(PlannerStarted event, Emitter<PlannerState> emit) {
    emit(PlannerState(status: PlannerStatus.ready, items: _repository.list()));
  }

  Future<void> _onAdded(
      PlannerItemAdded event, Emitter<PlannerState> emit) async {
    await _repository.add(
      title: event.title,
      notes: event.notes,
      dueAt: event.dueAt,
    );
    emit(state.copyWith(items: _repository.list()));
  }

  Future<void> _onToggled(
      PlannerItemToggled event, Emitter<PlannerState> emit) async {
    await _repository.toggleDone(event.id);
    emit(state.copyWith(items: _repository.list()));
  }

  Future<void> _onDeleted(
      PlannerItemDeleted event, Emitter<PlannerState> emit) async {
    await _repository.delete(event.id);
    emit(state.copyWith(items: _repository.list()));
  }
}
