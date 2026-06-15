part of 'settings_bloc.dart';

enum SettingsStatus { initial, ready }

class SettingsState extends Equatable {
  final SettingsStatus status;
  final AppSettings settings;

  const SettingsState({
    this.status = SettingsStatus.initial,
    this.settings = const AppSettings(),
  });

  SettingsState copyWith({
    SettingsStatus? status,
    AppSettings? settings,
  }) =>
      SettingsState(
        status: status ?? this.status,
        settings: settings ?? this.settings,
      );

  @override
  List<Object?> get props => [status, settings];
}
