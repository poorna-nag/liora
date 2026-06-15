import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../di/service_locator.dart';
import '../services/auth_service.dart';
import '../services/gemini_service.dart';
import '../session/session_manager.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/character/data/repositories/character_repository.dart';
import '../storage/hive_registrar.dart';
import '../storage/preferences_service.dart';
import '../../features/personality/data/repositories/personality_repository.dart';
import '../../features/settings/data/repositories/settings_repository.dart';
import 'init_step.dart';

/// Orchestrates application startup and registers dependencies.
///
/// Emits an [InitProgress] before each step so the splash screen can show a
/// live progress indicator. Designed to run exactly once.
class AppInitializer {
  bool _aiAvailable = false;

  Stream<InitProgress> initialize() async* {
    final total = InitStep.values.length;

    // 1. Firebase (and therefore the AI service). Guarded so the app still
    //    runs if config is missing — the assistant simply reports it's offline.
    yield InitProgress(InitStep.firebase, 1, total);
    _aiAvailable = await _initFirebase();

    // 2. Local storage (Hive).
    yield InitProgress(InitStep.storage, 2, total);
    await Hive.initFlutter();
    HiveRegistrar.registerAdapters();
    await HiveRegistrar.openBoxes();

    // 3. Preferences.
    yield InitProgress(InitStep.preferences, 3, total);
    final prefs = await PreferencesService.create();

    // 4. Guest session.
    yield InitProgress(InitStep.session, 4, total);
    final session = GuestSessionManager(prefs);
    await session.init();

    // Dependencies can now be wired.
    setupServiceLocator(prefs: prefs, session: session);

    // 5. User settings + AI configuration (seed personality presets).
    yield InitProgress(InitStep.configuration, 5, total);
    await sl<PersonalityRepository>().seedPresetsIfNeeded();
    await sl<CharacterRepository>().seedPresetsIfNeeded();
    sl<SettingsRepository>().load();

    // 6. Warm up the assistant and resolve the auth/session state.
    yield InitProgress(InitStep.ai, 6, total);
    sl<GeminiService>().markAvailable(_aiAvailable);
    sl<AuthService>().markAvailable(_aiAvailable);
    await sl<AuthRepository>().bootstrap();
  }

  Future<bool> _initFirebase() async {
    try {
      // Uses the native config added by `flutterfire configure`
      // (google-services.json / GoogleService-Info.plist). If absent, this
      // throws and we degrade gracefully.
      await Firebase.initializeApp();
      return true;
    } catch (_) {
      return false;
    }
  }
}
