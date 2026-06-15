import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../avatar/presentation/companion_avatar.dart';
import '../../data/models/character_archetype.dart';
import '../../data/models/companion_character.dart';
import '../bloc/character_bloc.dart';

/// Lets the user browse and choose their AI companion. The selection is saved
/// immediately; the avatar preview is upgraded to the animated avatar in a
/// later phase.
class CharacterSelectionScreen extends StatelessWidget {
  const CharacterSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose your companion')),
      body: BlocBuilder<CharacterBloc, CharacterState>(
        builder: (context, state) {
          if (state.status == CharacterStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: _Header()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final character = state.characters[i];
                      return _CharacterCard(
                        character: character,
                        selected: character.id == state.activeId,
                        onTap: () => context
                            .read<CharacterBloc>()
                            .add(CharacterSelected(character.id)),
                      );
                    },
                    childCount: state.characters.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Who would you like to talk to?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Each companion has its own personality, voice and style. '
            'You can change this anytime.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final CompanionCharacter character;
  final bool selected;
  final VoidCallback onTap;

  const _CharacterCard({
    required this.character,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = character.archetype.accent;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? accent : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _AvatarPreview(character: character),
                  const Spacer(),
                  if (selected)
                    Icon(Icons.check_circle, color: accent, size: 22),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                character.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                character.archetype.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  character.description,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Live animated avatar preview for each companion card.
class _AvatarPreview extends StatelessWidget {
  final CompanionCharacter character;
  const _AvatarPreview({required this.character});

  @override
  Widget build(BuildContext context) {
    return AnimatedCompanionAvatar(
      archetype: character.archetype,
      emotion: character.defaultEmotion,
      size: 64,
    );
  }
}
