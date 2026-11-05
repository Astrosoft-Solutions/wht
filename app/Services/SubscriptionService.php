<?php

namespace App\Services;

use App\Models\Payment;
use App\Models\Plan;
use App\Models\Subscription;
use App\Models\User;
use Carbon\CarbonInterface;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class SubscriptionService
{
    public function __construct(private readonly RazorpayService $razorpay) {}

    /**
     * Creates a Razorpay order and a pending subscription the coach then pays for.
     */
    public function startCheckout(User $user, Plan $plan, string $source): Subscription
    {
        $this->ensureCanBuy($user, $plan);

        $order = $this->razorpay->createOrder(
            $plan->price_paise,
            $plan->currency,
            'sub_'.$user->id.'_'.now()->timestamp,
            ['user_id' => $user->id, 'plan_id' => $plan->id],
        );

        $subscription = $user->subscriptions()->create([
            'plan_id' => $plan->id,
            'status' => Subscription::STATUS_PENDING,
            'amount_paise' => $plan->price_paise,
            'currency' => $plan->currency,
            'source' => $source,
            'razorpay_order_id' => $order['id'],
        ]);

        $this->log($subscription, 'order.created', 'created', $order);

        return $subscription;
    }

    /**
     * Marks a paid order as active. Safe to call twice (client verify and webhook).
     *
     * @param  array<string, mixed>  $payload
     */
    public function confirmPayment(Subscription $subscription, string $paymentId, ?string $signature, string $event, array $payload = []): Subscription
    {
        return DB::transaction(function () use ($subscription, $paymentId, $signature, $event, $payload) {
            $subscription = Subscription::whereKey($subscription->id)->lockForUpdate()->firstOrFail();

            if ($subscription->status !== Subscription::STATUS_ACTIVE) {
                $subscription->razorpay_payment_id = $paymentId;
                $subscription->razorpay_signature = $signature ?? $subscription->razorpay_signature;
                $this->activate($subscription, $subscription->plan->duration_days);
            }

            $this->log($subscription, $event, 'captured', $payload, $paymentId);

            return $subscription->load('plan');
        });
    }

    public function assignManually(User $user, Plan $plan, ?int $days = null, int $amountPaise = 0, ?string $notes = null, ?CarbonInterface $startsAt = null): Subscription
    {
        return DB::transaction(function () use ($user, $plan, $days, $amountPaise, $notes, $startsAt) {
            if ($user->coach_type !== $plan->coach_type) {
                $user->forceFill(['coach_type' => $plan->coach_type])->save();
            }

            $subscription = $user->subscriptions()->create([
                'plan_id' => $plan->id,
                'status' => Subscription::STATUS_PENDING,
                'amount_paise' => $amountPaise,
                'currency' => $plan->currency,
                'source' => 'manual',
                'notes' => $notes,
            ]);
            $this->activate($subscription, $days ?? $plan->duration_days, $startsAt);
            $this->log($subscription, 'manual.assigned', 'assigned');

            return $subscription->load('plan');
        });
    }

    public function cancel(Subscription $subscription, string $reason = 'Cancelled by admin'): Subscription
    {
        $subscription->update(['status' => Subscription::STATUS_CANCELLED, 'notes' => $reason]);
        $this->log($subscription, 'subscription.cancelled', 'cancelled');

        return $subscription;
    }

    /**
     * Flags subscriptions whose period has ended; run daily from the scheduler.
     */
    public function expireOverdue(): int
    {
        return Subscription::where('status', Subscription::STATUS_ACTIVE)
            ->where('ends_at', '<=', now())
            ->update(['status' => Subscription::STATUS_EXPIRED]);
    }

    /**
     * Renewing the same plan queues the new period after the current one; switching plans
     * (upgrade or downgrade) starts immediately and ends the plan being replaced.
     */
    private function activate(Subscription $subscription, int $days, ?CarbonInterface $startsAt = null): void
    {
        $others = Subscription::where('user_id', $subscription->user_id)
            ->whereKeyNot($subscription->id)
            ->activeOrUpcoming()
            ->get();

        $start = $startsAt ?? now();
        if (! $startsAt) {
            $samePlan = $others->where('plan_id', $subscription->plan_id);
            if ($samePlan->isNotEmpty() && $samePlan->count() === $others->count()) {
                $start = $samePlan->max('ends_at');
            } else {
                foreach ($others as $other) {
                    $other->update(['status' => Subscription::STATUS_CANCELLED, 'notes' => 'Replaced by '.$subscription->plan->name]);
                }
            }
        }

        $subscription->fill([
            'status' => Subscription::STATUS_ACTIVE,
            'starts_at' => $start,
            'ends_at' => $start->copy()->addDays($days),
        ])->save();
    }

    private function ensureCanBuy(User $user, Plan $plan): void
    {
        if (! $user->isCoach()) {
            throw ValidationException::withMessages(['plan_id' => ['Only coaches can subscribe to plans.']]);
        }
        if (! $plan->is_active) {
            throw ValidationException::withMessages(['plan_id' => ['This plan is no longer available.']]);
        }
        if ($user->coach_type && $user->coach_type !== $plan->coach_type) {
            throw ValidationException::withMessages([
                'plan_id' => ["This plan is for {$plan->coach_type}s. Choose a {$user->coach_type} plan."],
            ]);
        }
        if (! $user->coach_type) {
            $user->forceFill(['coach_type' => $plan->coach_type])->save();
        }
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    private function log(Subscription $subscription, string $event, string $status, array $payload = [], ?string $paymentId = null): void
    {
        Payment::create([
            'user_id' => $subscription->user_id,
            'subscription_id' => $subscription->id,
            'event' => $event,
            'status' => $status,
            'razorpay_order_id' => $subscription->razorpay_order_id,
            'razorpay_payment_id' => $paymentId ?? $subscription->razorpay_payment_id,
            'amount_paise' => $subscription->amount_paise,
            'currency' => $subscription->currency,
            'payload' => $payload ?: null,
        ]);
    }
}
