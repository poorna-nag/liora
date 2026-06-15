import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/init/init_step.dart';
import '../../data/repositories/splash_repository.dart';

part 'splash_event.dart';
part 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final SplashRepository _repository;

  SplashBloc(this._repository) : super(const SplashState()) {
    on<SplashStarted>(_onStarted);
  }

  Future<void> _onStarted(
      SplashStarted event, Emitter<SplashState> emit) async {
    emit(state.copyWith(status: SplashStatus.inProgress));
    try {
      await for (final progress in _repository.initialize()) {
        emit(state.copyWith(
          status: SplashStatus.inProgress,
          progress: progress,
        ));
      }
      emit(state.copyWith(status: SplashStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: SplashStatus.failure,
        errorMessage: 'Initialization failed: $e',
      ));
    }
  }
}
