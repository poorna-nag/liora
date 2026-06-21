import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// AUTH GATE DISABLED: re-add when re-enabling the redirect below.
// import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/screen/forgot_password_screen.dart';
import '../../features/auth/presentation/screen/login_screen.dart';
import '../../features/auth/presentation/screen/signup_screen.dart';
import '../../features/character/presentation/bloc/character_bloc.dart';
import '../../features/character/presentation/screen/character_selection_screen.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../features/chat/presentation/screen/chat_screen.dart';
import '../../features/history/presentation/bloc/history_bloc.dart';
import '../../features/history/presentation/screen/history_screen.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/home/presentation/screen/home_screen.dart';
import '../../features/memory/presentation/bloc/memory_bloc.dart';
import '../../features/memory/presentation/screen/memory_screen.dart';
import '../../features/multilingual/presentation/bloc/multilingual_bloc.dart';
import '../../features/multilingual/presentation/screen/multilingual_screen.dart';
import '../../features/personality/presentation/bloc/personality_bloc.dart';
import '../../features/personality/presentation/screen/personality_screen.dart';
import '../../features/planner/presentation/bloc/planner_bloc.dart';
import '../../features/planner/presentation/screen/planner_screen.dart';
import '../../features/settings/presentation/screen/settings_screen.dart';
import '../../features/translation/presentation/bloc/translation_bloc.dart';
import '../../features/translation/presentation/screen/translation_screen.dart';
import '../../features/ar/presentation/bloc/ar_bloc.dart';
import '../../features/ar/presentation/screen/ar_screen.dart';
import '../../features/live_vision/presentation/bloc/live_vision_bloc.dart';
import '../../features/live_vision/presentation/screen/live_vision_screen.dart';
import '../../features/vision/presentation/bloc/vision_bloc.dart';
import '../../features/vision/presentation/screen/vision_screen.dart';
import '../../features/voice_conversation/presentation/bloc/voice_conversation_bloc.dart';
import '../../features/voice_conversation/presentation/screen/voice_conversation_screen.dart';
import '../di/service_locator.dart';
import 'route_names.dart';

/// Builds the app's [GoRouter]. Each feature route provides its own bloc from
/// the service locator.
///
/// AUTH GATE DISABLED: the app currently goes Splash -> Home with no login
/// gate. The login/signup/forgot routes stay registered (reachable from the
/// Home/Settings "sign in" actions). To re-enable forced sign-in, uncomment the
/// `_authRoutes` set and the `refreshListenable` + `redirect` lines below (and
/// restore the unused imports / `final auth`).
class AppRouter {
  AppRouter._();

  // static const _authRoutes = {
  //   RouteNames.login,
  //   RouteNames.signup,
  //   RouteNames.forgotPassword,
  // };

  static GoRouter build() {
    // final auth = sl<AuthRepository>();
    return GoRouter(
      initialLocation: RouteNames.home,
      // refreshListenable: GoRouterRefreshStream(auth.statusChanges),
      // redirect: (context, state) {
      //   final loggedOut = auth.status == AuthStatus.unauthenticated ||
      //       auth.status == AuthStatus.unknown;
      //   final onAuthRoute = _authRoutes.contains(state.matchedLocation);
      //   if (loggedOut) {
      //     return onAuthRoute ? null : RouteNames.login;
      //   }
      //   // Keep a fully authenticated user out of the auth flow. A guest is
      //   // allowed onto it so they can upgrade to a real account.
      //   if (auth.status == AuthStatus.authenticated && onAuthRoute) {
      //     return RouteNames.home;
      //   }
      //   return null;
      // },
      routes: [
        GoRoute(
          path: RouteNames.login,
          builder: (context, state) => BlocProvider(
            create: (_) => sl<AuthBloc>(),
            child: const LoginScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.signup,
          builder: (context, state) => BlocProvider(
            create: (_) => sl<AuthBloc>(),
            child: const SignupScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.forgotPassword,
          builder: (context, state) => BlocProvider(
            create: (_) => sl<AuthBloc>(),
            child: const ForgotPasswordScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.home,
          builder: (context, state) => BlocProvider(
            create: (_) => sl<HomeBloc>()..add(const HomeStarted()),
            child: const HomeScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.chat,
          builder: (context, state) {
            final conversationId = state.extra as String?;
            return BlocProvider(
              create: (_) => sl<ChatBloc>()
                ..add(ChatStarted(conversationId: conversationId)),
              child: const ChatScreen(),
            );
          },
        ),
        GoRoute(
          path: RouteNames.voice,
          builder: (context, state) => BlocProvider(
            create: (_) =>
                sl<VoiceConversationBloc>()..add(const VoiceStarted()),
            child: const VoiceConversationScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.vision,
          builder: (context, state) => BlocProvider(
            create: (_) => sl<VisionBloc>()..add(const VisionStarted()),
            child: const VisionScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.liveVision,
          builder: (context, state) => BlocProvider(
            create: (_) => sl<LiveVisionBloc>()..add(const LiveVisionStarted()),
            child: const LiveVisionScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.ar,
          builder: (context, state) => BlocProvider(
            create: (_) => sl<ArBloc>()..add(const ArStarted()),
            child: const ArScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.multilingual,
          builder: (context, state) => BlocProvider(
            create: (_) =>
                sl<MultilingualBloc>()..add(const MultilingualStarted()),
            child: const MultilingualScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.translation,
          builder: (context, state) => BlocProvider(
            create: (_) =>
                sl<TranslationBloc>()..add(const TranslationStarted()),
            child: const TranslationScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.history,
          builder: (context, state) => BlocProvider(
            create: (_) => sl<HistoryBloc>()..add(const HistoryStarted()),
            child: const HistoryScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: RouteNames.personality,
          builder: (context, state) => BlocProvider(
            create: (_) =>
                sl<PersonalityBloc>()..add(const PersonalityStarted()),
            child: const PersonalityScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.memory,
          builder: (context, state) => BlocProvider(
            create: (_) => sl<MemoryBloc>()..add(const MemoryStarted()),
            child: const MemoryScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.planner,
          builder: (context, state) => BlocProvider(
            create: (_) => sl<PlannerBloc>()..add(const PlannerStarted()),
            child: const PlannerScreen(),
          ),
        ),
        GoRoute(
          path: RouteNames.characterSelection,
          builder: (context, state) => BlocProvider(
            create: (_) => sl<CharacterBloc>()..add(const CharacterStarted()),
            child: const CharacterSelectionScreen(),
          ),
        ),
      ],
    );
  }
}

/// Adapts a [Stream] into a [Listenable] so go_router re-runs its redirect when
/// the auth status changes. Standard go_router pattern.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription =
        stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
