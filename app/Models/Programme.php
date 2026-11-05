<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Programme extends Model
{
    protected $fillable = [
        'name',
        'goal',
        'total_weeks',
        'weeks_completed',
        'start_date',
    ];

    protected function casts(): array
    {
        return [
            'start_date' => 'date:Y-m-d',
            'total_weeks' => 'integer',
            'weeks_completed' => 'integer',
        ];
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function measurements(): HasMany
    {
        return $this->hasMany(CustomerMeasurement::class);
    }

    public function weeksRemaining(): int
    {
        return max(0, $this->total_weeks - $this->weeks_completed);
    }
}
