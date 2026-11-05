<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

class MasterHabit extends Model
{
    protected $fillable = [
        'name',
        'icon',
        'color',
        'start_time',
        'end_time',
        'days_of_week',
        'sort_order',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'days_of_week' => 'array',
            'is_active' => 'boolean',
            'sort_order' => 'integer',
        ];
    }

    public function scopeActive(Builder $query): Builder
    {
        return $query->where('is_active', true);
    }

    public function scopeOrdered(Builder $query): Builder
    {
        return $query->orderBy('start_time')->orderBy('sort_order');
    }

    /**
     * Attributes for a user's own copy of this template.
     *
     * @return array<string, mixed>
     */
    public function toHabitAttributes(): array
    {
        return $this->only(['name', 'icon', 'color', 'start_time', 'end_time', 'days_of_week', 'sort_order']);
    }
}
