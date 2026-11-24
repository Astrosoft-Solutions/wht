import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/skeleton.dart';
import '../../subscription/data/subscription_models.dart';
import '../../subscription/providers/subscription_providers.dart';
import '../../subscription/widgets/plan_widgets.dart';
import '../data/customer_models.dart';
import '../data/customer_repository.dart';
import '../providers/customer_providers.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => setState(() => _query = value.trim()));
  }

  Future<void> _delete(Customer customer) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete customer?',
      message: '${customer.name} (${customer.code}) and all their records will be removed.',
    );
    if (!ok) return;
    try {
      await ref.read(customerRepositoryProvider).delete(customer.id);
      ref.invalidate(customerListProvider);
      ref.invalidate(subscriptionOverviewProvider);
      if (mounted) showSnack(context, 'Customer deleted');
    } catch (e) {
      if (mounted) showSnack(context, ApiException.from(e).message, error: true);
    }
  }

  /// Checks the plan limit before opening the form, so the coach isn't stopped after filling it in.
  Future<void> _add() async {
    try {
      final overview = await ref.read(subscriptionOverviewProvider.future);
      final reason = overview.customerLimitReason;
      if (!mounted) return;
      if (reason != null) {
        await showUpgradeDialog(context, reason);
        return;
      }
    } catch (_) {
      // If the plan can't be loaded, the server still enforces the limit when saving.
    }
    if (mounted) context.push(Routes.customerNew);
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customerListProvider(_query));
    final overview = ref.watch(subscriptionOverviewProvider).value;
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Records'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              onPressed: _add,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (overview != null) _LimitBanner(overview: overview),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by name, phone or id...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(Icons.close_rounded, color: p.textSecondary),
                        onPressed: () {
                          _search.clear();
                          _onSearchChanged('');
                        },
                      ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          Expanded(
            child: customers.when(
              loading: () => const SkeletonList(count: 7, padding: EdgeInsets.fromLTRB(16, 4, 16, 24)),
              error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(customerListProvider(_query))),
              data: (list) {
                if (list.isEmpty) {
                  return EmptyView(
                    icon: _query.isEmpty ? Icons.groups_outlined : Icons.search_off_rounded,
                    title: _query.isEmpty ? 'No customers yet' : 'No matches',
                    message: _query.isEmpty ? 'Add your first customer to start tracking progress.' : 'No customers match "$_query".',
                    action: _query.isEmpty
                        ? FilledButton.icon(
                            style: FilledButton.styleFrom(minimumSize: const Size(190, 46)),
                            onPressed: _add,
                            icon: const Icon(Icons.person_add_alt_1_rounded),
                            label: const Text('Add Customer'),
                          )
                        : null,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () {
                    ref.invalidate(subscriptionOverviewProvider);
                    return ref.refresh(customerListProvider(_query).future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _CustomerRow(customer: list[i], onDelete: () => _delete(list[i])).staggered(i),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LimitBanner extends StatelessWidget {
  const _LimitBanner({required this.overview});

  final SubscriptionOverview overview;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final limit = overview.maxCustomers;
    final count = overview.customersCount;
    final noPlan = overview.current == null;
    final full = !noPlan && limit != null && count >= limit;
    final ratio = limit == null || limit == 0 ? 0.0 : (count / limit).clamp(0.0, 1.0);
    final color = noPlan || full ? AppColors.danger : (ratio >= 0.8 ? AppColors.warning : AppColors.accent);

    return InkWell(
      onTap: () => context.push(noPlan || full ? Routes.plans : Routes.myPlan),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(noPlan ? Icons.lock_outline_rounded : Icons.groups_rounded, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    noPlan
                        ? 'No active plan'
                        : limit == null
                            ? '$count customers \u2022 Unlimited'
                            : '$count / $limit customers',
                    style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary),
                  ),
                  if (noPlan || full)
                    Text(
                      noPlan ? 'Choose a plan to add customers' : 'Limit reached. Upgrade to add more.',
                      style: TextStyle(fontSize: 12, color: p.textSecondary),
                    )
                  else if (limit != null) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: ratio, minHeight: 5, backgroundColor: p.mint, color: color),
                    ),
                  ],
                ],
              ),
            ),
            if (noPlan || full) ...[
              const SizedBox(width: 8),
              Text(noPlan ? 'Choose' : 'Upgrade', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            ],
          ],
        ),
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({required this.customer, required this.onDelete});

  final Customer customer;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final initials = customer.name.trim().split(RegExp(r'\s+')).take(2).map((w) => w.isEmpty ? '' : w[0].toUpperCase()).join();
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push(Routes.customerRecord(customer.id)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
          child: Row(
            children: [
              Hero(
                tag: 'customer-${customer.id}',
                child: Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: customer.isActive ? AppColors.brandGradient : null,
                    color: customer.isActive ? null : p.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    initials,
                    style: TextStyle(color: customer.isActive ? Colors.white : p.textSecondary, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(customer.code, style: TextStyle(color: p.textSecondary, fontSize: 12.5)),
                        const SizedBox(width: 10),
                        StatusDot(active: customer.isActive),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'record':
                      context.push(Routes.customerRecord(customer.id));
                    case 'photos':
                      context.push(Routes.customerBeforeAfter(customer.id));
                    case 'edit':
                      context.push(Routes.customerEdit(customer.id));
                    case 'delete':
                      onDelete();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'record', child: Text('Service Record')),
                  PopupMenuItem(value: 'photos', child: Text('Before & After')),
                  PopupMenuItem(value: 'edit', child: Text('Edit Details')),
                  PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.danger))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
