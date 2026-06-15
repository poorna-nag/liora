import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/companion_character.dart';
import '../../data/repositories/character_repository.dart';

part 'character_event.dart';
part 'character_state.dart';

class CharacterBloc extends Bloc<CharacterEvent, CharacterState> {
  final CharacterRepository _repository;

  CharacterBloc(this._repository) : super(const CharacterState()) {
    on<CharacterStarted>(_onStarted);
    on<CharacterSelected>(_onSelected);
    on<CharacterSaved>(_onSaved);
    on<CharacterDeleted>(_onDeleted);
  }

  Future<void> _onStarted(
      CharacterStarted event, Emitter<CharacterState> emit) async {
    await _repository.seedPresetsIfNeeded();
    emit(state.copyWith(
      status: CharacterStatus.ready,
      characters: _repository.getAll(),
      activeId: _repository.getActiveOrDefault().id,
    ));
  }

  Future<void> _onSelected(
      CharacterSelected event, Emitter<CharacterState> emit) async {
    await _repository.setActive(event.id);
    emit(state.copyWith(activeId: event.id));
  }

  Future<void> _onSaved(
      CharacterSaved event, Emitter<CharacterState> emit) async {
    await _repository.save(event.character);
    emit(state.copyWith(characters: _repository.getAll()));
  }

  Future<void> _onDeleted(
      CharacterDeleted event, Emitter<CharacterState> emit) async {
    await _repository.delete(event.id);
    emit(state.copyWith(
      characters: _repository.getAll(),
      activeId: _repository.getActiveOrDefault().id,
    ));
  }
}
