import 'package:hive_ce/hive.dart';

import '../companion/models/companion_profile.dart';
import '../companion/models/relationship_state.dart';
import '../../features/character/data/models/character_archetype.dart';
import '../../features/character/data/models/companion_character.dart';
import '../../features/chat/data/models/chat_message.dart';
import '../../features/chat/data/models/chat_role.dart';
import '../../features/emotion/data/models/emotion.dart';
import '../../features/history/data/models/conversation.dart';
import '../../features/memory/data/models/memory_entry.dart';
import '../../features/personality/data/models/ai_personality.dart';
import '../../features/settings/data/models/app_settings.dart';
import '../constants/app_constants.dart';

/// Registers all Hive [TypeAdapter]s and opens the boxes used by the app.
///
/// Called once during startup (see `AppInitializer`).
class HiveRegistrar {
  HiveRegistrar._();

  static void registerAdapters() {
    _registerOnce(0, ChatRoleAdapter());
    _registerOnce(1, ChatMessageAdapter());
    _registerOnce(2, ConversationAdapter());
    _registerOnce(3, MemoryEntryAdapter());
    _registerOnce(4, AIPersonalityAdapter());
    _registerOnce(5, AppSettingsAdapter());
    // V2 companion adapters.
    _registerOnce(6, EmotionAdapter());
    _registerOnce(7, CharacterArchetypeAdapter());
    _registerOnce(8, CompanionCharacterAdapter());
    _registerOnce(9, RelationshipStateAdapter());
    _registerOnce(10, CompanionProfileAdapter());
  }

  static void _registerOnce<T>(int typeId, TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(typeId)) {
      Hive.registerAdapter<T>(adapter);
    }
  }

  static Future<void> openBoxes() async {
    await Future.wait([
      _open(AppConstants.conversationsBox),
      _open(AppConstants.messagesBox),
      _open(AppConstants.memoryBox),
      _open(AppConstants.personalityBox),
      _open(AppConstants.settingsBox),
      _open(AppConstants.characterBox),
      _open(AppConstants.relationshipBox),
      _open(AppConstants.profileBox),
    ]);
  }

  static Future<void> _open(String name) async {
    if (!Hive.isBoxOpen(name)) {
      await Hive.openBox(name);
    }
  }
}
