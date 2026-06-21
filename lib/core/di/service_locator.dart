import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';

import '../companion/animation_engine.dart';
import '../companion/companion_manager.dart';
import '../companion/emotion_engine.dart';
import '../companion/language_engine.dart';
import '../companion/memory_engine.dart';
import '../companion/personality_engine.dart';
import '../companion/prompt_builder.dart';
import '../companion/relationship_engine.dart';
import '../companion/speech_engine.dart';
import '../companion/vision_engine.dart';
import '../live_vision/frame_processor.dart';
import '../live_vision/vision_session_manager.dart';
import '../../features/live_vision/data/repositories/live_vision_repository.dart';
import '../../features/live_vision/data/repositories/live_vision_repository_impl.dart';
import '../../features/live_vision/presentation/bloc/live_vision_bloc.dart';
import '../../features/ar/data/services/ar_support_service.dart';
import '../../features/ar/presentation/bloc/ar_bloc.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/character/data/repositories/character_repository.dart';
import '../../features/character/data/repositories/character_repository_impl.dart';
import '../../features/character/presentation/bloc/character_bloc.dart';
import '../../features/chat/data/repositories/chat_repository.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../features/home/data/repositories/home_repository.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/history/data/repositories/history_repository.dart';
import '../../features/history/data/repositories/history_repository_impl.dart';
import '../../features/history/presentation/bloc/history_bloc.dart';
import '../../features/memory/data/repositories/memory_repository.dart';
import '../../features/memory/data/repositories/memory_repository_impl.dart';
import '../../features/memory/presentation/bloc/memory_bloc.dart';
import '../../features/multilingual/data/repositories/multilingual_repository.dart';
import '../../features/multilingual/data/repositories/multilingual_repository_impl.dart';
import '../../features/multilingual/presentation/bloc/multilingual_bloc.dart';
import '../../features/personality/data/repositories/personality_repository.dart';
import '../../features/personality/data/repositories/personality_repository_impl.dart';
import '../../features/personality/presentation/bloc/personality_bloc.dart';
import '../../features/planner/data/repositories/planner_repository.dart';
import '../../features/planner/data/repositories/planner_repository_impl.dart';
import '../../features/planner/presentation/bloc/planner_bloc.dart';
import '../../features/settings/data/repositories/settings_repository.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';
import '../../features/translation/data/repositories/translation_repository.dart';
import '../../features/translation/data/repositories/translation_repository_impl.dart';
import '../../features/translation/presentation/bloc/translation_bloc.dart';
import '../../features/vision/data/repositories/vision_repository.dart';
import '../../features/vision/data/repositories/vision_repository_impl.dart';
import '../../features/vision/presentation/bloc/vision_bloc.dart';
import '../../features/voice_conversation/data/repositories/voice_conversation_repository.dart';
import '../../features/voice_conversation/data/repositories/voice_conversation_repository_impl.dart';
import '../../features/voice_conversation/presentation/bloc/voice_conversation_bloc.dart';
import '../migration/data_migration_service.dart';
import '../services/auth_service.dart';
import '../services/camera_service.dart';
import '../services/gemini_service.dart';
import '../services/memory_extractor.dart';
import '../services/memory_service.dart';
import '../services/notification_service.dart';
import '../services/permission_service.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../session/session_manager.dart';
import '../storage/conversation_store.dart';
import '../storage/hive_storage_service.dart';
import '../storage/local_storage_service.dart';
import '../storage/preferences_service.dart';

/// Global service locator.
final GetIt sl = GetIt.instance;

