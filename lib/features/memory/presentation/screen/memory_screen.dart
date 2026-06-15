import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/memory_bloc.dart';

class MemoryScreen extends StatelessWidget {
  const MemoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Memory'),
        actions: [
          BlocBuilder<MemoryBloc, MemoryState>(
            builder: (context, state) => state.entries.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Clear all',
                    icon: const Icon(Icons.delete_sweep_outlined),
                    onPressed: () =>
                        context.read<MemoryBloc>().add(const MemoryCleared()),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Remember'),
      ),
      body: BlocBuilder<MemoryBloc, MemoryState>(
        builder: (context, state) {
          if (state.status == MemoryStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.entries.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Save facts you want the assistant to remember across '
                  'conversations, like your name or preferences.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final e = state.entries[i];
              return Card(
                child: ListTile(
                  leading: IconButton(
                    icon: Icon(
                      e.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                      color: e.pinned
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    onPressed: () => context
                        .read<MemoryBloc>()
                        .add(MemoryUpdated(e.copyWith(pinned: !e.pinned))),
                  ),
                  title: Text(e.content),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () =>
                        context.read<MemoryBloc>().add(MemoryDeleted(e.id)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addDialog(BuildContext context) async {
    final bloc = context.read<MemoryBloc>();
    final controller = TextEditingController();
    var pinned = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add memory'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'e.g. My name is Aditya',
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pin (always remembered)'),
                value: pinned,
                onChanged: (v) => setState(() => pinned = v ?? false),
              ),
            ],
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
      ),
    );

    if (saved == true && controller.text.trim().isNotEmpty) {
      bloc.add(MemoryAdded(controller.text.trim(), pinned: pinned));
    }
  }
}
