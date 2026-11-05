<?php

namespace App\Models;

use Carbon\CarbonInterface;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Habit extends Model
{
    /** @use HasFactory<\Database\Factories\HabitFactory> */
    use HasFactory;

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

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function logs(): HasMany
    {
        return $this->hasMany(HabitLog::class);
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
     * days_of_week holds ISO weekday numbers (1 = Monday ... 7 = Sunday); null or empty means every day.
     */
    public function isScheduledOn(CarbonInterface $date): bool
    {
        if (empty($this->days_of_week)) {
            return true;
        }

        return in_array($date->dayOfWeekIso, array_map('intval', $this->days_of_week), true);
    }
}
