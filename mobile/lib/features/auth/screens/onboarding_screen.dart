import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/onboarding_provider.dart';

class _Page {
  const _Page(this.title, this.body, this.icons);
  final String title;
  final String body;
  final List<(IconData, Color)> icons;
}

const _pages = [
  _Page(
    'Build Healthy Habits Everyday',
    'Track your fitness, hydration, meals, prayer, sleep and more, all in one place.',
    [(Icons.self_improvement, AppColors.warning), (Icons.event_available, AppColors.brandLight)],
  ),
  _Page(
    'Stay On Schedule',
    'Plan every habit by the clock and get gentle reminders until it is done.',
    [(Icons.notifications_active_rounded, AppColors.info), (Icons.water_drop, AppColors.info)],
  ),
  _Page(
    'Manage Your Customers',
    'Record measurements, follow programmes and compare before & after progress.',
    [(Icons.groups, AppColors.brandLight), (Icons.monitor_weight, AppColors.warning)],
  ),
  _Page(
    'See Your Progress',
    'Streaks, completion rates and trends keep you motivated every week.',
    [(Icons.insights, AppColors.brandLight), (Icons.emoji_events, AppColors.gold)],
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() => ref.read(onboardingSeenProvider.notifier).markSeen();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isLast = _index == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                opacity: isLast ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: TextButton(onPressed: isLast ? null : _finish, child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600))),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _OnboardingPage(key: ValueKey(i), page: _pages[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _index ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _index ? AppColors.brand : p.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: FilledButton(
                onPressed: isLast
                    ? _finish
                    : () => _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(isLast ? 'Get Started' : 'Next'),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({super.key, required this.page});

  final _Page page;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(width: 240, height: 240, decoration: BoxDecoration(color: p.mint, shape: BoxShape.circle))
                    .animate()
                    .scale(begin: const Offset(0.85, 0.85), duration: 500.ms, curve: Curves.easeOutBack),
                const Positioned(left: 18, bottom: 30, child: Icon(Icons.eco, size: 64, color: AppColors.accent)),
                const Positioned(right: 14, top: 30, child: Icon(Icons.eco, size: 52, color: AppColors.brandLight)),
                Positioned(
                  right: 60,
                  top: 50,
                  child: _IconBadge(icon: page.icons[1].$1, color: page.icons[1].$2, size: 72)
                      .animate(delay: 150.ms)
                      .fadeIn()
                      .slideY(begin: -0.3, end: 0, curve: Curves.easeOutBack),
                ),
                Positioned(
                  left: 60,
                  bottom: 40,
                  child: _IconBadge(icon: page.icons[0].$1, color: page.icons[0].$2, size: 96)
                      .animate(delay: 250.ms)
                      .fadeIn()
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOutBack)
                      .then()
                      .shimmer(duration: 1200.ms, color: Colors.white54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, height: 1.2),
          ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2, end: 0),
          const SizedBox(height: 12),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: p.textSecondary, height: 1.45),
          ).animate(delay: 320.ms).fadeIn(),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color, required this.size});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [BoxShadow(color: p.shadow, blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Icon(icon, color: color, size: size * 0.55),
    );
  }
}
