<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\Plan */
class PlanResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'coach_type' => $this->coach_type,
            'tier' => $this->tier,
            'name' => $this->name,
            'description' => $this->description,
            'price_paise' => $this->price_paise,
            'price' => round($this->price_paise / 100, 2),
            'currency' => $this->currency,
            'duration_days' => $this->duration_days,
            'max_customers' => $this->max_customers,
            'features' => $this->features ?? [],
            'is_active' => $this->is_active,
            'sort_order' => $this->sort_order,
            'subscriptions_count' => $this->whenCounted('subscriptions'),
        ];
    }
}
