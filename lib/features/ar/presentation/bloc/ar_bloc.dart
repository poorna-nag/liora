import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/services/ar_support_service.dart';
import '../../utils/ar_constants.dart';

part 'ar_event.dart';
part 'ar_state.dart';

/// Phase 7 — thin status mirror for the AR screen. The AR session/object/anchor
/// managers live in the screen (they're created by the plugin's `ARView`); this
/// bloc only tracks what the UI needs: are we initializing, ready, unsupported
/// or errored, and how many objects are placed.
///
/// Graceful-degradation (requirement 11): platforms that can't host AR are
/// rejected immediately, and if the AR view never comes up within
/// [ArConstants.initTimeout] we assume the device is unsupported rather than
/// spinning forever.
class ArBloc extends Bloc<ArEvent, ArState> {
  final ArSupportService _support;
  Timer? _initTimer;

  ArBloc(this._support) : super(const ArState()) {
    on<ArStarted>(_onStarted);
    on<ArViewReady>(_onViewReady);
    on<ArInitTimedOut>(_onInitTimedOut);
    on<ArObjectPlaced>(_onObjectPlaced);
    on<ArCleared>(_onCleared);
    on<ArErrorReported>(_onErrorReported);
  }

  void _onStarted(ArStarted event, Emitter<ArState> emit) {
    if (!_support.isPlatformCapable) {
      emit(state.copyWith(
        status: ArStatus.unsupported,
        message: _support.unsupportedMessage,
      ));
      return;
    }
    emit(const ArState(status: ArStatus.initializing));
    _initTimer?.cancel();
    _initTimer = Timer(ArConstants.initTimeout, () => add(const ArInitTimedOut()));
  }

  void _onViewReady(ArViewReady event, Emitter<ArState> emit) {
    _initTimer?.cancel();
    if (state.status == ArStatus.initializing) {
      emit(state.copyWith(status: ArStatus.ready));
    }
  }

  void _onInitTimedOut(ArInitTimedOut event, Emitter<ArState> emit) {
    if (state.status == ArStatus.initializing) {
      emit(state.copyWith(
        status: ArStatus.unsupported,
        message: _support.unsupportedMessage,
      ));
    }
  }

  void _onObjectPlaced(ArObjectPlaced event, Emitter<ArState> emit) {
    emit(state.copyWith(placedCount: state.placedCount + 1));
  }

  void _onCleared(ArCleared event, Emitter<ArState> emit) {
    emit(state.copyWith(placedCount: 0));
  }

  void _onErrorReported(ArErrorReported event, Emitter<ArState> emit) {
    emit(state.copyWith(status: ArStatus.error, message: event.message));
  }

  @override
  Future<void> close() {
    _initTimer?.cancel();
    return super.close();
  }
}
