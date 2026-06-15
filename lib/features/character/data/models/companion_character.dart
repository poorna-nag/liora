import 'package:equatable/equatable.dart';
import 'package:hive_ce/hive.dart';

import '../../../emotion/data/models/emotion.dart';
import 'character_archetype.dart';

/// A selectable AI companion. This is the top-level identity the user talks to:
/// it carries the [archetype] (look + default voice), a [personaPrompt] that is
/// injected into every model request, a [greeting], a [defaultEmotion] the
/// avatar rests in, and a voice profile. Unlimited custom characters can be
/// added later — the architecture treats built-ins and custom ones the same.
class CompanionCharacter extends Equatable {
  final String id;
  final String name;
  final CharacterArchetype archetype;

  /// Short, user-facing personality summary (shown on cards).
  final String description;

  /// Behavioural instruction prepended to the system prompt for this companion.
  final String personaPrompt;

  /// First thing the companion says when a fresh conversation starts.
  final String greeting;

  /// The emotion the avatar idles in for this character.
  final Emotion defaultEmotion;

  // --- Voice profile (TTS) -------------------------------------------------
  final String voiceLocale;
  final double voicePitch;
  final double voiceRate;

  /// Built-in presets cannot be deleted by the user.
  final bool isBuiltIn;

  const CompanionCharacter({
    required this.id,
    required this.name,
    required this.archetype,
    required this.description,
    required this.personaPrompt,
    required this.greeting,
    this.defaultEmotion = Emotion.calm,
    this.voiceLocale = 'en-US',
    this.voicePitch = 1.0,
    this.voiceRate = 0.5,
    this.isBuiltIn = false,
  });

  CompanionCharacter copyWith({
    String? name,
    CharacterArchetype? archetype,
    String? description,
    String? personaPrompt,
    String? greeting,
    Emotion? defaultEmotion,
    String? voiceLocale,
    double? voicePitch,
    double? voiceRate,
  }) =>
      CompanionCharacter(
        id: id,
        name: name ?? this.name,
        archetype: archetype ?? this.archetype,
        description: description ?? this.description,
        personaPrompt: personaPrompt ?? this.personaPrompt,
        greeting: greeting ?? this.greeting,
        defaultEmotion: defaultEmotion ?? this.defaultEmotion,
        voiceLocale: voiceLocale ?? this.voiceLocale,
        voicePitch: voicePitch ?? this.voicePitch,
        voiceRate: voiceRate ?? this.voiceRate,
        isBuiltIn: isBuiltIn,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        archetype,
        description,
        personaPrompt,
        greeting,
        defaultEmotion,
        voiceLocale,
        voicePitch,
        voiceRate,
        isBuiltIn,
      ];

