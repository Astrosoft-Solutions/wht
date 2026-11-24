import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/habit_icon.dart';
import '../data/habit.dart';

/// One row of the schedule: icon, time, name and a completion control.
class HabitTile extends StatelessWidget {
  const HabitTile({
    super.key,
    required this.habit,
    required this.onToggle,
    this.onTap,
    this.showProgress = false,
    this.dense = false,
  });

  final Habit habit;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;
  final bool showProgress;
  final bool dense;

  bool get _isCurrent {
    if (habit.isCompleted || !habit.isScheduledToday) return false;
    final now = TimeOfDay.now();
    final minutes = now.hour * 60 + now.minute;
    int toMinutes(String t) {
      final p = t.split(':');
      return int.parse(p[0]) * 60 + int.parse(p[1]);
    }

    final start = toMinutes(habit.startTime);
    final end = habit.endTime != null ? toMinutes(habit.endTime!) : start + 30;
    return minutes >= start && minutes <= end;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final done = habit.isCompleted && !showProgress;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: dense ? 10 : 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: parseHexColor(habit.color).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: HabitIcon(icon: habit.icon, color: habit.color, size: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: done ? p.textSecondary : p.textPrimary,
                      decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
                      decorationColor: p.textSecondary,
                    ),
                    child: Text(habit.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 12, color: p.textSecondary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          habit.timeLabel,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: p.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (_isCurrent) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                          child: const Text('NOW', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.accent)),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .fade(begin: 0.55, end: 1, duration: 900.ms),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (showProgress) _Progress(habit: habit) else _CheckButton(done: habit.isCompleted, current: _isCurrent, onTap: onToggle),
          ],
        ),
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  const _CheckButton({required this.done, required this.current, required this.onTap});

  final bool done;
  final bool current;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      checked: done,
      label: done ? 'Mark as not done' : 'Mark as done',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap!();
              },
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
              child: child,
            ),
            child: done
                ? Container(
                    key: const ValueKey('done'),
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                  )
                : Container(
                    key: const ValueKey('todo'),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: current ? AppColors.accent : p.border, width: 2.2),
                    ),
                    child: current ? const Icon(Icons.play_arrow_rounded, size: 16, color: AppColors.accent) : null,
                  ),
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final done = habit.completedCount ?? 0;
    final total = habit.scheduledCount ?? 0;
    final ratio = total == 0 ? 0.0 : done / total;
    return SizedBox(
      width: 64,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('$done/$total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: p.primary)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: ratio),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: 5, backgroundColor: p.mint, color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}
