<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CustomerMeasurement extends Model
{
    protected $fillable = [
        'programme_id',
        'recorded_on',
        'weight',
        'fat_percent',
        'bmi',
        'muscle',
        'visceral_fat',
        'body_age',
        'chest',
        'waist',
        'hp',
        'rm_24',
        'total_points',
    ];

    protected function casts(): array
    {
        return [
            'recorded_on' => 'date:Y-m-d',
            'weight' => 'float',
            'fat_percent' => 'float',
            'bmi' => 'float',
            'muscle' => 'float',
            'visceral_fat' => 'float',
            'body_age' => 'integer',
            'chest' => 'float',
            'waist' => 'float',
            'total_points' => 'integer',
        ];
    }

    protected static function booted(): void
    {
        static::saving(function (CustomerMeasurement $measurement) {
            if ($measurement->bmi === null && $measurement->weight) {
                $height = $measurement->customer?->height_cm;
                if ($height) {
                    $measurement->bmi = static::calculateBmi((float) $measurement->weight, (float) $height);
                }
            }
        });
    }

    public static function calculateBmi(float $weightKg, float $heightCm): float
    {
        $meters = $heightCm / 100;

        return round($weightKg / ($meters * $meters), 1);
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function programme(): BelongsTo
    {
        return $this->belongsTo(Programme::class);
    }
}