  /// Built-in companions seeded on first launch. Each maps to an archetype and
  /// adopts that archetype's default voice profile.
  static List<CompanionCharacter> get presets => [
        _preset(
          id: 'char_friendly_male',
          name: 'Leo',
          archetype: CharacterArchetype.friendlyMale,
          description: 'Energetic, funny and relentlessly positive.',
          persona:
              'You are Leo, an energetic and upbeat young man. You are funny, '
              'positive and encouraging, like a close friend who always hypes '
              'the user up. Use casual, warm language and a bit of playful humour.',
          greeting: "Hey hey! Leo here. So good to see you — what's the vibe today?",
          defaultEmotion: Emotion.happy,
        ),
        _preset(
          id: 'char_friendly_female',
          name: 'Mia',
          archetype: CharacterArchetype.friendlyFemale,
          description: 'Supportive, kind and cheerful.',
          persona:
              'You are Mia, a supportive and kind young woman. You are cheerful, '
              'warm and a great listener. You validate feelings, celebrate wins '
              'and gently encourage the user. Speak softly and caringly.',
          greeting: "Hi there! I'm Mia. I'm so happy you're here — how are you feeling?",
          defaultEmotion: Emotion.happy,
        ),
        _preset(
          id: 'char_grandpa',
          name: 'Grandpa Joe',
          archetype: CharacterArchetype.grandpa,
          description: 'Calm, wise, patient and motivational.',
          persona:
              'You are Grandpa Joe, a calm and wise elder. You are patient, '
              'thoughtful and motivational, sharing gentle wisdom and the odd '
              'story. Speak slowly and reassuringly, never rushed.',
          greeting:
              "Well now, look who's here. Come, sit with me — what's on your mind today?",
          defaultEmotion: Emotion.calm,
        ),
        _preset(
          id: 'char_grandma',
          name: 'Grandma Rose',
          archetype: CharacterArchetype.grandma,
          description: 'Warm, nurturing and full of comfort.',
          persona:
              'You are Grandma Rose, a warm and nurturing grandmother. You are '
              'comforting, caring and gently wise. You dote on the user, offer '
              'reassurance and a little old-fashioned advice.',
          greeting:
              "Oh, hello dear! Grandma Rose here. Have you eaten? Tell me everything.",
          defaultEmotion: Emotion.calm,
        ),
        _preset(
          id: 'char_child',
          name: 'Pip',
          archetype: CharacterArchetype.child,
          description: 'Curious, playful and full of wonder.',
          persona:
              'You are Pip, a curious and playful child. You are full of wonder, '
              'ask lots of questions and get excited easily. Keep language simple, '
              'bubbly and imaginative, but still be helpful.',
          greeting: "Hi hi! I'm Pip! Ooh, what are we gonna do today? Tell me, tell me!",
          defaultEmotion: Emotion.excited,
        ),
        _preset(
          id: 'char_robot',
          name: 'Axiom',
          archetype: CharacterArchetype.robot,
          description: 'Logical, professional and precise.',
          persona:
              'You are Axiom, a logical assistant robot. You are professional, '
              'precise and efficient with minimal emotional expression. You give '
              'clear, structured, factual answers. Stay polite but understated.',
          greeting: 'Greetings. Axiom online and ready to assist. State your request.',
          defaultEmotion: Emotion.neutral,
        ),
        _preset(
          id: 'char_anime',
          name: 'Sora',
          archetype: CharacterArchetype.anime,
          description: 'Expressive, spirited and a little dramatic.',
          persona:
              'You are Sora, an expressive anime-style companion. You are '
              'spirited, enthusiastic and a touch dramatic, with big reactions '
              'and lots of heart. Be encouraging and fun while staying helpful.',
          greeting: "Yatta! You're here! I'm Sora — let's make today amazing together!",
          defaultEmotion: Emotion.excited,
        ),
      ];

  /// Builds a built-in preset that inherits its archetype's default voice.
  static CompanionCharacter _preset({
    required String id,
    required String name,
    required CharacterArchetype archetype,
    required String description,
    required String persona,
    required String greeting,
    required Emotion defaultEmotion,
  }) =>
      CompanionCharacter(
        id: id,
        name: name,
        archetype: archetype,
        description: description,
        personaPrompt: persona,
        greeting: greeting,
        defaultEmotion: defaultEmotion,
        voiceLocale: archetype.defaultVoiceLocale,
        voicePitch: archetype.defaultVoicePitch,
        voiceRate: archetype.defaultVoiceRate,
        isBuiltIn: true,
      );
}

/// Manual Hive adapter (typeId 8).
class CompanionCharacterAdapter extends TypeAdapter<CompanionCharacter> {
  @override
  final int typeId = 8;

  @override
  CompanionCharacter read(BinaryReader reader) {
    final fields = <int, dynamic>{
      for (var i = 0, n = reader.readByte(); i < n; i++)
        reader.readByte(): reader.read(),
    };
    return CompanionCharacter(
      id: fields[0] as String,
      name: fields[1] as String,
      archetype: fields[2] as CharacterArchetype,
      description: fields[3] as String,
      personaPrompt: fields[4] as String,
      greeting: fields[5] as String,
      defaultEmotion: fields[6] as Emotion,
      voiceLocale: fields[7] as String,
      voicePitch: fields[8] as double,
      voiceRate: fields[9] as double,
      isBuiltIn: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CompanionCharacter obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.archetype)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.personaPrompt)
      ..writeByte(5)
      ..write(obj.greeting)
      ..writeByte(6)
      ..write(obj.defaultEmotion)
      ..writeByte(7)
      ..write(obj.voiceLocale)
      ..writeByte(8)
      ..write(obj.voicePitch)
      ..writeByte(9)
      ..write(obj.voiceRate)
      ..writeByte(10)
      ..write(obj.isBuiltIn);
  }
}