/// Registers every service, repository and bloc factory.
///
/// Called once during startup after [prefs] and [session] are ready (see
/// `AppInitializer`). Repositories depend only on abstractions, so V2 can
/// re-register an implementation (e.g. remote-backed) without touching blocs.
void setupServiceLocator({
  required PreferencesService prefs,
  required SessionManager session,
}) {
  // --- Core singletons -----------------------------------------------------
  sl
    ..registerSingleton<PreferencesService>(prefs)
    ..registerSingleton<SessionManager>(session)
    ..registerSingleton<LocalStorageService>(HiveStorageService())
    ..registerSingleton<GeminiService>(GeminiService())
    ..registerSingleton<AuthService>(AuthService())
    ..registerLazySingleton<ConversationStore>(
        () => ConversationStore(sl(), sl()))
    ..registerLazySingleton<MemoryService>(() => MemoryService(sl(), sl()))
    ..registerLazySingleton<MemoryExtractor>(() => MemoryExtractor(sl(), sl()))
    ..registerLazySingleton<NotificationService>(() => NotificationService())
    ..registerLazySingleton<SpeechService>(() => SpeechService())
    ..registerLazySingleton<TtsService>(() => TtsService())
    ..registerLazySingleton<CameraService>(() => CameraService())
    ..registerLazySingleton<PermissionService>(() => PermissionService())
    ..registerLazySingleton<ArSupportService>(() => const ArSupportService())
    ..registerLazySingleton<DataMigrationService>(
        () => const NoopDataMigrationService());

  // --- Companion Engine ----------------------------------------------------
  // The central brain. Every feature talks to CompanionManager, which composes
  // these engines into the request pipeline.
  sl
    ..registerLazySingleton<EmotionEngine>(() => EmotionEngine())
    ..registerLazySingleton<PersonalityEngine>(() => PersonalityEngine())
    ..registerLazySingleton<LanguageEngine>(() => LanguageEngine())
    ..registerLazySingleton<AnimationEngine>(() => AnimationEngine())
    ..registerLazySingleton<RelationshipEngine>(
        () => RelationshipEngine(sl(), sl()))
    ..registerLazySingleton<MemoryEngine>(() => MemoryEngine(sl(), sl(), sl()))
    ..registerLazySingleton<PromptBuilder>(
        () => PromptBuilder(sl(), sl(), sl()))
    ..registerLazySingleton<VisionEngine>(() => VisionEngine(sl()))
    ..registerLazySingleton<SpeechEngine>(() => SpeechEngine(sl()))
    ..registerLazySingleton<FrameProcessor>(() => const FrameProcessor())
    ..registerLazySingleton<CompanionManager>(() => CompanionManager(
          sl(), // GeminiService
          sl(), // CharacterRepository
          sl(), // PromptBuilder
          sl(), // EmotionEngine
          sl(), // RelationshipEngine
          sl(), // AnimationEngine
          sl(), // VisionEngine
          sl(), // SpeechEngine
          sl(), // LanguageEngine
        ));

  // --- Repositories --------------------------------------------------------
  sl
    ..registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(sl(), sl(), sl()))
    ..registerLazySingleton<SettingsRepository>(
        () => SettingsRepositoryImpl(sl(), sl()))
    ..registerLazySingleton<PersonalityRepository>(
        () => PersonalityRepositoryImpl(sl(), sl()))
    ..registerLazySingleton<CharacterRepository>(
        () => CharacterRepositoryImpl(sl(), sl(), sl()))
    ..registerLazySingleton<ChatRepository>(
        () => ChatRepositoryImpl(sl(), sl(), sl()))
    ..registerLazySingleton<VoiceConversationRepository>(
        () => VoiceConversationRepositoryImpl(sl()))
    ..registerLazySingleton<VisionRepository>(
        () => VisionRepositoryImpl(sl(), sl()))
    ..registerLazySingleton<MultilingualRepository>(
        () => MultilingualRepositoryImpl(sl()))
    ..registerLazySingleton<TranslationRepository>(
        () => TranslationRepositoryImpl(sl(), sl()))
    ..registerLazySingleton<HistoryRepository>(
        () => HistoryRepositoryImpl(sl()))
    ..registerLazySingleton<MemoryRepository>(
        () => MemoryRepositoryImpl(sl()))
    ..registerLazySingleton<PlannerRepository>(
        () => PlannerRepositoryImpl(sl(), sl(), sl()))
    ..registerLazySingleton<LiveVisionRepository>(
        () => LiveVisionRepositoryImpl(sl(), sl()))
    ..registerLazySingleton<HomeRepository>(
        () => const HomeRepositoryImpl());

  // --- Live Vision (V3) ----------------------------------------------------
  // The session manager is per-screen stateful, so it is a factory; it owns the
  // camera, scheduler and transient scene memory for one session.
  sl.registerFactory<VisionSessionManager>(() => VisionSessionManager(
        sl<CameraService>(),
        sl<CompanionManager>(),
        sl<SpeechEngine>(),
        sl<SpeechService>(),
        sl<PermissionService>(),
        sl<LiveVisionRepository>(),
        sl<FrameProcessor>(),
        sl<SettingsRepository>(),
        Battery(),
        Connectivity(),
      ));

  // --- Blocs ---------------------------------------------------------------
  // SettingsBloc is a singleton because it drives the global theme/language.
  sl
    ..registerLazySingleton<SettingsBloc>(
        () => SettingsBloc(sl())..add(const SettingsStarted()))
    ..registerFactory<AuthBloc>(() => AuthBloc(sl()))
    ..registerFactory<ChatBloc>(() => ChatBloc(sl()))
    ..registerFactory<VoiceConversationBloc>(
        () => VoiceConversationBloc(sl(), sl(), sl(), sl(), sl()))
    ..registerFactory<VisionBloc>(() => VisionBloc(sl()))
    ..registerFactory<LiveVisionBloc>(() => LiveVisionBloc(sl()))
    ..registerFactory<ArBloc>(() => ArBloc(sl()))
    ..registerFactory<MultilingualBloc>(() => MultilingualBloc(sl()))
    ..registerFactory<TranslationBloc>(
        () => TranslationBloc(sl(), sl(), sl(), sl()))
    ..registerFactory<HistoryBloc>(() => HistoryBloc(sl()))
    ..registerFactory<HomeBloc>(() => HomeBloc(sl(), sl()))
    ..registerFactory<PersonalityBloc>(() => PersonalityBloc(sl()))
    ..registerFactory<PlannerBloc>(() => PlannerBloc(sl()))
    ..registerFactory<CharacterBloc>(() => CharacterBloc(sl()))
    ..registerFactory<MemoryBloc>(() => MemoryBloc(sl()));
}
