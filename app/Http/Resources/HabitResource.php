<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\Habit */
class HabitResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $attributes = $this->resource->getAttributes();

        return [
            'id' => $this->id,
            'name' => $this->name,
            'icon' => $this->icon,
            'color' => $this->color,
            'start_time' => substr((string) $this->start_time, 0, 5),
            'end_time' => $this->end_time ? substr((string) $this->end_time, 0, 5) : null,
            'days_of_week' => $this->days_of_week,
            'sort_order' => $this->sort_order,
            'is_active' => $this->is_active,
            'is_completed' => $this->when(array_key_exists('is_completed', $attributes), fn () => (bool) $attributes['is_completed']),
            'is_scheduled_today' => $this->when(array_key_exists('is_scheduled_today', $attributes), fn () => (bool) $attributes['is_scheduled_today']),
            'completed_count' => $this->when(array_key_exists('completed_count', $attributes), fn () => (int) $attributes['completed_count']),
            'scheduled_count' => $this->when(array_key_exists('scheduled_count', $attributes), fn () => (int) $attributes['scheduled_count']),
        ];
    }
}
