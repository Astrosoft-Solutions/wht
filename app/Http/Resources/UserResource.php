<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\User */
class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $subscription = $this->isCoach() ? $this->activeSubscription() : null;

        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'mobile' => $this->mobile,
            'avatar_url' => $this->avatarUrl(),
            'has_google' => $this->google_id !== null,
            'role' => $this->role,
            'coach_type' => $this->coach_type,
            'status' => $this->status,
            'subscription' => $subscription ? new SubscriptionResource($subscription) : null,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
