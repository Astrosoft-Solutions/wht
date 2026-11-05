<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\CustomerMeasurement */
class MeasurementResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'customer_id' => $this->customer_id,
            'programme_id' => $this->programme_id,
            'recorded_on' => $this->recorded_on?->toDateString(),
            'weight' => $this->weight,
            'fat_percent' => $this->fat_percent,
            'bmi' => $this->bmi,
            'muscle' => $this->muscle,
            'visceral_fat' => $this->visceral_fat,
            'body_age' => $this->body_age,
            'chest' => $this->chest,
            'waist' => $this->waist,
            'hp' => $this->hp,
            'rm_24' => $this->rm_24,
            'total_points' => $this->total_points,
        ];
    }
}
