import 'package:flutter/material.dart';

import '../../../../core/routing/route_names.dart';
import '../models/feature_tile.dart';
import 'home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl();

  @override
  List<FeatureTile> tiles() => const [
        FeatureTile(
          title: 'AI Chat',
          subtitle: 'Chat with your assistant',
          icon: Icons.chat_bubble_outline,
          color: Color(0xFF6C5CE7),
          route: RouteNames.chat,
        ),
        FeatureTile(
          title: 'Voice',
          subtitle: 'Talk hands-free',
          icon: Icons.mic_none,
          color: Color(0xFF00CEC9),
          route: RouteNames.voice,
        ),
        FeatureTile(
          title: 'Vision',
          subtitle: 'Analyze what you see',
          icon: Icons.camera_alt_outlined,
          color: Color(0xFFFD79A8),
          route: RouteNames.vision,
        ),
        FeatureTile(
          title: 'Multilingual',
          subtitle: 'Chat in any language',
          icon: Icons.translate,
          color: Color(0xFF0984E3),
          route: RouteNames.multilingual,
        ),
        FeatureTile(
          title: 'Translate',
          subtitle: 'Voice & text translation',
          icon: Icons.g_translate,
          color: Color(0xFFE17055),
          route: RouteNames.translation,
        ),
        FeatureTile(
          title: 'History',
          subtitle: 'Past conversations',
          icon: Icons.history,
          color: Color(0xFF636E72),
          route: RouteNames.history,
        ),
        FeatureTile(
          title: 'Personality',
          subtitle: 'Shape your assistant',
          icon: Icons.psychology,
          color: Color(0xFFA29BFE),
          route: RouteNames.personality,
        ),
        FeatureTile(
          title: 'Memory',
          subtitle: 'What the AI remembers',
          icon: Icons.bookmark_outline,
          color: Color(0xFF00B894),
          route: RouteNames.memory,
        ),
        FeatureTile(
          title: 'Settings',
          subtitle: 'Preferences & data',
          icon: Icons.settings_outlined,
          color: Color(0xFF2D3436),
          route: RouteNames.settings,
        ),
      ];
}
