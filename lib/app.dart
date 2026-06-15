import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/di/service_locator.dart';
import 'core/init/app_initializer.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/splash/data/repositories/splash_repository_impl.dart';
import 'features/splash/presentation/bloc/splash_bloc.dart';
import 'features/splash/presentation/screen/splash_screen.dart';

/// Root widget. Shows the splash screen (which initializes the app) and then
/// swaps to the router-driven app with global settings/theme once ready.
class LioraApp extends StatefulWidget {
  const LioraApp({super.key});

  @override
  State<LioraApp> createState() => _LioraAppState();
}

class _LioraAppState extends State<LioraApp> {
  bool _initialized = false;
  GoRouter? _router;

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: BlocProvider(
          create: (_) =>
              SplashBloc(SplashRepositoryImpl(AppInitializer()))
                ..add(const SplashStarted()),
          child: SplashScreen(
            onInitialized: () => setState(() => _initialized = true),
          ),
        ),
      );
    }

    _router ??= AppRouter.build();

    return BlocProvider<SettingsBloc>.value(
      value: sl<SettingsBloc>(),
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Liora',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: state.settings.themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
