import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/widgets/brand_loader.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/skeleton.dart';
import '../data/habit.dart';
import '../providers/habit_providers.dart';
import '../widgets/habit_form_sheet.dart';
import '../widgets/habit_list.dart';

class DailyHabitsScreen extends ConsumerStatefulWidget {
  const DailyHabitsScreen({super.key});

  @override
  ConsumerState<DailyHabitsScreen> createState() => _DailyHabitsScreenState();
}

class _DailyHabitsScreenState extends ConsumerState<DailyHabitsScreen> {
  HabitRange _range = HabitRange.today;
  bool _completingAll = false;

  Future<void> _completeAll() async {
    setState(() => _completingAll = true);
    try {
      await ref.read(habitActionsProvider).completeAll();
      if (mounted) showSnack(context, 'All habits marked as completed');
    } catch (e) {
      if (mounted) showSnack(context, ApiException.from(e).message, error: true);
    } finally {
      if (mounted) setState(() => _completingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(habitScheduleProvider(_range));
    final isToday = _range == HabitRange.today;
    final allDone = schedule.value?.habits.every((h) => h.isCompleted) ?? false;

    final p = context.palette;
    final todayHabits = isToday ? schedule.value?.habits : null;
    final doneCount = todayHabits?.where((h) => h.isCompleted).length ?? 0;
    final total = todayHabits?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(color: Colors.white),
        title: const Text('Daily Habits'),
        actions: [
          IconButton(
            tooltip: 'Add habit',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => showHabitFormSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          GradientHeader(
            padding: const EdgeInsets.fromLTRB(Gaps.l, 0, Gaps.l, Gaps.l),
            child: Column(
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  child: isToday && total > 0
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: Gaps.m, top: Gaps.xs),
                          child: Row(
                            children: [
                              ProgressRing(
                                value: doneCount / total,
                                size: 46,
                                stroke: 5,
                                color: Colors.white,
                                trackColor: Colors.white.withValues(alpha: 0.2),
                                child: Text(
                                  '${(doneCount / total * 100).round()}%',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: Gaps.m),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      allDone ? 'All done for today!' : '$doneCount of $total habits done',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                                    ),
                                    Text(
                                      allDone ? 'Enjoy the rest of your day.' : 'Keep going, you are doing great.',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                _HeaderTabs(
                  range: _range,
                  onChanged: (r) => setState(() => _range = r),
                ),
              ],
            ),
          ),
          Expanded(
            child: schedule.when(
              loading: () => const SkeletonList(count: 8),
              error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(habitScheduleProvider(_range))),
              data: (data) {
                if (data.habits.isEmpty) {
                  return EmptyView(
                    icon: Icons.event_available_rounded,
                    title: 'No habits yet',
                    message: 'Create your first habit or pick from templates.',
                    action: FilledButton.icon(
                      style: FilledButton.styleFrom(minimumSize: const Size(180, 46)),
                      onPressed: () => showHabitFormSheet(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Habit'),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(habitScheduleProvider(_range).future),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
                    children: [
                      Card(child: HabitList(key: ValueKey(_range), habits: data.habits, showProgress: !isToday)),
                      if (!isToday)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'Completed days out of scheduled days so far in this period.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: p.textSecondary, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomSheet: isToday && (schedule.value?.habits.isNotEmpty ?? false)
          ? Container(
              color: p.background,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 46),
              child: LoadingButton(
                onPressed: allDone ? null : _completeAll,
                busy: _completingAll,
                label: allDone ? 'All Completed' : 'Mark All Completed',
                icon: allDone ? Icons.verified_rounded : Icons.done_all_rounded,
              ),
            )
          : null,
    );
  }
}

/// White-on-green version of the Today / Week / Month switch for the gradient header.
class _HeaderTabs extends StatelessWidget {
  const _HeaderTabs({required this.range, required this.onChanged});

  final HabitRange range;
  final ValueChanged<HabitRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 8) / HabitRange.values.length;
        return Container(
          height: 42,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(22)),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: width * range.index,
                top: 0,
                bottom: 0,
                width: width,
                child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18))),
              ),
              Row(
                children: [
                  for (final r in HabitRange.values)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(r),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: r == range ? AppColors.brand : Colors.white,
                            ),
                            child: Text(r.label),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
