import 'subscription_models.dart';

enum PlanState { none, active, expiringSoon, expired }

class PlanStatus {
  const PlanStatus(this.state, {this.daysLeft = 0, this.endedAt, this.planName});

  final PlanState state;
  final int daysLeft;
  final DateTime? endedAt;
  final String? planName;

  /// Shown as a warning banner on the dashboard.
  bool get needsAttention => state == PlanState.expiringSoon || state == PlanState.expired;

  static const warnDays = 7;

  factory PlanStatus.from(SubscriptionOverview overview, {DateTime? now}) {
    final current = overview.current;
    if (current != null) {
      return PlanStatus(
        current.daysLeft <= warnDays ? PlanState.expiringSoon : PlanState.active,
        daysLeft: current.daysLeft,
        planName: current.plan?.name,
      );
    }

    final today = now ?? DateTime.now();
    final ended = overview.history
        .where((s) => s.endsAt != null && s.endsAt!.isBefore(today) && s.status != 'cancelled')
        .toList()
      ..sort((a, b) => b.endsAt!.compareTo(a.endsAt!));
    if (ended.isNotEmpty) {
      return PlanStatus(PlanState.expired, endedAt: ended.first.endsAt, planName: ended.first.plan?.name);
    }
    return const PlanStatus(PlanState.none);
  }
}
