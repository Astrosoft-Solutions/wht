<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Customer extends Model
{
    /** @use HasFactory<\Database\Factories\CustomerFactory> */
    use HasFactory;

    protected $fillable = [
        'customer_code',
        'name',
        'phone',
        'email',
        'height_cm',
        'status',
        'health_condition_before',
        'remarks',
    ];

    protected function casts(): array
    {
        return [
            'height_cm' => 'float',
        ];
    }

    protected static function booted(): void
    {
        static::creating(function (Customer $customer) {
            if (empty($customer->customer_code)) {
                $customer->customer_code = static::nextCodeFor($customer->user_id);
            }
        });
    }

    public static function nextCodeFor(int $userId): string
    {
        $max = static::where('user_id', $userId)
            ->where('customer_code', 'like', 'CUST%')
            ->pluck('customer_code')
            ->map(fn (string $code) => (int) substr($code, 4))
            ->max() ?? 0;

        return 'CUST'.str_pad((string) ($max + 1), 3, '0', STR_PAD_LEFT);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function programmes(): HasMany
    {
        return $this->hasMany(Programme::class);
    }

    public function measurements(): HasMany
    {
        return $this->hasMany(CustomerMeasurement::class);
    }

    public function latestMeasurement(): HasOne
    {
        return $this->hasOne(CustomerMeasurement::class)->latestOfMany('recorded_on');
    }

    /**
     * The first measurement, captured on the Personal Details form.
     */
    public function baselineMeasurement(): HasOne
    {
        return $this->hasOne(CustomerMeasurement::class)->oldestOfMany('recorded_on');
    }

    public function photos(): HasMany
    {
        return $this->hasMany(CustomerPhoto::class);
    }

    public function scopeSearch(Builder $query, ?string $term): Builder
    {
        if (! $term) {
            return $query;
        }

        return $query->where(function (Builder $q) use ($term) {
            $q->where('name', 'like', "%{$term}%")
                ->orWhere('phone', 'like', "%{$term}%")
                ->orWhere('customer_code', 'like', "%{$term}%");
        });
    }
}
