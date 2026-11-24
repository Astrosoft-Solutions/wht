<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\Subscription */
class SubscriptionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $status = $this->status;
        if ($status === 'active' && $this->ends_at?->isPast()) {
            $status = 'expired';
        }

        return [
            'id' => $this->id,
            'status' => $status,
            'is_current' => $this->isCurrent(),
            'starts_at' => $this->starts_at?->toIso8601String(),
            'ends_at' => $this->ends_at?->toIso8601String(),
            'days_left' => $this->daysLeft(),
            'amount_paise' => $this->amount_paise,
            'amount' => round($this->amount_paise / 100, 2),
            'currency' => $this->currency,
            'source' => $this->source,
            'razorpay_order_id' => $this->razorpay_order_id,
            'razorpay_payment_id' => $this->razorpay_payment_id,
            'notes' => $this->notes,
            'plan' => new PlanResource($this->whenLoaded('plan')),
            'user' => $this->whenLoaded('user', fn () => [
                'id' => $this->user->id,
                'name' => $this->user->name,
                'email' => $this->user->email,
                'coach_type' => $this->user->coach_type,
            ]),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
