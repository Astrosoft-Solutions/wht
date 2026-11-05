import '../../../core/utils/formatters.dart';

class Plan {
  const Plan({
    required this.id,
    required this.coachType,
    required this.tier,
    required this.name,
    this.description,
    required this.price,
    required this.currency,
    required this.durationDays,
    this.maxCustomers,
    this.features = const [],
  });

  final int id;
  final String coachType;

  /// gold, silver or bronze.
  final String tier;
  final String name;
  final String? description;
  final double price;
  final String currency;
  final int durationDays;

  /// Null means unlimited.
  final int? maxCustomers;
  final List<String> features;

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
        id: json['id'] as int,
        coachType: json['coach_type'] as String,
        tier: json['tier'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        price: toDouble(json['price']) ?? 0,
        currency: json['currency'] as String? ?? 'INR',
        durationDays: toInt(json['duration_days']) ?? 30,
        maxCustomers: toInt(json['max_customers']),
        features: ((json['features'] as List?) ?? const []).map((e) => e.toString()).toList(),
      );
}

class SubscriptionItem {
  const SubscriptionItem({
    required this.id,
    required this.status,
    required this.isCurrent,
    this.startsAt,
    this.endsAt,
    required this.daysLeft,
    required this.amount,
    required this.source,
    this.plan,
  });

  final int id;
  final String status;
  final bool isCurrent;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int daysLeft;
  final double amount;
  final String source;
  final Plan? plan;

  factory SubscriptionItem.fromJson(Map<String, dynamic> json) => SubscriptionItem(
        id: json['id'] as int,
        status: json['status'] as String,
        isCurrent: json['is_current'] as bool? ?? false,
        startsAt: json['starts_at'] == null ? null : DateTime.parse(json['starts_at'] as String).toLocal(),
        endsAt: json['ends_at'] == null ? null : DateTime.parse(json['ends_at'] as String).toLocal(),
        daysLeft: toInt(json['days_left']) ?? 0,
        amount: toDouble(json['amount']) ?? 0,
        source: json['source'] as String? ?? 'manual',
        plan: json['plan'] == null ? null : Plan.fromJson(json['plan'] as Map<String, dynamic>),
      );
}

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.event,
    required this.amount,
    this.razorpayPaymentId,
    this.planName,
    this.createdAt,
  });

  final int id;
  final String event;
  final double amount;
  final String? razorpayPaymentId;
  final String? planName;
  final DateTime? createdAt;

  bool get isManual => event == 'manual.assigned';

  factory PaymentRecord.fromJson(Map<String, dynamic> json) => PaymentRecord(
        id: json['id'] as int,
        event: json['event'] as String,
        amount: toDouble(json['amount']) ?? 0,
        razorpayPaymentId: json['razorpay_payment_id'] as String?,
        planName: json['plan_name'] as String?,
        createdAt: json['created_at'] == null ? null : DateTime.parse(json['created_at'] as String).toLocal(),
      );
}

class SubscriptionOverview {
  const SubscriptionOverview({
    this.current,
    required this.customersCount,
    this.maxCustomers,
    required this.history,
    this.payments = const [],
    required this.paymentsEnabled,
  });

  final SubscriptionItem? current;
  final int customersCount;
  final int? maxCustomers;
  final List<SubscriptionItem> history;
  final List<PaymentRecord> payments;
  final bool paymentsEnabled;

  /// Null when the coach may add another customer, otherwise the reason they cannot.
  String? get customerLimitReason {
    if (current == null) return 'You need an active plan to add customers. Choose a Gold, Silver or Bronze plan to continue.';
    final limit = maxCustomers;
    if (limit != null && customersCount >= limit) {
      return 'Your ${current!.plan?.name ?? 'plan'} allows up to $limit customers. Upgrade your plan to add more.';
    }
    return null;
  }

  factory SubscriptionOverview.fromJson(Map<String, dynamic> json) => SubscriptionOverview(
        current: json['current'] == null ? null : SubscriptionItem.fromJson(json['current'] as Map<String, dynamic>),
        customersCount: toInt(json['customers_count']) ?? 0,
        maxCustomers: toInt(json['max_customers']),
        history: (json['history'] as List).map((e) => SubscriptionItem.fromJson(e as Map<String, dynamic>)).toList(),
        payments: ((json['payments'] as List?) ?? const [])
            .map((e) => PaymentRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
        paymentsEnabled: json['payments_enabled'] as bool? ?? false,
      );
}

class CheckoutOrder {
  const CheckoutOrder({
    required this.orderId,
    required this.keyId,
    required this.amountPaise,
    required this.currency,
    required this.name,
    required this.description,
    required this.prefill,
  });

  final String orderId;
  final String keyId;
  final int amountPaise;
  final String currency;
  final String name;
  final String description;
  final Map<String, dynamic> prefill;

  factory CheckoutOrder.fromJson(Map<String, dynamic> json) => CheckoutOrder(
        orderId: json['order_id'] as String,
        keyId: json['key_id'] as String,
        amountPaise: toInt(json['amount']) ?? 0,
        currency: json['currency'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        prefill: Map<String, dynamic>.from(json['prefill'] as Map),
      );
}
