import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/skeleton.dart';
import '../../content/providers/content_providers.dart';
import '../../habits/data/habit_repository.dart';
import '../../habits/providers/habit_providers.dart';
import '../../habits/widgets/habit_list.dart';
import '../../subscription/data/plan_status.dart';
import '../../subscription/data/subscription_models.dart';
import '../../subscription/providers/subscription_providers.dart';
import '../../subscription/widgets/plan_widgets.dart';
import '../widgets/app_drawer.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const _previewCount = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    final unread = ref.watch(announcementsProvider).value?.unreadCount ?? 0;
    final subscription = ref.watch(subscriptionOverviewProvider).value;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(color: Colors.white),
        title: const Text('WellnessHabitTrack'),
        actions: [
          IconButton(
            tooltip: 'Announcements',
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              backgroundColor: AppColors.gold,
              textColor: Colors.black,
              child: const Icon(Icons.notifications_none_rounded),
            ),
            onPressed: () => context.push(Routes.announcements),
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.go(Routes.profile),
          ),
        ],
      ),
      body: dashboard.when(
        skipLoadingOnRefresh: true,
        loading: () => const _DashboardSkeleton(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(dashboardProvider)),
        data: (data) => RefreshIndicator(
          onRefresh: () {
            ref.invalidate(subscriptionOverviewProvider);
            ref.invalidate(announcementsProvider);
            return ref.refresh(dashboardProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 110),
            children: [
              _Header(data: data),
              // The content is pulled up so the stats card overlaps the green header.
              Transform.translate(
                offset: const Offset(0, -34),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Gaps.l),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _StatsCard(data: data).staggered(0),
                      const SizedBox(height: Gaps.l),
                      if (subscription != null) ...[
                        _PlanCard(overview: subscription).staggered(1),
                        const SizedBox(height: Gaps.l),
                      ],
                      _ScheduleCard(data: data, previewCount: _previewCount).staggered(2),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.data});

  final Dashboard data;

  @override
  Widget build(BuildContext context) {
    return GradientHeader(
      padding: const EdgeInsets.fromLTRB(Gaps.l, Gaps.s, Gaps.l, 56),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${Fmt.greeting(DateTime.now())},',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 15, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${data.user.firstName}!',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.waving_hand_rounded, color: AppColors.gold, size: 24),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_rounded, size: 13, color: Colors.white),
                const SizedBox(width: 6),
                Text(Fmt.chipDate(data.date), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.data});

  final Dashboard data;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: p.shadow, blurRadius: 18, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _Stat(
                top: const IconBadge(icon: Icons.local_fire_department_rounded, color: AppColors.warning, size: 38),
                value: AnimatedCount(value: data.completed, suffix: '/${data.total}', style: _valueStyle(context)),
                label: 'Habits',
              ),
            ),
            VerticalDivider(width: 1, color: p.border),
            Expanded(
              child: _Stat(
                top: ProgressRing(value: data.percent / 100, size: 38, stroke: 4.5),
                value: AnimatedCount(value: data.percent, suffix: '%', style: _valueStyle(context)),
                label: 'Completed',
              ),
            ),
            VerticalDivider(width: 1, color: p.border),
            Expanded(
              child: _Stat(
                top: const IconBadge(icon: Icons.emoji_events_rounded, color: AppColors.gold, size: 38),
                value: AnimatedCount(value: data.streak, style: _valueStyle(context)),
                label: 'Day Streak',
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle? _valueStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800);
}

class _Stat extends StatelessWidget {
  const _Stat({required this.top, required this.value, required this.label});

  final Widget top;
  final Widget value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 38, child: Center(child: top)),
        const SizedBox(height: 8),
        value,
        Text(label, style: TextStyle(fontSize: 12, color: context.palette.textSecondary)),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.overview});

  final SubscriptionOverview overview;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final status = PlanStatus.from(overview);
    final current = overview.current;
    final limit = overview.maxCustomers;

    if (status.needsAttention || status.state == PlanState.none) {
      final expired = status.state == PlanState.expired;
      final none = status.state == PlanState.none;
      final color = expired || none ? AppColors.danger : AppColors.warning;
      final title = switch (status.state) {
        PlanState.expired => 'Your ${status.planName ?? 'plan'} has expired',
        PlanState.none => 'No active plan',
        _ => 'Plan expires in ${status.daysLeft} day${status.daysLeft == 1 ? '' : 's'}',
      };
      final body = switch (status.state) {
        PlanState.expired => 'Renew to keep adding and managing customers.',
        PlanState.none => 'Choose a plan to add and manage customers.',
        _ => 'Renew now so your customers are not interrupted.',
      };
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            IconBadge(icon: expired || none ? Icons.error_outline_rounded : Icons.schedule_rounded, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary)),
                  Text(body, style: TextStyle(fontSize: 12.5, color: p.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 38), padding: const EdgeInsets.symmetric(horizontal: 14)),
              onPressed: () => context.push(Routes.plans),
              child: Text(none ? 'Choose' : 'Renew'),
            ),
          ],
        ),
      );
    }

    final plan = current!.plan!;
    final usage = limit == null ? null : (overview.customersCount / limit).clamp(0.0, 1.0);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push(Routes.myPlan),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              IconBadge(icon: Icons.workspace_premium_rounded, color: tierColors[plan.tier]?.$1 ?? AppColors.gold),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(plan.name, style: const TextStyle(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 6),
                        TierChip(tier: plan.tier),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${current.daysLeft} days left  \u2022  '
                      '${limit == null ? '${overview.customersCount} customers' : '${overview.customersCount}/$limit customers'}',
                      style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                    ),
                    if (usage != null) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(end: usage),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, _) => LinearProgressIndicator(
                            value: v,
                            minHeight: 5,
                            backgroundColor: p.mint,
                            color: usage >= 0.9 ? AppColors.danger : AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: p.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.data, required this.previewCount});

  final Dashboard data;
  final int previewCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text("Today's Habit Schedule", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
                TextButton(onPressed: () => context.go(Routes.habits), child: const Text('View All')),
              ],
            ),
          ),
          if (data.schedule.isEmpty)
            const EmptyView(
              icon: Icons.event_available_rounded,
              title: 'Nothing scheduled today',
              message: 'Tap + to add your first habit.',
            )
          else
            HabitList(habits: data.schedule.take(previewCount).toList(), dense: true, editable: false),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const GradientHeader(padding: EdgeInsets.fromLTRB(Gaps.l, Gaps.s, Gaps.l, 56), child: SizedBox(height: 56)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.l),
          child: Transform.translate(
            offset: const Offset(0, -34),
            child: const Shimmering(
              child: Column(
                children: [
                  SkeletonCard(height: 120),
                  SkeletonCard(height: 72),
                  SkeletonCard(height: 300),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
