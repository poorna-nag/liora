import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liora/features/settings/data/models/app_settings.dart';
import 'package:liora/features/settings/data/repositories/settings_repository.dart';
import 'package:liora/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository repository;

  setUpAll(() {
    registerFallbackValue(const AppSettings());
  });

  setUp(() {
    repository = MockSettingsRepository();
    when(() => repository.load()).thenReturn(const AppSettings());
    when(() => repository.save(any())).thenAnswer((_) async {});
  });

  group('SettingsBloc', () {
    blocTest<SettingsBloc, SettingsState>(
      'loads settings on SettingsStarted',
      build: () => SettingsBloc(repository),
      act: (bloc) => bloc.add(const SettingsStarted()),
      expect: () => [
        isA<SettingsState>()
            .having((s) => s.status, 'status', SettingsStatus.ready),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'persists theme mode change',
      build: () => SettingsBloc(repository),
      seed: () => const SettingsState(status: SettingsStatus.ready),
      act: (bloc) => bloc.add(const ThemeModeChanged(ThemeMode.dark)),
      expect: () => [
        isA<SettingsState>()
            .having((s) => s.settings.themeMode, 'themeMode', ThemeMode.dark),
      ],
      verify: (_) => verify(() => repository.save(any())).called(1),
    );
  });
}
