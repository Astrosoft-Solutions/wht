import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/widgets/common.dart';
import '../data/habit.dart';
import '../providers/habit_providers.dart';
import 'habit_form_sheet.dart';
import 'habit_tile.dart';

/// Habit rows separated by dividers, with toggle handling and an edit/delete menu on tap.
class HabitList extends ConsumerStatefulWidget {
  const HabitList({super.key, required this.habits, this.showProgress = false, this.dense = false, this.editable = true});

  final List<Habit> habits;
  final bool showProgress;
  final bool dense;
  final bool editable;

  @override
  ConsumerState<HabitList> createState() => _HabitListState();
}

class _HabitListState extends ConsumerState<HabitList> {
  final _busy = <int>{};

  /// Flipped immediately on tap so the checkmark responds before the server round-trip finishes.
  final _optimistic = <int, bool>{};

  Future<void> _toggle(Habit habit) async {
    if (_busy.contains(habit.id)) return;
    setState(() {
      _busy.add(habit.id);
      _optimistic[habit.id] = !habit.isCompleted;
    });
    try {
      await ref.read(habitActionsProvider).toggle(habit.id);
    } catch (e) {
      if (mounted) {
        setState(() => _optimistic.remove(habit.id));
        showSnack(context, ApiException.from(e).message, error: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy.remove(habit.id);
          final current = widget.habits.where((h) => h.id == habit.id).firstOrNull;
          if (current != null && _optimistic[habit.id] == current.isCompleted) _optimistic.remove(habit.id);
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant HabitList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Drop optimistic values once the refreshed data from the server agrees with them.
    for (final habit in widget.habits) {
      if (_optimistic[habit.id] == habit.isCompleted && !_busy.contains(habit.id)) {
        _optimistic.remove(habit.id);
      }
    }
  }

  Future<void> _openMenu(Habit habit) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(habit.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(habit.timeLabel),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit habit'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.danger),
              title: const Text('Delete habit', style: TextStyle(color: AppColors.danger)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;

    if (action == 'edit') {
      await showHabitFormSheet(context, habit: habit);
    } else if (action == 'delete') {
      final ok = await confirmDialog(context, title: 'Delete habit?', message: '"${habit.name}" and its history will be removed.');
      if (!ok) return;
      try {
        await ref.read(habitActionsProvider).delete(habit.id);
        if (mounted) showSnack(context, 'Habit deleted');
      } catch (e) {
        if (mounted) showSnack(context, ApiException.from(e).message, error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < widget.habits.length; i++) ...[
          if (i > 0) const Divider(indent: 64, endIndent: 14),
          Builder(builder: (context) {
            final base = widget.habits[i];
            final habit = _optimistic.containsKey(base.id) ? base.copyWith(isCompleted: _optimistic[base.id]) : base;
            return HabitTile(
              key: ValueKey(base.id),
              habit: habit,
              dense: widget.dense,
              showProgress: widget.showProgress,
              onToggle: () => _toggle(base),
              onTap: widget.editable ? () => _openMenu(base) : null,
            ).staggered(i);
          }),
        ],
      ],
    );
  }
}
