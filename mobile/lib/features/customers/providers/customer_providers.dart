import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../subscription/providers/subscription_providers.dart';
import '../data/customer_models.dart';
import '../data/customer_repository.dart';

/// Keyed by the search text.
final customerListProvider = FutureProvider.autoDispose.family<List<Customer>, String>(
  (ref, search) => ref.watch(customerRepositoryProvider).list(search: search),
);

final customerDetailProvider = FutureProvider.autoDispose.family<Customer, int>(
  (ref, id) => ref.watch(customerRepositoryProvider).get(id),
);

final measurementsProvider = FutureProvider.autoDispose.family<List<Measurement>, int>(
  (ref, customerId) => ref.watch(customerRepositoryProvider).measurements(customerId),
);

/// Invalidates everything that shows a customer after it changes.
void refreshCustomer(WidgetRef ref, int customerId) {
  ref.invalidate(customerListProvider);
  ref.invalidate(subscriptionOverviewProvider);
  ref.invalidate(customerDetailProvider(customerId));
  ref.invalidate(measurementsProvider(customerId));
}
