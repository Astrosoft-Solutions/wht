<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\User */
class CoachResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $subscription = $this->relationLoaded('currentSubscription')
            ? $this->currentSubscription
            : $this->activeSubscription();

        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'mobile' => $this->mobile,
            'avatar_url' => $this->avatarUrl(),
            'coach_type' => $this->coach_type,
            'status' => $this->status,
            'customers_count' => $this->whenCounted('customers'),
            'habits_count' => $this->whenCounted('habits'),
            'subscription' => $subscription ? new SubscriptionResource($subscription) : null,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
