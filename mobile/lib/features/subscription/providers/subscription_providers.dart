import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/subscription_models.dart';
import '../data/subscription_repository.dart';

final subscriptionOverviewProvider = FutureProvider.autoDispose<SubscriptionOverview>(
  (ref) => ref.watch(subscriptionRepositoryProvider).overview(),
);

final plansProvider = FutureProvider.autoDispose<List<Plan>>(
  (ref) => ref.watch(subscriptionRepositoryProvider).plans(),
);
