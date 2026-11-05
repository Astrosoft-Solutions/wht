import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'subscription_models.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SubscriptionRepository(ref.watch(dioProvider)),
);

class SubscriptionRepository {
  SubscriptionRepository(this._dio);

  final Dio _dio;

  Future<SubscriptionOverview> overview() => guardApi(() async {
        final res = await _dio.get('/subscription');
        return SubscriptionOverview.fromJson(res.data as Map<String, dynamic>);
      });

  Future<List<Plan>> plans() => guardApi(() async {
        final res = await _dio.get('/plans');
        return (res.data['data'] as List).map((e) => Plan.fromJson(e as Map<String, dynamic>)).toList();
      });

  Future<CheckoutOrder> checkout(int planId) => guardApi(() async {
        final res = await _dio.post('/subscriptions/checkout', data: {'plan_id': planId, 'source': 'app'});
        return CheckoutOrder.fromJson(res.data as Map<String, dynamic>);
      });

  /// Returns the server's confirmation message.
  Future<String> verify({required String orderId, required String paymentId, required String signature}) =>
      guardApi(() async {
        final res = await _dio.post('/subscriptions/verify', data: {
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
        });
        return res.data['message'] as String;
      });
}
