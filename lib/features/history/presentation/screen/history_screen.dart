import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/route_names.dart';
import '../../data/models/conversation.dart';
import '../bloc/history_bloc.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversation History')),
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          if (state.status == HistoryStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.conversations.isEmpty) {
            return const Center(
              child: Text('No conversations yet.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.conversations.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final c = state.conversations[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Icon(_iconFor(c.kind))),
                  title: Text(c.title, maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    c.lastMessagePreview ?? _labelFor(c.kind),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat.MMMd().add_jm().format(c.updatedAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => context
                            .read<HistoryBloc>()
                            .add(HistoryItemDeleted(c.id)),
                      ),
                    ],
                  ),
                  onTap: () => context.push(RouteNames.chat, extra: c.id),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(ConversationKind kind) {
    switch (kind) {
      case ConversationKind.chat:
        return Icons.chat_bubble_outline;
      case ConversationKind.voice:
        return Icons.mic_none;
      case ConversationKind.vision:
        return Icons.camera_alt_outlined;
      case ConversationKind.multilingual:
        return Icons.translate;
      case ConversationKind.translation:
        return Icons.g_translate;
    }
  }

  String _labelFor(ConversationKind kind) => kind.name;
}
