import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../planner/data/repositories/planner_repository.dart';
import '../../data/models/feature_tile.dart';
import '../../data/repositories/home_repository.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository _repository;
  final PlannerRepository _planner;

  HomeBloc(this._repository, this._planner) : super(const HomeState()) {
    on<HomeStarted>(_onStarted);
  }

  void _onStarted(HomeStarted event, Emitter<HomeState> emit) {
    // Phase 6: surface what's due so the companion feels proactive.
    emit(HomeState(
      tiles: _repository.tiles(),
      reminder: _planner.proactiveSummary(),
    ));
  }
}
