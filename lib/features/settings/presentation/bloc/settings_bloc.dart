import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../data/models/app_settings.dart';
import '../../data/repositories/settings_repository.dart';

part 'settings_event.dart';
part 'settings_state.dart';

/// Owns the app-wide [AppSettings]. Other features read the current settings
/// from this bloc (provided globally) so theme/language/personality changes
/// take effect immediately.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _repository;

  SettingsBloc(this._repository) : super(const SettingsState()) {
    on<SettingsStarted>(_onStarted);
    on<ThemeModeChanged>(_onThemeModeChanged);
    on<LanguageChanged>(_onLanguageChanged);
    on<ActivePersonalityChanged>(_onActivePersonalityChanged);
    on<MemoryToggled>(_onMemoryToggled);
    on<SpeechRateChanged>(_onSpeechRateChanged);
    on<AllDataCleared>(_onAllDataCleared);
  }

  void _onStarted(SettingsStarted event, Emitter<SettingsState> emit) {
    emit(state.copyWith(
      status: SettingsStatus.ready,
      settings: _repository.load(),
    ));
  }

  Future<void> _persist(AppSettings settings, Emitter<SettingsState> emit) async {
    await _repository.save(settings);
    emit(state.copyWith(status: SettingsStatus.ready, settings: settings));
  }

  Future<void> _onThemeModeChanged(
      ThemeModeChanged event, Emitter<SettingsState> emit) {
    return _persist(state.settings.copyWith(themeMode: event.themeMode), emit);
  }

  Future<void> _onLanguageChanged(
      LanguageChanged event, Emitter<SettingsState> emit) {
    return _persist(
        state.settings.copyWith(languageCode: event.languageCode), emit);
  }

  Future<void> _onActivePersonalityChanged(
      ActivePersonalityChanged event, Emitter<SettingsState> emit) {
    return _persist(
        state.settings.copyWith(activePersonalityId: event.personalityId),
        emit);
  }

  Future<void> _onMemoryToggled(
      MemoryToggled event, Emitter<SettingsState> emit) {
    return _persist(
        state.settings.copyWith(memoryEnabled: event.enabled), emit);
  }

  Future<void> _onSpeechRateChanged(
      SpeechRateChanged event, Emitter<SettingsState> emit) {
    return _persist(state.settings.copyWith(speechRate: event.rate), emit);
  }

  Future<void> _onAllDataCleared(
      AllDataCleared event, Emitter<SettingsState> emit) async {
    await _repository.clearAllData();
    emit(state.copyWith(status: SettingsStatus.ready));
  }
}
