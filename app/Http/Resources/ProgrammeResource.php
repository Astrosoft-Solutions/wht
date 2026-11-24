<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\Programme */
class ProgrammeResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'customer_id' => $this->customer_id,
            'name' => $this->name,
            'goal' => $this->goal,
            'total_weeks' => $this->total_weeks,
            'weeks_completed' => $this->weeks_completed,
            'weeks_remaining' => $this->weeksRemaining(),
            'start_date' => $this->start_date?->toDateString(),
        ];
    }
}
