import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/models/plan_item.dart';
import '../bloc/planner_bloc.dart';

/// Phase 6 — the AI Planner screen: add reminders/goals with optional due
/// dates, check them off, and see what's due now. The companion also surfaces
/// due items proactively on Home.
class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planner')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      body: BlocBuilder<PlannerBloc, PlannerState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
            return const _EmptyView();
          }
          final due = state.dueNow;
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              if (due.isNotEmpty) ...[
                const _SectionHeader('Due now'),
                ...due.map((i) => _PlanTile(item: i)),
                const Divider(height: 24),
                const _SectionHeader('All plans'),
              ],
              ...state.items.map((i) => _PlanTile(item: i)),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddSheet(BuildContext context) async {
    final bloc = context.read<PlannerBloc>();
    final result = await showModalBottomSheet<_NewPlan>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddPlanSheet(),
    );
    if (result != null && result.title.trim().isNotEmpty) {
      bloc.add(PlannerItemAdded(
        title: result.title.trim(),
        notes: result.notes.trim(),
        dueAt: result.dueAt,
      ));
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  final PlanItem item;
  const _PlanTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final due = item.dueAt;
    final subtitleParts = <String>[
      if (item.notes.isNotEmpty) item.notes,
      if (due != null) _formatDue(due),
    ];
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade400,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) =>
          context.read<PlannerBloc>().add(PlannerItemDeleted(item.id)),
      child: ListTile(
        leading: Checkbox(
          value: item.done,
          onChanged: (_) =>
              context.read<PlannerBloc>().add(PlannerItemToggled(item.id)),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            decoration: item.done ? TextDecoration.lineThrough : null,
            color: item.done ? Theme.of(context).disabledColor : null,
          ),
        ),
        subtitle: subtitleParts.isEmpty ? null : Text(subtitleParts.join(' • ')),
        trailing: item.isOverdue
            ? const Icon(Icons.warning_amber, color: Colors.orange, size: 20)
            : null,
      ),
    );
  }

  String _formatDue(DateTime d) {
    final hasTime = d.hour != 0 || d.minute != 0;
    final datePart = DateFormat.MMMEd().format(d);
    return hasTime ? '$datePart, ${DateFormat.jm().format(d)}' : datePart;
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_note_outlined,
                size: 56, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            Text(
              'No plans yet.\nTap New to add a goal or reminder, and I\'ll keep '
              'an eye on it for you.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Lightweight value carried back from the add sheet.
class _NewPlan {
  final String title;
  final String notes;
  final DateTime? dueAt;
  const _NewPlan(this.title, this.notes, this.dueAt);
}

class _AddPlanSheet extends StatefulWidget {
  const _AddPlanSheet();

  @override
  State<_AddPlanSheet> createState() => _AddPlanSheetState();
}

class _AddPlanSheetState extends State<_AddPlanSheet> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _dueAt;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueAt ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt ?? now),
    );
    setState(() {
      _dueAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 0,
        time?.minute ?? 0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('New plan', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'What do you want to do?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _dueAt == null
                      ? 'No due date'
                      : 'Due ${DateFormat.MMMEd().add_jm().format(_dueAt!)}',
                ),
              ),
              TextButton.icon(
                onPressed: _pickDateTime,
                icon: const Icon(Icons.schedule),
                label: const Text('Set due'),
              ),
              if (_dueAt != null)
                IconButton(
                  onPressed: () => setState(() => _dueAt = null),
                  icon: const Icon(Icons.clear),
                ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              _NewPlan(_titleController.text, _notesController.text, _dueAt),
            ),
            child: const Text('Add plan'),
          ),
        ],
      ),
    );
  }
}
