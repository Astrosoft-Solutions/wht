import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/widgets/brand_loader.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/skeleton.dart';
import '../../auth/providers/auth_controller.dart';
import '../../customers/providers/customer_providers.dart';
import '../data/razorpay_payment.dart';
import '../data/subscription_models.dart';
import '../data/subscription_repository.dart';
import '../providers/subscription_providers.dart';
import '../widgets/plan_widgets.dart';

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  int? _busyPlanId;

  Future<void> _buy(Plan plan) async {
    setState(() => _busyPlanId = plan.id);
    final repo = ref.read(subscriptionRepositoryProvider);
    try {
      final order = await repo.checkout(plan.id);
      final result = await RazorpayPayment.pay(order);
      if (result == null) return;

      final message = await repo.verify(orderId: result.orderId, paymentId: result.paymentId, signature: result.signature);
      ref.invalidate(subscriptionOverviewProvider);
      ref.invalidate(customerListProvider);
      await ref.read(authControllerProvider.notifier).refresh();
      if (mounted) showSnack(context, message);
    } catch (e) {
      if (mounted) showSnack(context, ApiException.from(e).message, error: true);
    } finally {
      if (mounted) setState(() => _busyPlanId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(plansProvider);
    final overview = ref.watch(subscriptionOverviewProvider);
    final current = overview.value?.current;
    final paymentsEnabled = overview.value?.paymentsEnabled ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Choose a Plan')),
      body: plans.when(
        loading: () => const Shimmering(
          child: Padding(
            padding: EdgeInsets.all(Gaps.l),
            child: Column(children: [SkeletonCard(height: 70), SkeletonCard(height: 280), SkeletonCard(height: 280)]),
          ),
        ),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(plansProvider)),
        data: (list) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!RazorpayPayment.isSupported) const _WebNotice(),
            if (RazorpayPayment.isSupported && overview.hasValue && !paymentsEnabled)
              const _Notice(
                icon: Icons.info_outline,
                text: 'Online payments are not set up yet. Please contact the administrator to activate a plan.',
              ),
            if (current != null)
              _Notice(
                icon: Icons.workspace_premium,
                text: 'Your ${current.plan?.name} plan is active. Renewing adds time after it ends; '
                    'choosing a different plan starts it now and replaces the current one.',
              ),
            if (list.isEmpty) const EmptyView(icon: Icons.workspace_premium_outlined, message: 'No plans are available right now.'),
            for (var i = 0; i < list.length; i++)
              _PlanCard(
                plan: list[i],
                isCurrent: current?.plan?.id == list[i].id,
                busy: _busyPlanId == list[i].id,
                enabled: RazorpayPayment.isSupported && paymentsEnabled && _busyPlanId == null,
                onBuy: () => _buy(list[i]),
              ).staggered(i + 1, stepMs: 90),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.isCurrent, required this.busy, required this.enabled, required this.onBuy});

  final Plan plan;
  final bool isCurrent;
  final bool busy;
  final bool enabled;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final featured = plan.tier == 'gold';
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isCurrent ? p.primary : p.border, width: isCurrent ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (featured)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF9A825), Color(0xFFFFD54F)])),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_rounded, size: 16, color: Color(0xFF5D4037)),
                  SizedBox(width: 4),
                  Text('MOST POPULAR', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, letterSpacing: 1, color: Color(0xFF5D4037))),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TierChip(tier: plan.tier),
                    const Spacer(),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: p.mint, borderRadius: BorderRadius.circular(20)),
                        child: Text('Current plan', style: TextStyle(color: p.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(plan.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                if (plan.description != null) ...[
                  const SizedBox(height: 2),
                  Text(plan.description!, style: TextStyle(color: p.textSecondary, fontSize: 12.5)),
                ],
                const SizedBox(height: 8),
                Text.rich(TextSpan(children: [
                  TextSpan(
                    text: formatRupees(plan.price),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: p.primary),
                  ),
                  TextSpan(text: '  / ${plan.durationDays} days', style: TextStyle(color: p.textSecondary)),
                ])),
                const SizedBox(height: 12),
                _Feature(plan.maxCustomers == null ? 'Unlimited customers' : 'Up to ${plan.maxCustomers} customers'),
                for (final f in plan.features) _Feature(f),
                const SizedBox(height: 12),
                LoadingButton(
                  onPressed: enabled ? onBuy : null,
                  busy: busy,
                  icon: isCurrent ? Icons.autorenew_rounded : Icons.lock_outline_rounded,
                  label: isCurrent ? 'Renew - ${formatRupees(plan.price)}' : 'Pay ${formatRupees(plan.price)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: p.mint, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: p.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: p.primary))),
        ],
      ),
    );
  }
}

class _WebNotice extends StatelessWidget {
  const _WebNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: context.palette.tileOrange, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'In-app payment works on the Android and iOS apps. On the web, subscribe from the coach web panel.',
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () => launchUrl(Uri.parse(Env.adminPanelUrl)),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Open web panel'),
          ),
        ],
      ),
    );
  }
}
