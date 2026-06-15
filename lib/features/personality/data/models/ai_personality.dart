import 'package:equatable/equatable.dart';
import 'package:hive_ce/hive.dart';

/// A configurable AI persona. The [systemPrompt] is prepended to every model
/// request so the assistant adopts the chosen tone/behavior.
class AIPersonality extends Equatable {
  final String id;
  final String name;
  final String description;
  final String systemPrompt;

  /// Built-in presets cannot be deleted by the user.
  final bool isBuiltIn;

  const AIPersonality({
    required this.id,
    required this.name,
    required this.description,
    required this.systemPrompt,
    this.isBuiltIn = false,
  });

  AIPersonality copyWith({
    String? name,
    String? description,
    String? systemPrompt,
  }) =>
      AIPersonality(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        systemPrompt: systemPrompt ?? this.systemPrompt,
        isBuiltIn: isBuiltIn,
      );

  @override
  List<Object?> get props => [id, name, description, systemPrompt, isBuiltIn];

  /// Default presets seeded on first launch.
  static List<AIPersonality> get presets => const [
        AIPersonality(
          id: 'preset_friendly',
          name: 'Friendly Companion',
          description: 'Warm, encouraging and conversational.',
          systemPrompt:
              'You are a warm, friendly companion. Be supportive, conversational '
              'and concise. Show genuine interest in the user.',
          isBuiltIn: true,
        ),
        AIPersonality(
          id: 'preset_professional',
          name: 'Professional Assistant',
          description: 'Precise, formal and to the point.',
          systemPrompt:
              'You are a professional assistant. Provide accurate, well-structured '
              'and concise answers in a formal tone.',
          isBuiltIn: true,
        ),
        AIPersonality(
          id: 'preset_creative',
          name: 'Creative Muse',
          description: 'Imaginative, playful and idea-rich.',
          systemPrompt:
              'You are a creative muse. Be imaginative, playful and generate vivid '
              'ideas, while still being helpful.',
          isBuiltIn: true,
        ),
      ];
}

/// Manual Hive adapter (typeId 4).
class AIPersonalityAdapter extends TypeAdapter<AIPersonality> {
  @override
  final int typeId = 4;

  @override
  AIPersonality read(BinaryReader reader) {
    final fields = <int, dynamic>{
      for (var i = 0, n = reader.readByte(); i < n; i++)
        reader.readByte(): reader.read(),
    };
    return AIPersonality(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      systemPrompt: fields[3] as String,
      isBuiltIn: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AIPersonality obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.systemPrompt)
      ..writeByte(4)
      ..write(obj.isBuiltIn);
  }
}
