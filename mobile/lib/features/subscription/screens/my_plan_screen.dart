import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/skeleton.dart';
import '../data/subscription_models.dart';
import '../providers/subscription_providers.dart';
import '../widgets/plan_widgets.dart';

class MyPlanScreen extends ConsumerStatefulWidget {
  const MyPlanScreen({super.key});

  @override
  ConsumerState<MyPlanScreen> createState() => _MyPlanScreenState();
}

class _MyPlanScreenState extends ConsumerState<MyPlanScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(subscriptionOverviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Plan')),
      body: overview.when(
        loading: () => const SkeletonPage(headerHeight: 170, rows: 4),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(subscriptionOverviewProvider)),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.refresh(subscriptionOverviewProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(Gaps.l),
            children: [
              _CurrentPlanCard(data: data).staggered(0),
              const SizedBox(height: Gaps.m),
              FilledButton.icon(
                onPressed: () => context.push(Routes.plans),
                icon: const Icon(Icons.workspace_premium_rounded),
                label: Text(data.current == null ? 'Choose a Plan' : 'Renew or Change Plan'),
              ).staggered(1),
              const SizedBox(height: Gaps.xl),
              PillTabs(
                labels: ['Plans (${data.history.length})', 'Payments (${data.payments.length})'],
                selected: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
              const SizedBox(height: Gaps.m),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _tab == 0 ? _HistoryList(key: const ValueKey('plans'), items: data.history) : _PaymentList(key: const ValueKey('payments'), items: data.payments),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({required this.data});

  final SubscriptionOverview data;

  @override
  Widget build(BuildContext context) {
    final current = data.current;
    if (current == null) {
      return const Card(
        child: EmptyView(
          icon: Icons.workspace_premium_outlined,
          title: 'No active plan',
          message: 'You can track habits for free. Choose a plan to add and manage customers.',
        ),
      );
    }

    final plan = current.plan!;
    final limit = data.maxCustomers;
    final usage = limit == null ? null : (data.customersCount / limit).clamp(0.0, 1.0);
    final totalDays = plan.durationDays == 0 ? 30 : plan.durationDays;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: AppColors.brand.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CURRENT PLAN', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(plan.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              ProgressRing(
                value: current.daysLeft / totalDays,
                size: 64,
                stroke: 6,
                color: AppColors.gold,
                trackColor: Colors.white.withValues(alpha: 0.2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedCount(value: current.daysLeft, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                    const Text('days', style: TextStyle(color: Colors.white70, fontSize: 9.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Gaps.m),
          Text(
            'Active until ${current.endsAt == null ? '-' : Fmt.chipDate(current.endsAt!)}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: Gaps.l),
          Row(
            children: [
              const Icon(Icons.groups_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                limit == null ? '${data.customersCount} customers (unlimited)' : '${data.customersCount} of $limit customers used',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ],
          ),
          if (usage != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: usage),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  color: usage >= 0.9 ? const Color(0xFFFF8A80) : AppColors.gold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({super.key, required this.items});

  final List<SubscriptionItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Card(child: EmptyView(icon: Icons.receipt_long_rounded, title: 'No plans yet', message: 'Your plan history appears here.'));
    }
    final p = context.palette;
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(indent: 16, endIndent: 16),
            Builder(builder: (context) {
              final item = items[i];
              final period = item.startsAt == null
                  ? '-'
                  : '${Fmt.shortDate(item.startsAt!)} - ${item.endsAt == null ? '' : Fmt.shortDate(item.endsAt!)}';
              final status = item.isCurrent ? 'Active' : capitalize(item.status);
              final statusColor = item.isCurrent ? AppColors.accent : (item.status == 'cancelled' ? AppColors.danger : p.textSecondary);
              return ListTile(
                leading: IconBadge(icon: Icons.workspace_premium_rounded, color: tierColors[item.plan?.tier]?.$1 ?? AppColors.gold),
                title: Text(item.plan?.name ?? 'Plan', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('$period  \u2022  ${item.source == 'manual' ? 'Assigned by admin' : 'Paid online'}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatRupees(item.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(status, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ).staggered(i);
            }),
          ],
        ],
      ),
    );
  }
}

class _PaymentList extends StatelessWidget {
  const _PaymentList({super.key, required this.items});

  final List<PaymentRecord> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Card(child: EmptyView(icon: Icons.payments_outlined, title: 'No payments yet', message: 'Receipts for your purchases appear here.'));
    }
    final p = context.palette;
    final dateFormat = DateFormat('dd MMM yyyy, h:mm a');
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(indent: 16, endIndent: 16),
            Builder(builder: (context) {
              final payment = items[i];
              return ListTile(
                leading: IconBadge(
                  icon: payment.isManual ? Icons.admin_panel_settings_outlined : Icons.receipt_long_rounded,
                  color: payment.isManual ? AppColors.info : AppColors.accent,
                ),
                title: Text(payment.planName ?? 'Plan', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(payment.createdAt == null ? '-' : dateFormat.format(payment.createdAt!)),
                    if (payment.razorpayPaymentId != null)
                      Text(payment.razorpayPaymentId!, style: TextStyle(fontSize: 11.5, color: p.textSecondary, fontFamily: 'monospace')),
                  ],
                ),
                isThreeLine: payment.razorpayPaymentId != null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(formatRupees(payment.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (payment.razorpayPaymentId != null)
                      IconButton(
                        tooltip: 'Copy payment ID',
                        icon: Icon(Icons.copy_rounded, size: 18, color: p.textSecondary),
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: payment.razorpayPaymentId!));
                          if (context.mounted) showSnack(context, 'Payment ID copied');
                        },
                      ),
                  ],
                ),
              ).staggered(i);
            }),
          ],
        ],
      ),
    );
  }
}
