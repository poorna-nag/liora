import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/feature_tile.dart';
import '../../data/repositories/home_repository.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository _repository;

  HomeBloc(this._repository) : super(const HomeState()) {
    on<HomeStarted>(_onStarted);
  }

  void _onStarted(HomeStarted event, Emitter<HomeState> emit) {
    emit(HomeState(tiles: _repository.tiles()));
  }
}
