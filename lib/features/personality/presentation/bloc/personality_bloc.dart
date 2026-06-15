import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/ai_personality.dart';
import '../../data/repositories/personality_repository.dart';

part 'personality_event.dart';
part 'personality_state.dart';

class PersonalityBloc extends Bloc<PersonalityEvent, PersonalityState> {
  final PersonalityRepository _repository;

  PersonalityBloc(this._repository) : super(const PersonalityState()) {
    on<PersonalityStarted>(_onStarted);
    on<PersonalitySaved>(_onSaved);
    on<PersonalityDeleted>(_onDeleted);
  }

  Future<void> _onStarted(
      PersonalityStarted event, Emitter<PersonalityState> emit) async {
    await _repository.seedPresetsIfNeeded();
    emit(state.copyWith(
      status: PersonalityStatus.ready,
      personalities: _repository.getAll(),
    ));
  }

  Future<void> _onSaved(
      PersonalitySaved event, Emitter<PersonalityState> emit) async {
    await _repository.save(event.personality);
    emit(state.copyWith(personalities: _repository.getAll()));
  }

  Future<void> _onDeleted(
      PersonalityDeleted event, Emitter<PersonalityState> emit) async {
    await _repository.delete(event.id);
    emit(state.copyWith(personalities: _repository.getAll()));
  }
}
