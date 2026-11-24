<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use App\Models\Subscription;
use App\Services\RazorpayService;
use App\Services\SubscriptionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Activates subscriptions when Razorpay reports a captured payment, even if the
 * app closed before it could call /subscriptions/verify.
 */
class RazorpayWebhookController extends Controller
{
    private const CAPTURE_EVENTS = ['payment.captured', 'order.paid'];

    public function __invoke(Request $request, RazorpayService $razorpay, SubscriptionService $subscriptions): JsonResponse
    {
        if (! $razorpay->verifyWebhookSignature($request->getContent(), $request->header('X-Razorpay-Signature'))) {
            return response()->json(['message' => 'Invalid signature.'], 400);
        }

        $event = (string) $request->input('event');
        $payment = $request->input('payload.payment.entity', []);
        $orderId = $payment['order_id'] ?? $request->input('payload.order.entity.id');

        if (in_array($event, self::CAPTURE_EVENTS, true) && $orderId) {
            $subscription = Subscription::where('razorpay_order_id', $orderId)->first();
            if ($subscription) {
                $subscriptions->confirmPayment($subscription, (string) ($payment['id'] ?? ''), null, 'webhook.'.$event, $request->all());
            }
        } elseif ($event === 'payment.failed' && $orderId) {
            $subscription = Subscription::where('razorpay_order_id', $orderId)->first();
            Payment::create([
                'user_id' => $subscription?->user_id,
                'subscription_id' => $subscription?->id,
                'event' => 'webhook.payment.failed',
                'status' => 'failed',
                'razorpay_order_id' => $orderId,
                'razorpay_payment_id' => $payment['id'] ?? null,
                'amount_paise' => $payment['amount'] ?? null,
                'payload' => $request->all(),
            ]);
        }

        return response()->json(['status' => 'ok']);
    }
}
