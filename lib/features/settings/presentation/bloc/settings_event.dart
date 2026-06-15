part of 'settings_bloc.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class SettingsStarted extends SettingsEvent {
  const SettingsStarted();
}

class ThemeModeChanged extends SettingsEvent {
  final ThemeMode themeMode;
  const ThemeModeChanged(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

class LanguageChanged extends SettingsEvent {
  final String languageCode;
  const LanguageChanged(this.languageCode);

  @override
  List<Object?> get props => [languageCode];
}

class ActivePersonalityChanged extends SettingsEvent {
  final String personalityId;
  const ActivePersonalityChanged(this.personalityId);

  @override
  List<Object?> get props => [personalityId];
}

class MemoryToggled extends SettingsEvent {
  final bool enabled;
  const MemoryToggled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class SpeechRateChanged extends SettingsEvent {
  final double rate;
  const SpeechRateChanged(this.rate);

  @override
  List<Object?> get props => [rate];
}

class AllDataCleared extends SettingsEvent {
  const AllDataCleared();
}
