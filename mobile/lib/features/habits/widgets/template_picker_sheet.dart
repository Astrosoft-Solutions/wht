import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/widgets/brand_loader.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/habit_icon.dart';
import '../../content/data/content_repository.dart';
import '../../content/providers/content_providers.dart';
import '../providers/habit_providers.dart';

Future<void> showTemplatePickerSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _TemplatePickerSheet(),
  );
}

/// Lets a coach copy habit templates managed by the superadmin into their own habits.
class _TemplatePickerSheet extends ConsumerStatefulWidget {
  const _TemplatePickerSheet();

  @override
  ConsumerState<_TemplatePickerSheet> createState() => _TemplatePickerSheetState();
}

class _TemplatePickerSheetState extends ConsumerState<_TemplatePickerSheet> {
  final _selected = <int>{};
  bool _saving = false;

  Future<void> _add() async {
    setState(() => _saving = true);
    try {
      await ref.read(contentRepositoryProvider).adoptMasterHabits(_selected.toList());
      ref.read(habitActionsProvider).refreshAll();
      if (!mounted) return;
      showSnack(context, '${_selected.length} habit${_selected.length == 1 ? '' : 's'} added');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showSnack(context, ApiException.from(e).message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(masterHabitsProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: context.palette.border, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text('Habit Templates', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Pick the habits to add to your schedule.', style: TextStyle(color: context.palette.textSecondary)),
          ),
          Expanded(
            child: templates.when(
              loading: () => const SkeletonList(count: 8),
              error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(masterHabitsProvider)),
              data: (items) => items.isEmpty
                  ? const EmptyView(icon: Icons.library_add_check_outlined, message: 'No templates available.')
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final habit = items[i];
                        return CheckboxListTile(
                          value: _selected.contains(habit.id),
                          activeColor: AppColors.brand,
                          checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          onChanged: (v) => setState(() => v == true ? _selected.add(habit.id) : _selected.remove(habit.id)),
                          secondary: HabitIcon(icon: habit.icon, color: habit.color),
                          title: Text(habit.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(habit.timeLabel),
                        ).staggered(i);
                      },
                    ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: LoadingButton(
                onPressed: _selected.isEmpty ? null : _add,
                busy: _saving,
                label: _selected.isEmpty ? 'Select habits' : 'Add ${_selected.length} habit${_selected.length == 1 ? '' : 's'}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}