import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/ai_personality.dart';
import '../bloc/personality_bloc.dart';

class PersonalityScreen extends StatelessWidget {
  const PersonalityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Personality')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editDialog(context, null),
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      body: BlocBuilder<PersonalityBloc, PersonalityState>(
        builder: (context, state) {
          if (state.status == PersonalityStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.personalities.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final p = state.personalities[i];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.psychology)),
                  title: Text(p.name),
                  subtitle: Text(p.description),
                  trailing: p.isBuiltIn
                      ? const Chip(label: Text('Preset'))
                      : PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'edit') _editDialog(context, p);
                            if (v == 'delete') {
                              context
                                  .read<PersonalityBloc>()
                                  .add(PersonalityDeleted(p.id));
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                                value: 'delete', child: Text('Delete')),
                          ],
                        ),
                  onTap: p.isBuiltIn ? null : () => _editDialog(context, p),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _editDialog(BuildContext context, AIPersonality? existing) async {
    final bloc = context.read<PersonalityBloc>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl =
        TextEditingController(text: existing?.description ?? '');
    final promptCtrl =
        TextEditingController(text: existing?.systemPrompt ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'New personality' : 'Edit personality'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: promptCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'System prompt',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );

    if (saved == true && nameCtrl.text.trim().isNotEmpty) {
      final personality = AIPersonality(
        id: existing?.id ?? const Uuid().v4(),
        name: nameCtrl.text.trim(),
        description: descCtrl.text.trim(),
        systemPrompt: promptCtrl.text.trim(),
      );
      bloc.add(PersonalitySaved(personality));
    }
  }
}
