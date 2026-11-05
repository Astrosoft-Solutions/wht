import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_habit_tracker/core/theme/app_colors.dart';
import 'package:wellness_habit_tracker/features/subscription/data/plan_status.dart';
import 'package:wellness_habit_tracker/features/subscription/data/subscription_models.dart';

Plan plan({int? maxCustomers = 10}) => Plan(
      id: 1,
      coachType: 'coach',
      tier: 'gold',
      name: 'Coach Gold',
      price: 3999,
      currency: 'INR',
      durationDays: 30,
      maxCustomers: maxCustomers,
    );

SubscriptionItem item({required int daysLeft, bool current = true, String status = 'active', DateTime? endsAt}) =>
    SubscriptionItem(
      id: 1,
      status: status,
      isCurrent: current,
      endsAt: endsAt,
      daysLeft: daysLeft,
      amount: 3999,
      source: 'app',
      plan: plan(),
    );

SubscriptionOverview overview({SubscriptionItem? current, List<SubscriptionItem> history = const [], int customers = 0, int? max = 10}) =>
    SubscriptionOverview(current: current, customersCount: customers, maxCustomers: max, history: history, paymentsEnabled: true);

void main() {
  final now = DateTime(2026, 11, 5);

  group('PlanStatus', () {
    test('active plan with plenty of days is not flagged', () {
      final status = PlanStatus.from(overview(current: item(daysLeft: 20)), now: now);
      expect(status.state, PlanState.active);
      expect(status.needsAttention, isFalse);
    });

    test('plan ending within 7 days is expiring soon', () {
      final status = PlanStatus.from(overview(current: item(daysLeft: 3)), now: now);
      expect(status.state, PlanState.expiringSoon);
      expect(status.daysLeft, 3);
      expect(status.needsAttention, isTrue);
    });

    test('no current plan but an ended one in history is expired', () {
      final ended = item(daysLeft: 0, current: false, status: 'expired', endsAt: DateTime(2026, 11, 1));
      final status = PlanStatus.from(overview(history: [ended]), now: now);
      expect(status.state, PlanState.expired);
      expect(status.endedAt, DateTime(2026, 11, 1));
    });

    test('cancelled plans do not count as expired, and an empty history means no plan', () {
      final cancelled = item(daysLeft: 0, current: false, status: 'cancelled', endsAt: DateTime(2026, 10, 1));
      expect(PlanStatus.from(overview(history: [cancelled]), now: now).state, PlanState.none);
      expect(PlanStatus.from(overview(), now: now).state, PlanState.none);
    });
  });

  group('customerLimitReason', () {
    test('blocks when there is no plan or the limit is reached', () {
      expect(overview().customerLimitReason, isNotNull);
      expect(overview(current: item(daysLeft: 10), customers: 10, max: 10).customerLimitReason, contains('up to 10'));
    });

    test('allows below the limit and on unlimited plans', () {
      expect(overview(current: item(daysLeft: 10), customers: 9, max: 10).customerLimitReason, isNull);
      expect(overview(current: item(daysLeft: 10), customers: 500, max: null).customerLimitReason, isNull);
    });
  });

  test('AppPalette interpolates between light and dark', () {
    final mid = AppPalette.light.lerp(AppPalette.dark, 0.5);
    expect(mid.background, Color.lerp(AppPalette.light.background, AppPalette.dark.background, 0.5));
    expect(AppPalette.light.lerp(null, 0.5), same(AppPalette.light));
    expect(AppPalette.light.lerp(AppPalette.dark, 1).textPrimary, AppPalette.dark.textPrimary);
  });
}
