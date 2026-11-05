<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\PaymentResource;
use App\Http\Resources\SubscriptionResource;
use App\Models\Plan;
use App\Models\Subscription;
use App\Services\RazorpayService;
use App\Services\SubscriptionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use RuntimeException;

class SubscriptionController extends Controller
{
    public function __construct(
        private readonly SubscriptionService $subscriptions,
        private readonly RazorpayService $razorpay,
    ) {}

    public function show(Request $request): JsonResponse
    {
        $user = $request->user();
        $current = $user->activeSubscription();

        return response()->json([
            'current' => $current ? new SubscriptionResource($current) : null,
            'customers_count' => $user->customers()->count(),
            'max_customers' => $current?->plan?->max_customers,
            'history' => SubscriptionResource::collection(
                $user->subscriptions()->where('status', '!=', Subscription::STATUS_PENDING)->with('plan')->latest()->limit(50)->get()
            ),
            'payments' => PaymentResource::collection(
                $user->payments()->with('subscription.plan')->whereIn('event', ['payment.verified', 'webhook.payment.captured', 'manual.assigned'])->latest()->limit(50)->get()
            ),
            'payments_enabled' => $this->razorpay->isConfigured(),
        ]);
    }

    public function checkout(Request $request): JsonResponse
    {
        $data = $request->validate([
            'plan_id' => ['required', 'integer', 'exists:plans,id'],
            'source' => ['nullable', 'in:panel,app'],
        ]);

        $user = $request->user();
        $plan = Plan::findOrFail($data['plan_id']);

        try {
            $subscription = $this->subscriptions->startCheckout($user, $plan, $data['source'] ?? 'app');
        } catch (RuntimeException $e) {
            return response()->json(['message' => $e->getMessage()], 503);
        }

        return response()->json([
            'subscription_id' => $subscription->id,
            'order_id' => $subscription->razorpay_order_id,
            'key_id' => $this->razorpay->keyId(),
            'amount' => $subscription->amount_paise,
            'currency' => $subscription->currency,
            'name' => config('app.name'),
            'description' => $plan->name.' - '.$plan->duration_days.' days',
            'prefill' => [
                'name' => $user->name,
                'email' => $user->email,
                'contact' => $user->mobile,
            ],
        ], 201);
    }

    public function verify(Request $request): JsonResponse
    {
        $data = $request->validate([
            'razorpay_order_id' => ['required', 'string'],
            'razorpay_payment_id' => ['required', 'string'],
            'razorpay_signature' => ['required', 'string'],
        ]);

        $subscription = $request->user()->subscriptions()
            ->where('razorpay_order_id', $data['razorpay_order_id'])
            ->first();

        if (! $subscription) {
            throw ValidationException::withMessages(['razorpay_order_id' => ['Unknown order.']]);
        }

        if (! $this->razorpay->verifyPaymentSignature($data['razorpay_order_id'], $data['razorpay_payment_id'], $data['razorpay_signature'])) {
            throw ValidationException::withMessages(['razorpay_signature' => ['Payment could not be verified.']]);
        }

        $subscription = $this->subscriptions->confirmPayment(
            $subscription,
            $data['razorpay_payment_id'],
            $data['razorpay_signature'],
            'payment.verified',
        );

        return response()->json([
            'message' => 'Payment successful. Your '.$subscription->plan->name.' plan is active.',
            'subscription' => new SubscriptionResource($subscription),
        ]);
    }
}
