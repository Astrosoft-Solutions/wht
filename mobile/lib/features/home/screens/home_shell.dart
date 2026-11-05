import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../habits/providers/habit_providers.dart';
import '../../habits/widgets/habit_form_sheet.dart';
import '../../reminders/reminder_providers.dart';
import '../../reminders/reminder_service.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> with WidgetsBindingObserver {
  late final ConfettiController _confetti = ConfettiController(duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onStart());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _confetti.dispose();
    super.dispose();
  }

  void _celebrate() {
    HapticFeedback.mediumImpact();
    _confetti.play();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        backgroundColor: AppColors.brand,
        content: Row(
          children: [
            Icon(Icons.emoji_events_rounded, color: AppColors.gold),
            SizedBox(width: 10),
            Expanded(child: Text('All habits done for today. Great work!', style: TextStyle(color: Colors.white))),
          ],
        ),
      ));
  }

  /// Reminders are planned only a day or two ahead, so they are refreshed whenever the app comes back.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.read(reminderSyncProvider).sync();
  }

  Future<void> _onStart() async {
    if (await ReminderService.instance.launchedFromReminder() && mounted) {
      context.go(Routes.habits);
    }
    await ref.read(reminderSyncProvider).sync();
  }

  void _go(int index) => widget.shell.goBranch(index, initialLocation: index == widget.shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final shell = widget.shell;
    ref.listen(celebrationProvider, (_, _) => _celebrate());
    return Scaffold(
      body: Stack(
        children: [
          shell,
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.06,
              numberOfParticles: 18,
              maxBlastForce: 22,
              minBlastForce: 8,
              gravity: 0.25,
              colors: const [AppColors.brand, AppColors.accent, AppColors.gold, Color(0xFFA5D6A7), Colors.white],
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.brandGradient,
          boxShadow: [BoxShadow(color: AppColors.brand.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: FloatingActionButton(
          tooltip: 'Add habit',
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          onPressed: () {
            HapticFeedback.selectionClick();
            showHabitFormSheet(context);
          },
          child: const Icon(Icons.add_rounded, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        elevation: 12,
        shadowColor: context.palette.shadow,
        height: 66,
        padding: EdgeInsets.zero,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: Row(
          children: [
            _NavItem(icon: Icons.home_rounded, label: 'Home', selected: shell.currentIndex == 0, onTap: () => _go(0)),
            _NavItem(icon: Icons.grid_view_rounded, label: 'Habits', selected: shell.currentIndex == 1, onTap: () => _go(1)),
            const SizedBox(width: 64),
            _NavItem(icon: Icons.bar_chart_rounded, label: 'Reports', selected: shell.currentIndex == 2, onTap: () => _go(2)),
            _NavItem(icon: Icons.person_rounded, label: 'Profile', selected: shell.currentIndex == 3, onTap: () => _go(3)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = selected ? p.primary : p.textSecondary;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
              decoration: BoxDecoration(
                color: selected ? p.mint : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedScale(
                scale: selected ? 1.1 : 1,
                duration: const Duration(milliseconds: 250),
                child: Icon(icon, color: color),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(fontSize: 11.5, color: color, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
