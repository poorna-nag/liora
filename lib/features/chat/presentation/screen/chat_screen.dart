import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/message_bubble.dart';
import '../../../avatar/presentation/avatar_activity.dart';
import '../../../avatar/presentation/companion_avatar.dart';
import '../../../character/data/models/character_archetype.dart';
import '../../../character/data/repositories/character_repository.dart';
import '../../../emotion/data/models/emotion.dart';
import '../bloc/chat_bloc.dart';

/// Generic chat UI, reused by the chat and multilingual features via the
/// [ChatBloc] provided above it.
class ChatScreen extends StatelessWidget {
  final String title;
  const ChatScreen({super.key, this.title = 'AI Chat'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          const _CompanionHeader(),
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listenWhen: (prev, curr) => curr.status == ChatStatus.error,
              listener: (context, state) {
                if (state.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.errorMessage!)),
                  );
                }
              },
              builder: (context, state) {
                if (state.status == ChatStatus.initial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.messages.isEmpty) {
                  return const _EmptyState();
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: state.messages.length,
                  itemBuilder: (context, i) {
                    final m = state.messages[i];
                    return MessageBubble(
                      text: m.content,
                      isUser: m.isUser,
                      imagePath: m.imagePath,
                    );
                  },
                );
              },
            ),
          ),
          const _Composer(),
        ],
      ),
    );
  }
}

/// Shows the active companion's animated avatar reacting to the conversation:
/// it thinks while the reply is composing and expresses the reply's emotion.
class _CompanionHeader extends StatelessWidget {
  const _CompanionHeader();

  @override
  Widget build(BuildContext context) {
    final character = sl<CharacterRepository>().getActiveOrDefault();
    return BlocBuilder<ChatBloc, ChatState>(
      buildWhen: (a, b) =>
          a.emotion != b.emotion || a.activity != b.activity,
      builder: (context, state) {
        final mood = state.activity == AvatarActivity.thinking
            ? 'Thinking…'
            : '${state.emotion.emoji}  ${state.emotion.label}';
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                character.archetype.accent.withValues(alpha: 0.14),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedCompanionAvatar(
                archetype: character.archetype,
                emotion: state.emotion,
                activity: state.activity,
                size: 132,
              ),
              Text(
                character.name,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                mood,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          const Text('Say hello to start the conversation.'),
        ],
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer();

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<ChatBloc>().add(ChatMessageSent(text));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isSending =
        context.select((ChatBloc b) => b.state.status == ChatStatus.sending);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(context),
                decoration: const InputDecoration(
                  hintText: 'Type a message…',
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (isSending)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton.filled(
                onPressed: () => _send(context),
                icon: const Icon(Icons.send),
              ),
          ],
        ),
      ),
    );
  }
}
