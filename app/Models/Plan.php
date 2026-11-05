<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Plan extends Model
{
    /** @use HasFactory<\Database\Factories\PlanFactory> */
    use HasFactory;

    public const COACH_TYPES = ['consultant', 'coach', 'guide'];
    public const TIERS = ['gold', 'silver', 'bronze'];

    protected $fillable = [
        'coach_type',
        'tier',
        'name',
        'description',
        'price_paise',
        'currency',
        'duration_days',
        'max_customers',
        'features',
        'is_active',
        'sort_order',
    ];

    protected function casts(): array
    {
        return [
            'price_paise' => 'integer',
            'duration_days' => 'integer',
            'max_customers' => 'integer',
            'features' => 'array',
            'is_active' => 'boolean',
            'sort_order' => 'integer',
        ];
    }

    public function subscriptions(): HasMany
    {
        return $this->hasMany(Subscription::class);
    }

    public function scopeActive(Builder $query): Builder
    {
        return $query->where('is_active', true);
    }

    /**
     * Gold first, then Silver, then Bronze.
     */
    public function scopeOrdered(Builder $query): Builder
    {
        return $query->orderBy('coach_type')
            ->orderByRaw("CASE tier WHEN 'gold' THEN 1 WHEN 'silver' THEN 2 ELSE 3 END")
            ->orderBy('sort_order');
    }
}
