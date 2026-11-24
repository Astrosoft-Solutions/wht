<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\Payment */
class PaymentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'event' => $this->event,
            'status' => $this->status,
            'razorpay_order_id' => $this->razorpay_order_id,
            'razorpay_payment_id' => $this->razorpay_payment_id,
            'amount_paise' => $this->amount_paise,
            'amount' => $this->amount_paise !== null ? round($this->amount_paise / 100, 2) : null,
            'currency' => $this->currency,
            'subscription_id' => $this->subscription_id,
            'plan_name' => $this->subscription?->plan?->name,
            'user' => $this->whenLoaded('user', fn () => $this->user ? [
                'id' => $this->user->id,
                'name' => $this->user->name,
                'email' => $this->user->email,
            ] : null),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
