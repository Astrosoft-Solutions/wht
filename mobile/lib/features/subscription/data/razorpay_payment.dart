import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../core/network/api_client.dart';
import 'subscription_models.dart';

class RazorpayResult {
  const RazorpayResult({required this.orderId, required this.paymentId, required this.signature});

  final String orderId;
  final String paymentId;
  final String signature;
}

/// Opens Razorpay's native checkout. Only available on Android and iOS.
class RazorpayPayment {
  static bool get isSupported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  /// Resolves with the signed payment, or null when the user closes the checkout.
  static Future<RazorpayResult?> pay(CheckoutOrder order) {
    final razorpay = Razorpay();
    final completer = Completer<RazorpayResult?>();

    void finish(void Function() complete) {
      if (!completer.isCompleted) complete();
      razorpay.clear();
    }

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
      finish(() => completer.complete(RazorpayResult(
            orderId: r.orderId ?? order.orderId,
            paymentId: r.paymentId ?? '',
            signature: r.signature ?? '',
          )));
    });
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
      if (r.code == Razorpay.PAYMENT_CANCELLED) {
        finish(() => completer.complete(null));
      } else {
        finish(() => completer.completeError(ApiException(r.message ?? 'Payment failed. Please try again.')));
      }
    });
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse _) {
      // External wallets confirm asynchronously; the Razorpay webhook activates the plan.
      finish(() => completer.complete(null));
    });

    razorpay.open({
      'key': order.keyId,
      'amount': order.amountPaise,
      'currency': order.currency,
      'order_id': order.orderId,
      'name': order.name,
      'description': order.description,
      'prefill': order.prefill,
      'theme': {'color': '#1B5E20'},
    });

    return completer.future;
  }
}
