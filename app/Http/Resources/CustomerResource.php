<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\Customer */
class CustomerResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'customer_code' => $this->customer_code,
            'name' => $this->name,
            'phone' => $this->phone,
            'email' => $this->email,
            'height_cm' => $this->height_cm,
            'status' => $this->status,
            'health_condition_before' => $this->health_condition_before,
            'remarks' => $this->remarks,
            'baseline_measurement' => new MeasurementResource($this->whenLoaded('baselineMeasurement')),
            'latest_measurement' => new MeasurementResource($this->whenLoaded('latestMeasurement')),
            'programmes' => ProgrammeResource::collection($this->whenLoaded('programmes')),
            'photos' => PhotoResource::collection($this->whenLoaded('photos')),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
